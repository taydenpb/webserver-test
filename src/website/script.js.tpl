async function getGreeting() {
    const name = document.getElementById('nameInput').value;
    try {
        const result = await fetch('${api_endpoint}', { // Corrected reference
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            mode: 'cors',
            body: JSON.stringify({ name: name })
        });
        
        if (!result.ok) {
            throw new Error("HTTP error! status: " + result.status);
        }
        
        const data = await result.json();
        document.getElementById('greeting').textContent = data.message;
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('greeting').textContent = 'Error: Could not get greeting';
    }
}