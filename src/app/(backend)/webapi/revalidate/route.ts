import { revalidateTag } from 'next/cache';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  if (!process.env.REVALIDATE_SECRET) {
    return NextResponse.json('REVALIDATE_SECRET is not set', { status: 501 });
  }

  // 直接获取并验证 Authorization 头的值
  const authToken = request.headers.get('Authorization');

  if (!authToken || authToken !== process.env.REVALIDATE_SECRET) {
    return NextResponse.json('Unauthorized', { status: 401 });
  }

  const tag = request.nextUrl.searchParams.get('tag');

  if (!tag) {
    return NextResponse.json('tag query parameter is required', { status: 400 });
  }

  revalidateTag(tag);

  return Response.json({ now: Date.now(), revalidated: true });
}
