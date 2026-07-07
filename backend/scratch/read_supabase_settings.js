const supabaseUrl = 'https://pxcwkgrpkkoukgaqicky.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4Y3drZ3Jwa2tvdWtnYXFpY2t5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTcwMzE1MywiZXhwIjoyMDk1Mjc5MTUzfQ.knr5SpM503Lo5XCpYwH8t4E1nnmmLXf7dO42L4g74Ug';

async function readSettings() {
  console.log("Fetching active settings from Supabase...");
  try {
    const response = await fetch(`${supabaseUrl}/rest/v1/app_settings?select=*`, {
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
    console.log("Active Settings Row:");
    console.log(JSON.stringify(data, null, 2));
  } catch (error) {
    console.error("Error fetching settings:", error);
  }
}

readSettings();
