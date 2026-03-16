# Supabase Setup for CropSense AI

## Step 1: Create a New Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click **"New project"**
3. Choose your organization (or create one)
4. Fill in:
   - **Name:** `cropsense-ai` (or any name)
   - **Database Password:** Choose a strong password (save it)
   - **Region:** Pick closest to Rwanda (e.g. `Africa (Cape Town)` if available, or `Europe`)
5. Click **"Create new project"**
6. Wait 1–2 minutes for the project to be ready

---

## Step 2: Create the `profiles` Table

1. In your new project, go to **SQL Editor**
2. Click **"New query"**
3. Paste and run this SQL:

```sql
-- Create profiles table
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  phone TEXT DEFAULT '',
  district TEXT DEFAULT '',
  province TEXT DEFAULT '',
  location TEXT,
  land_size DOUBLE PRECISION,
  soil_type TEXT,
  sector TEXT DEFAULT '',
  cell TEXT DEFAULT '',
  village TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

4. Click **Run**

---

## Step 3: Get Your API Keys

1. Go to **Project Settings** (gear icon in sidebar)
2. Click **API** in the left menu
3. Copy:
   - **Project URL** (e.g. `https://xxxxxxxx.supabase.co`)
   - **anon public** key (under "Project API keys")

---

## Step 4: Update the App

Share the **Project URL** and **anon key** and we'll update `lib/services/supabase_service.dart` for you.
