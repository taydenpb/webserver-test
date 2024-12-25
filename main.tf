## main.tf
provider "aws" {
  region = var.aws_region
}

# S3 Bucket
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
}

# Enable versioning (optional but recommended)
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure the bucket for website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

# Configure public access block settings
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Account-level S3 public access block settings (if needed)
resource "aws_s3_account_public_access_block" "allow_public_access" {
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Add explicit dependency on public access block settings
resource "aws_s3_bucket_policy" "website" {
  depends_on = [
    aws_s3_bucket_public_access_block.website,
    aws_s3_account_public_access_block.allow_public_access
  ]
  
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "greeting_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "greeting" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "greeting.lambda_handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "greeting-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
    max_age      = 300
  }
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.greeting.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /greet"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.greeting.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# S3 Website Content Upload
resource "aws_s3_object" "html" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/src/website/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "js" {
  bucket       = aws_s3_bucket.website.id
  key          = "script.js"
  content_type = "application/javascript"
  content = templatefile(
    "${path.module}/src/website/script.js.tpl",
    {
        api_endpoint = "${aws_apigatewayv2_api.api.api_endpoint}/greet"
    }
)
}