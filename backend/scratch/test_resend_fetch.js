const apiKey = 're_hf8mURvL_FL12X3JfuZY8E9k7rAsP9WUk';
const fromEmail = 'noreply@techotd.in';
const toEmail = 'chaudharyyash103c@gmail.com';

async function testResend() {
  console.log(`Sending test email using Resend API to ${toEmail}...`);
  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: fromEmail,
        to: toEmail,
        subject: 'NutriVault Resend API Key Test',
        text: 'This is a test email sent using the Resend HTTPS API to verify delivery to your inbox.'
      })
    });

    const status = response.status;
    const bodyText = await response.text();
    console.log(`HTTP Status: ${status}`);
    console.log(`Response Body: ${bodyText}`);
  } catch (error) {
    console.error("Error sending email:", error);
  }
}

testResend();
