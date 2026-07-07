async function testLiveSendOtp() {
  console.log("Sending request to live /api/auth/send-otp...");
  try {
    const response = await fetch('https://nutrivault.techotd.in/api/auth/send-otp', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: 'chaudharyyash103c@gmail.com'
      })
    });

    const status = response.status;
    const bodyText = await response.text();
    console.log(`HTTP Status: ${status}`);
    console.log(`Response Body: ${bodyText}`);
  } catch (error) {
    console.error("Connection error:", error);
  }
}

testLiveSendOtp();
