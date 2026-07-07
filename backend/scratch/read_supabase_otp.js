const supabaseUrl = 'https://pxcwkgrpkkoukgaqicky.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4Y3drZ3Jwa2tvdWtnYXFpY2t5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTcwMzE1MywiZXhwIjoyMDk1Mjc5MTUzfQ.knr5SpM503Lo5XCpYwH8t4E1nnmmLXf7dO42L4g74Ug';

async function readOtpCodes() {
  console.log("Fetching recent OTP codes from Supabase...");
  try {
    const response = await fetch(`${supabaseUrl}/rest/v1/otp_codes?select=*&order=created_at.desc&limit=10`, {
      method: 'GET',
      headers: {
        'apikey': serviceKey,
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': 'application/json'
      }
    });

    const status = response.status;
    const data = await response.json();
    console.log(`HTTP Status: ${status}`);
    console.log("Recent OTP Codes:");
    console.log(JSON.stringify(data, null, 2));
  } catch (error) {
    console.error("Error fetching OTP codes:", error);
  }
}

readOtpCodes();
