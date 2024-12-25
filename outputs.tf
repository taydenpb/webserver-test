## outputs.tf
output "website_url" {
  value = "http://${aws_s3_bucket.website.bucket}.s3-website-${var.aws_region}.amazonaws.com"
}

output "api_endpoint" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/greet"
}