# NutriTrack Admin Dashboard

A complete, premium, and state-of-the-art admin control panel for the NutriTrack fitness application.

## 🚀 Stack & Technologies
* **Framework**: Next.js 14 (App Router, Server Components)
* **Language**: TypeScript
* **Styling**: Tailwind CSS + custom glassmorphic obsidian-dark aesthetics
* **Charts & Plots**: Recharts (fully customized with gradients, responsive wrappers, and interactive tooltips)
* **Database**: Supabase JS Client using Service Role Key (bypasses RLS secure policies server-side)
* **Authentication**: NextAuth.js (Credentials provider flow + middleware protection)
* **Deployment Ready**: Fully configured for Vercel deployment

---

## 📁 Key Folder Structure
```
admin/
├── app/
│   ├── (auth)/
│   │   └── login/               # Obsidian dark login page
│   ├── (dashboard)/
│   │   ├── layout.tsx           # Dashboard layout shell with Sidebar nav
│   │   ├── page.tsx             # Overview stats and charts screen
│   │   ├── users/
│   │   │   ├── page.tsx         # Searchable, filterable paginated user lists
│   │   │   └── [id]/page.tsx    # Dedicated user detail timelines & logs
│   │   ├── foods/
│   │   │   └── page.tsx         # Curated food manager database & sheets
│   │   ├── ai-costs/
│   │   │   └── page.tsx         # AI billing budgets and cache charts
│   │   ├── analytics/
│   │   │   └── page.tsx         # Cohorts, retention curves, & usage heatmaps
│   │   ├── revenue/
│   │   │   └── page.tsx         # Stripe payments projections and invoices
│   │   └── reports/
│   │       └── page.tsx         # Support tickets resolver & bug tracker
│   ├── api/
│   │   ├── auth/                # NextAuth handler configuration
│   │   ├── foods/               # REST actions for add/delete food items
│   │   ├── reports/             # REST actions to resolve/dismiss tickets
│   │   └── users/               # REST actions to ban/delete user records
│   ├── layout.tsx               # Root layout wrapper with Tailwind fonts
│   └── globals.css              # Custom base styles and scrollbars config 
├── components/
│   ├── data-table.tsx           # Reusable paginated custom tables
│   ├── stat-card.tsx            # Premium metrics cards with hover scaling
│   ├── sidebar.tsx              # Obsidian sidebar with active routes highlighting
│   └── providers.tsx            # SessionProvider client-side wrapper
├── lib/
│   ├── supabase.ts              # Service Role administrative DB client
│   └── queries.ts               # Parallel DB query queries with mock fallbacks
└── .env.local                   # Local environment secret variables
```

---

## 🔒 Security Architecture
1. **Zero Client Secrets**: The Supabase service role key `SUPABASE_SERVICE_ROLE_KEY` bypasses RLS to allow deleting users, banning accounts, and fetching logs. This key is **never** loaded into the browser. All database requests are performed inside **Next.js Server Components** or **API Route Handlers**.
2. **NextAuth Middleware Route Protection**: The admin panel uses middleware to check authentication tokens on every route under `/` (except `/login` and `/api/auth`). Unauthenticated users are instantly redirected to `/login` before any assets or page loads occur.
3. **Restricted Admin Boundary**: Access is strictly limited to emails matching the `ADMIN_EMAIL` environment variable.

---

## ⚙️ Running Locally

### 1. Configure Environment Variables
Create a `.env.local` file inside the `admin/` directory:
```bash
# NextAuth Configuration
NEXTAUTH_SECRET=94bcde832b4b4554b7ae28d484ea388ba72ef2cfce71a0b3b4bc8fa77a2efde5
NEXTAUTH_URL=http://localhost:3000

# Administrator Credentials
ADMIN_EMAIL=admin@nutritrack.com
ADMIN_PASSWORD=adminpassword123

# Supabase API Settings (Matching dev databases)
NEXT_PUBLIC_SUPABASE_URL=https://pxcwkgrpkkoukgaqicky.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
```

### 2. Run the Development Server
Navigate into the `admin/` directory and run:
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) with your browser.

---

## 🔐 Credentials
Use the following credentials to sign in to the panel during local development:
* **Admin Email**: `admin@nutritrack.com`
* **Admin Password**: `adminpassword123`
