import { withAuth } from 'next-auth/middleware';

export default withAuth({
  callbacks: {
    authorized({ req, token }) {
      // If there is a token, the user is authenticated
      return !!token;
    },
  },
  pages: {
    signIn: '/login',
  },
});

export const config = {
  matcher: [
    /*
     * Match all request paths except for:
     * 1. /login
     * 2. /api/auth (NextAuth endpoints)
     * 3. _next/static, _next/image, favicon.ico (Next.js assets)
     */
    '/((?!login|api/auth|_next/static|_next/image|favicon.ico).*)',
  ],
};
