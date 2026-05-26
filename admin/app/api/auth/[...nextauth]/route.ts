import NextAuth, { NextAuthOptions } from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'Admin Credentials',
      credentials: {
        email: { label: 'Email', type: 'email', placeholder: 'admin@example.com' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials) return null;

        const adminEmail = process.env.ADMIN_EMAIL || 'admin@nutritrack.com';
        const adminPassword = process.env.ADMIN_PASSWORD || 'adminpassword123';

        // Check if the logging email and password match
        if (
          credentials.email.toLowerCase() === adminEmail.toLowerCase() &&
          credentials.password === adminPassword
        ) {
          return {
            id: 'admin-id',
            name: 'System Admin',
            email: credentials.email,
          };
        }
        return null;
      },
    }),
  ],
  pages: {
    signIn: '/login',
  },
  session: {
    strategy: 'jwt',
    maxAge: 24 * 60 * 60, // 1 day
  },
  secret: process.env.NEXTAUTH_SECRET || 'fallback-secret-key-12345',
};

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };

