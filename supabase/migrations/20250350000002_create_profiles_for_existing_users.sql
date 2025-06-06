-- Create profiles for existing users who don't have one
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN 
        SELECT au.id, au.email
        FROM auth.users au
        LEFT JOIN public.profiles p ON p.id = au.id
        WHERE p.id IS NULL
    LOOP
        INSERT INTO public.profiles (
            id,
            username,
            full_name,
            avatar_url,
            is_admin
        ) VALUES (
            user_record.id,
            user_record.email,
            NULL,
            NULL,
            FALSE
        );

        RAISE NOTICE 'Created profile for user %', user_record.email;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Output the number of profiles that were missing before insertion
SELECT 
  'Profiles that were missing before this run: ' || COUNT(*)::text AS result
FROM (
    SELECT au.id
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.id IS NULL
) AS missing_profiles;

-- List all profiles (most recent first)
SELECT 
    p.id,
    p.username,
    p.is_admin,
    p.created_at
FROM public.profiles p
ORDER BY p.created_at DESC;
