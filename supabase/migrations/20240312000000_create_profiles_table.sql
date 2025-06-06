-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  is_admin BOOLEAN DEFAULT FALSE NOT NULL,
  peanuts_used INTEGER DEFAULT 0 NOT NULL,
  peanuts_refunded INTEGER DEFAULT 0 NOT NULL
);

-- Create trigger function to update updated_at column
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach the trigger to profiles table
CREATE OR REPLACE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION update_profiles_updated_at();

-- Clean up any previously created policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Only admins can update is_admin field" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own non-admin fields" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Policy: Everyone can view profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

-- Create helper function: prevent non-admins from changing is_admin
CREATE OR REPLACE FUNCTION check_is_admin_unchanged(is_admin_new BOOLEAN, user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  is_admin_old BOOLEAN;
BEGIN
  SELECT p.is_admin INTO is_admin_old FROM public.profiles p WHERE p.id = user_id;
  RETURN is_admin_new = is_admin_old;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy: Users can update their own non-admin fields
CREATE POLICY "Users can update their own non-admin fields"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (check_is_admin_unchanged(is_admin, id));

-- Policy: Admins can update any profile
CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT id FROM public.profiles WHERE is_admin = true
    )
  );

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (
    auth.uid() = id AND
    (is_admin = false OR auth.uid() IN (
      SELECT id FROM public.profiles WHERE is_admin = true
    ))
  );

-- Enable Row-Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Auto-create profile for each new user from auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, is_admin)
  VALUES (NEW.id, NEW.email, FALSE);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: run handle_new_user after each new auth.users entry
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Optionally promote the first user to admin manually
-- UPDATE public.profiles
-- SET is_admin = TRUE
-- WHERE id = '[YOUR_USER_ID]';
