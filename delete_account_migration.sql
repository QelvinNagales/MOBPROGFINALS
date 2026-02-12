-- Delete Account Migration - COMPLETE SOLUTION
-- Run this SQL in your Supabase SQL Editor to enable FULL account deletion
-- This will delete user data AND prevent them from logging in again

-- 1. Drop existing function if any
DROP FUNCTION IF EXISTS delete_user_account();

-- 2. Create the function with proper permissions to access auth schema
-- IMPORTANT: SET search_path is required to access auth.users
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete profile first (cascades to related tables)
  DELETE FROM public.profiles WHERE id = v_user_id;
  
  -- Delete from auth.users - THIS PREVENTS LOGIN
  DELETE FROM auth.users WHERE id = v_user_id;
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'Error deleting account: %', SQLERRM;
    RETURN FALSE;
END;
$$;

-- 3. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- 4. Add DELETE policy for profiles (if missing)
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;
CREATE POLICY "Users can delete own profile"
  ON profiles FOR DELETE
  USING (auth.uid() = id);
