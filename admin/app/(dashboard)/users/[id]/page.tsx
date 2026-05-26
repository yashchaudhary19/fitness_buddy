import React from 'react';
import { getUserById } from '@/lib/queries';
import UserDetailClient from './user-detail-client';
import { notFound } from 'next/navigation';

export const revalidate = 0;

interface UserDetailPageProps {
  params: {
    id: string;
  };
}

export default async function UserDetailPage({ params }: UserDetailPageProps) {
  try {
    const user = await getUserById(params.id);
    return <UserDetailClient user={user} />;
  } catch (err) {
    notFound();
  }
}
