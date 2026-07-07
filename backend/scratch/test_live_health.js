async function testLiveHealth() {
  const url = 'https://nutrivault.techotd.in/health?t=' + Date.now();
  console.log(`Fetching live health status from: ${url}`);
  try {
    const response = await fetch(url, {
      method: 'GET'
    });

    const status = response.status;
    const headers = {};
    for (const [key, value] of response.headers.entries()) {
      headers[key] = value;
    }
    const bodyText = await response.text();
    
    console.log(`HTTP Status: ${status}`);
    console.log("Response Headers:", JSON.stringify(headers, null, 2));
    console.log(`Response Body: ${bodyText}`);
  } catch (error) {
    console.error("Connection error:", error);
  }
}

testLiveHealth();
