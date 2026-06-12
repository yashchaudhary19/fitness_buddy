import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../auth/[...nextauth]/route';
import { getAppSettings, updateAppSettings } from '@/lib/queries';

export async function GET(req: NextRequest) {
  // Protect route
  const session = await getServerSession(authOptions);
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const settings = await getAppSettings();
    return NextResponse.json({ success: true, data: settings });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Failed to fetch settings' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  // Protect route
  const session = await getServerSession(authOptions);
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await req.json();
    
    // Update settings in database
    await updateAppSettings({
      ai_provider: body.ai_provider,
      gemini_model: body.gemini_model,
      claude_model: body.claude_model,
      gemini_api_key: body.gemini_api_key === "" ? null : body.gemini_api_key,
      claude_api_key: body.claude_api_key === "" ? null : body.claude_api_key,
    });

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Failed to update settings' }, { status: 500 });
  }
}
