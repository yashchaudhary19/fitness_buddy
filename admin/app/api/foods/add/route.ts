import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]/route';
import { addFoodManually } from '@/lib/queries';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const food = await req.json();
    if (!food.name || food.calories_per_100g === undefined) {
      return NextResponse.json({ error: 'Missing required food fields' }, { status: 400 });
    }

    await addFoodManually({
      name: food.name,
      brand: food.brand || '',
      calories_per_100g: Number(food.calories_per_100g),
      carbs_per_100g: Number(food.carbs_per_100g || 0),
      protein_per_100g: Number(food.protein_per_100g || 0),
      fat_per_100g: Number(food.fat_per_100g || 0),
      source: food.source || 'api',
    });

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Failed to add food item' }, { status: 500 });
  }
}
