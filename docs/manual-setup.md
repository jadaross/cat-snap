# Manual Setup Guide

Everything you need to do once to get Cat Snap running end-to-end. These are the steps that can't be automated — they require accounts, keys, and dashboard clicks.

Estimated time: **~30 minutes**

---

## 1. Supabase Project

Supabase is your database, auth, and file storage all in one.

### 1a. Create a project

1. Go to [supabase.com](https://supabase.com) and sign in (or create a free account)
2. Click **New project**
3. Choose a name (e.g. `cat-snap`), set a strong database password, and pick the region closest to your users
4. Wait ~2 minutes for the project to provision

### 1b. Run the database migration

1. In your Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **New query**
3. Copy the entire contents of `apps/web/supabase/migrations/001_initial.sql`
4. Paste it into the editor and click **Run**
5. You should see "Success. No rows returned" — this means all tables, indexes, policies, and functions were created

> **Tip:** If you see any errors about extensions already existing, that's fine — just re-run after commenting out the `create extension` lines.

### 1c. Create Storage buckets

1. In your Supabase dashboard, click **Storage** in the left sidebar
2. Click **New bucket** and create:
   - Name: `sighting-photos` | Toggle **Public bucket** ON
   - Name: `avatars` | Toggle **Public bucket** ON
3. For each bucket, go to **Policies** and ensure anon users can SELECT (read) and authenticated users can INSERT (upload). The SQL migration enables RLS but Storage buckets need their own policies set via the dashboard.

   For `sighting-photos`, add these policies:
   - **SELECT** → Allow for `public` (everyone can view photos)
   - **INSERT** → Allow for `authenticated` (only signed-in users can upload)

   Repeat for `avatars`.

### 1d. Enable Google OAuth (optional but recommended)

1. In Supabase dashboard → **Authentication** → **Providers**
2. Toggle **Google** on
3. You'll need a Google OAuth Client ID and Secret (see step 2 below)
4. Set the **Redirect URL** shown on this page — you'll need it in step 2

### 1e. Get your API keys

1. In Supabase dashboard → **Settings** → **API**
2. Copy:
   - **Project URL** → this is `NEXT_PUBLIC_SUPABASE_URL`
   - **anon public** key → this is `NEXT_PUBLIC_SUPABASE_ANON_KEY`

---

## 2. Google OAuth (optional)

Skip this if you only want email/password auth for now.

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a new project (or select an existing one)
3. Go to **APIs & Services** → **OAuth consent screen**
   - Choose **External**
   - Fill in app name ("Cat Snap"), support email, developer email
   - Add scopes: `email`, `profile`, `openid`
   - Save
4. Go to **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
   - Application type: **Web application**
   - Authorised redirect URIs: paste the redirect URL from Supabase step 1d (looks like `https://your-project.supabase.co/auth/v1/callback`)
   - Click **Create**
5. Copy the **Client ID** and **Client Secret**
6. Paste them into Supabase → Authentication → Providers → Google

---

## 3. Mapbox Account

Mapbox powers the interactive map. The free tier gives you 50,000 map loads/month — plenty to get started.

1. Go to [mapbox.com](https://mapbox.com) and create a free account
2. On your account dashboard, find your **Default public token** (starts with `pk.`)
3. Copy it — this is `NEXT_PUBLIC_MAPBOX_TOKEN`

> You can also create a new restricted token scoped to your domain for production.

---

## 4. Environment Variables

1. In `apps/web/`, copy the example file:
   ```bash
   cp .env.example .env.local
   ```
2. Open `.env.local` and fill in the three values:
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...your anon key...
   NEXT_PUBLIC_MAPBOX_TOKEN=pk.eyJ1...your mapbox token...
   ```
3. Save the file. **Never commit `.env.local` to git** — it's already in `.gitignore`.

---

## 5. Install Dependencies & Run Locally

From the root of the repo:

```bash
# Install all dependencies
npm install

# Start the dev server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). You should see the Cat Snap landing page.

**Test the full flow:**
1. Click **Sign up** and create an account (check your email for the confirmation link)
2. After confirming, log in
3. Go to **Map** — grant location permission when prompted
4. Click **Snap a Cat** — upload a photo, name the cat, submit
5. The map should now show a pin for your sighting

---

## 6. Deploy to Vercel

1. Push the repo to GitHub (if not already there)
2. Go to [vercel.com](https://vercel.com) and click **Add New → Project**
3. Import your GitHub repo
4. Set the **Root Directory** to `apps/web`
5. Add your environment variables (same three as in step 4) under **Environment Variables**
6. Click **Deploy**

Your app will be live at a `.vercel.app` URL within ~2 minutes.

**After deploying:**
- Go to Supabase → Authentication → URL Configuration
- Add your Vercel URL to **Site URL** (e.g. `https://cat-snap.vercel.app`)
- Add it to **Redirect URLs** as well (add both `https://your-app.vercel.app` and `https://your-app.vercel.app/auth/callback`)

---

## 7. Custom Domain (optional)

1. In Vercel → your project → **Settings** → **Domains**
2. Add your domain and follow the DNS instructions
3. Update the Supabase Site URL and Redirect URLs to your custom domain

---

## Summary Checklist

- [ ] Supabase project created
- [ ] SQL migration run (`001_initial.sql`)
- [ ] Storage buckets created: `sighting-photos` and `avatars` (both public)
- [ ] Storage bucket policies set (public read, auth write)
- [ ] Mapbox account + public token copied
- [ ] `.env.local` filled in with Supabase URL, anon key, and Mapbox token
- [ ] `npm install && npm run dev` runs without errors
- [ ] Sign-up → email confirm → log in works
- [ ] Can submit a sighting and see it on the map
- [ ] Deployed to Vercel
- [ ] Supabase redirect URLs updated with production domain
- [ ] *(Optional)* Google OAuth configured end-to-end

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Map doesn't render | Check `NEXT_PUBLIC_MAPBOX_TOKEN` is set correctly in `.env.local` |
| Auth callback fails after Google sign-in | Ensure the Supabase redirect URL is in your Google OAuth allowed URIs |
| Photo upload fails | Check Storage bucket exists, is public, and has INSERT policy for authenticated users |
| "Cat not found" on cat profile page | The `sightings_near` RPC function may not have been created — re-run the migration |
| `useLocation` returns null | Allow location permission in your browser; on localhost, Chrome allows it on `http://localhost` |
| Build error: `@supabase/ssr` not found | Run `npm install` from the `apps/web` directory |
