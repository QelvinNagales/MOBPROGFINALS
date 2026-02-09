-- APC Student Network - Supabase Database Schema
-- Run this SQL in your Supabase SQL Editor to set up the database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============ PROFILES TABLE ============
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  bio TEXT DEFAULT '',
  pronouns TEXT DEFAULT '',
  avatar_url TEXT,
  facebook_username TEXT DEFAULT '',
  linkedin_username TEXT DEFAULT '',
  skills TEXT[] DEFAULT '{}',
  projects TEXT[] DEFAULT '{}',
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============ PROJECTS TABLE ============
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  language TEXT DEFAULT 'Dart',
  is_public BOOLEAN DEFAULT true,
  topics TEXT[] DEFAULT '{}',
  stars INTEGER DEFAULT 0,
  forks INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Policies for projects
CREATE POLICY "Public projects are viewable by everyone"
  ON projects FOR SELECT
  USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can create own projects"
  ON projects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own projects"
  ON projects FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own projects"
  ON projects FOR DELETE
  USING (auth.uid() = user_id);

-- ============ PROJECT STARS TABLE ============
CREATE TABLE IF NOT EXISTS project_stars (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, project_id)
);

-- Enable Row Level Security
ALTER TABLE project_stars ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Stars are viewable by everyone"
  ON project_stars FOR SELECT
  USING (true);

CREATE POLICY "Users can star projects"
  ON project_stars FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unstar projects"
  ON project_stars FOR DELETE
  USING (auth.uid() = user_id);

-- ============ CONNECTIONS TABLE ============
CREATE TABLE IF NOT EXISTS connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  target_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(requester_id, target_id)
);

-- Enable Row Level Security
ALTER TABLE connections ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own connections"
  ON connections FOR SELECT
  USING (auth.uid() = requester_id OR auth.uid() = target_id);

CREATE POLICY "Users can create connection requests"
  ON connections FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Target users can update connection status"
  ON connections FOR UPDATE
  USING (auth.uid() = target_id);

-- ============ NOTIFICATIONS TABLE ============
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  from_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Anyone can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- ============ ACTIVITIES TABLE ============
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  target_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  target_project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Activities are viewable by everyone"
  ON activities FOR SELECT
  USING (true);

CREATE POLICY "Users can create own activities"
  ON activities FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============ FUNCTIONS ============

-- Function to increment stars
CREATE OR REPLACE FUNCTION increment_stars(project_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE projects SET stars = stars + 1 WHERE id = project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement stars
CREATE OR REPLACE FUNCTION decrement_stars(project_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE projects SET stars = GREATEST(stars - 1, 0) WHERE id = project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Function to update follower counts when connection is accepted
CREATE OR REPLACE FUNCTION update_follower_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    -- Increment following count for requester
    UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.requester_id;
    -- Increment followers count for target
    UPDATE profiles SET followers_count = followers_count + 1 WHERE id = NEW.target_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for connection status change
DROP TRIGGER IF EXISTS on_connection_update ON connections;
CREATE TRIGGER on_connection_update
  AFTER UPDATE ON connections
  FOR EACH ROW
  EXECUTE FUNCTION update_follower_counts();

-- ============ ENABLE REALTIME ============
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE connections;
ALTER PUBLICATION supabase_realtime ADD TABLE activities;

-- ============ INDEXES ============
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_connections_requester ON connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_connections_target ON connections(target_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_user ON activities(user_id);
