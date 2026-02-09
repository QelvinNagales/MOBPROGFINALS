-- APC Student Network - Enhanced Supabase Database Schema
-- Full-Stack Implementation with Advanced Features
-- Run this SQL in your Supabase SQL Editor to set up the database
-- This script is migration-safe and handles existing objects

-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- ============ PROFILES TABLE ============
-- Add new columns to existing profiles table if they don't exist
DO $$ 
BEGIN
  -- Add new columns if they don't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'cover_photo_url') THEN
    ALTER TABLE profiles ADD COLUMN cover_photo_url TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'github_username') THEN
    ALTER TABLE profiles ADD COLUMN github_username TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'website_url') THEN
    ALTER TABLE profiles ADD COLUMN website_url TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'location') THEN
    ALTER TABLE profiles ADD COLUMN location TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'year_level') THEN
    ALTER TABLE profiles ADD COLUMN year_level TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'course') THEN
    ALTER TABLE profiles ADD COLUMN course TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'projects_count') THEN
    ALTER TABLE profiles ADD COLUMN projects_count INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'profile_views') THEN
    ALTER TABLE profiles ADD COLUMN profile_views INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_verified') THEN
    ALTER TABLE profiles ADD COLUMN is_verified BOOLEAN DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_online') THEN
    ALTER TABLE profiles ADD COLUMN is_online BOOLEAN DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_seen') THEN
    ALTER TABLE profiles ADD COLUMN last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
  -- Add columns that may be missing from original schema
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'following_count') THEN
    ALTER TABLE profiles ADD COLUMN following_count INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'followers_count') THEN
    ALTER TABLE profiles ADD COLUMN followers_count INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'skills') THEN
    ALTER TABLE profiles ADD COLUMN skills TEXT[] DEFAULT '{}';
  END IF;
END $$;

-- Enable Row Level Security (safe to run multiple times)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop and recreate policies for profiles (to avoid conflicts)
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ============ SKILLS TABLE (Normalized) ============
CREATE TABLE IF NOT EXISTS skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  category TEXT DEFAULT 'General',
  icon_name TEXT DEFAULT 'code',
  color TEXT DEFAULT '#3D3D8F',
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User-Skill relationship (many-to-many)
CREATE TABLE IF NOT EXISTS user_skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  skill_id UUID REFERENCES skills(id) ON DELETE CASCADE NOT NULL,
  proficiency_level INTEGER DEFAULT 1 CHECK (proficiency_level BETWEEN 1 AND 5),
  years_experience DECIMAL(3,1) DEFAULT 0,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, skill_id)
);

ALTER TABLE skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Skills are viewable by everyone" ON skills;
DROP POLICY IF EXISTS "Authenticated users can add skills" ON skills;
DROP POLICY IF EXISTS "User skills are viewable by everyone" ON user_skills;
DROP POLICY IF EXISTS "Users can manage own skills" ON user_skills;

CREATE POLICY "Skills are viewable by everyone" ON skills FOR SELECT USING (true);
CREATE POLICY "Authenticated users can add skills" ON skills FOR INSERT WITH CHECK (true);

CREATE POLICY "User skills are viewable by everyone" ON user_skills FOR SELECT USING (true);
CREATE POLICY "Users can manage own skills" ON user_skills FOR ALL USING (auth.uid() = user_id);

-- ============ PROJECTS TABLE (Enhanced) ============
-- Add new columns to existing projects table if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'long_description') THEN
    ALTER TABLE projects ADD COLUMN long_description TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'technologies') THEN
    ALTER TABLE projects ADD COLUMN technologies TEXT[] DEFAULT '{}';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'github_url') THEN
    ALTER TABLE projects ADD COLUMN github_url TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'demo_url') THEN
    ALTER TABLE projects ADD COLUMN demo_url TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'thumbnail_url') THEN
    ALTER TABLE projects ADD COLUMN thumbnail_url TEXT DEFAULT '';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'stars_count') THEN
    ALTER TABLE projects ADD COLUMN stars_count INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'forks_count') THEN
    ALTER TABLE projects ADD COLUMN forks_count INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'views_count') THEN
    ALTER TABLE projects ADD COLUMN views_count INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'comments_count') THEN
    ALTER TABLE projects ADD COLUMN comments_count INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'status') THEN
    ALTER TABLE projects ADD COLUMN status TEXT DEFAULT 'in_progress';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'start_date') THEN
    ALTER TABLE projects ADD COLUMN start_date DATE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'end_date') THEN
    ALTER TABLE projects ADD COLUMN end_date DATE;
  END IF;
  -- Add these columns that may be missing from original schema
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'is_public') THEN
    ALTER TABLE projects ADD COLUMN is_public BOOLEAN DEFAULT true;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'topics') THEN
    ALTER TABLE projects ADD COLUMN topics TEXT[] DEFAULT '{}';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'projects' AND column_name = 'language') THEN
    ALTER TABLE projects ADD COLUMN language TEXT DEFAULT 'Dart';
  END IF;
END $$;

-- Create projects table if not exists (for fresh install)
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  long_description TEXT DEFAULT '',
  language TEXT DEFAULT 'Dart',
  is_public BOOLEAN DEFAULT true,
  topics TEXT[] DEFAULT '{}',
  technologies TEXT[] DEFAULT '{}',
  github_url TEXT DEFAULT '',
  demo_url TEXT DEFAULT '',
  thumbnail_url TEXT DEFAULT '',
  stars_count INTEGER DEFAULT 0,
  forks_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'in_progress',
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public projects viewable by all" ON projects;
DROP POLICY IF EXISTS "Users can CRUD own projects" ON projects;
DROP POLICY IF EXISTS "Public projects are viewable by everyone" ON projects;
DROP POLICY IF EXISTS "Users can create own projects" ON projects;
DROP POLICY IF EXISTS "Users can update own projects" ON projects;
DROP POLICY IF EXISTS "Users can delete own projects" ON projects;

CREATE POLICY "Public projects viewable by all" ON projects FOR SELECT
  USING (COALESCE(is_public, true) = true OR auth.uid() = user_id);
CREATE POLICY "Users can create own projects" ON projects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own projects" ON projects FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own projects" ON projects FOR DELETE USING (auth.uid() = user_id);

-- ============ PROJECT COLLABORATORS TABLE ============
CREATE TABLE IF NOT EXISTS project_collaborators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'contributor',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(project_id, user_id)
);

ALTER TABLE project_collaborators ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Collaborators viewable by all" ON project_collaborators;
DROP POLICY IF EXISTS "Project owners can manage collaborators" ON project_collaborators;

CREATE POLICY "Collaborators viewable by all" ON project_collaborators FOR SELECT USING (true);
CREATE POLICY "Project owners can manage collaborators" ON project_collaborators FOR ALL
  USING (EXISTS (SELECT 1 FROM projects WHERE id = project_id AND user_id = auth.uid()));

-- ============ PROJECT STARS TABLE ============
CREATE TABLE IF NOT EXISTS project_stars (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, project_id)
);

ALTER TABLE project_stars ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Stars viewable by all" ON project_stars;
DROP POLICY IF EXISTS "Users can star/unstar" ON project_stars;
DROP POLICY IF EXISTS "Stars are viewable by everyone" ON project_stars;
DROP POLICY IF EXISTS "Users can star projects" ON project_stars;
DROP POLICY IF EXISTS "Users can unstar projects" ON project_stars;

CREATE POLICY "Stars viewable by all" ON project_stars FOR SELECT USING (true);
CREATE POLICY "Users can star projects" ON project_stars FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unstar projects" ON project_stars FOR DELETE USING (auth.uid() = user_id);

-- ============ PROJECT COMMENTS TABLE ============
CREATE TABLE IF NOT EXISTS project_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  parent_comment_id UUID REFERENCES project_comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_edited BOOLEAN DEFAULT false,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE project_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Comments viewable by all" ON project_comments;
DROP POLICY IF EXISTS "Authenticated users can comment" ON project_comments;
DROP POLICY IF EXISTS "Users can edit own comments" ON project_comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON project_comments;

CREATE POLICY "Comments viewable by all" ON project_comments FOR SELECT USING (true);
CREATE POLICY "Authenticated users can comment" ON project_comments FOR INSERT 
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can edit own comments" ON project_comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON project_comments FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- SOCIAL/NETWORKING TABLES
-- ============================================================================

-- ============ CONNECTIONS TABLE (Enhanced) ============
-- Add new columns if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'connections' AND column_name = 'message') THEN
    ALTER TABLE connections ADD COLUMN message TEXT DEFAULT '';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  target_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending',
  message TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(requester_id, target_id)
);

ALTER TABLE connections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own connections" ON connections;
DROP POLICY IF EXISTS "Users can create requests" ON connections;
DROP POLICY IF EXISTS "Target can update status" ON connections;
DROP POLICY IF EXISTS "Users can delete own connections" ON connections;
DROP POLICY IF EXISTS "Users can create connection requests" ON connections;
DROP POLICY IF EXISTS "Target users can update connection status" ON connections;

CREATE POLICY "Users can view own connections" ON connections FOR SELECT
  USING (auth.uid() = requester_id OR auth.uid() = target_id);
CREATE POLICY "Users can create requests" ON connections FOR INSERT 
  WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Target can update status" ON connections FOR UPDATE 
  USING (auth.uid() = target_id OR auth.uid() = requester_id);
CREATE POLICY "Users can delete own connections" ON connections FOR DELETE
  USING (auth.uid() = requester_id OR auth.uid() = target_id);

-- ============ MESSAGES TABLE (Direct Messaging) ============
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  participant_1 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  participant_2 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(participant_1, participant_2)
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  attachment_url TEXT,
  is_read BOOLEAN DEFAULT false,
  is_edited BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can edit own messages" ON messages;

CREATE POLICY "Users can view own conversations" ON conversations FOR SELECT
  USING (auth.uid() = participant_1 OR auth.uid() = participant_2);
CREATE POLICY "Users can create conversations" ON conversations FOR INSERT
  WITH CHECK (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE POLICY "Users can view messages in their conversations" ON messages FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM conversations 
    WHERE id = conversation_id 
    AND (participant_1 = auth.uid() OR participant_2 = auth.uid())
  ));
CREATE POLICY "Users can send messages" ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can edit own messages" ON messages FOR UPDATE
  USING (auth.uid() = sender_id);

-- ============================================================================
-- ENGAGEMENT & ACTIVITY TABLES
-- ============================================================================

-- ============ NOTIFICATIONS TABLE (Enhanced) ============
-- Add missing columns to existing notifications table
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'reference_id') THEN
    ALTER TABLE notifications ADD COLUMN reference_id UUID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'reference_type') THEN
    ALTER TABLE notifications ADD COLUMN reference_type TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'from_user_id') THEN
    ALTER TABLE notifications ADD COLUMN from_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  from_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reference_id UUID,
  reference_type TEXT,
  action_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;

CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can delete own notifications" ON notifications FOR DELETE USING (auth.uid() = user_id);

-- ============ ACTIVITIES TABLE (Enhanced Feed) ============
-- Add missing columns to existing activities table
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'activities' AND column_name = 'is_public') THEN
    ALTER TABLE activities ADD COLUMN is_public BOOLEAN DEFAULT true;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'activities' AND column_name = 'metadata') THEN
    ALTER TABLE activities ADD COLUMN metadata JSONB DEFAULT '{}';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'activities' AND column_name = 'title') THEN
    ALTER TABLE activities ADD COLUMN title TEXT DEFAULT '';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  metadata JSONB DEFAULT '{}',
  target_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  target_project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public activities viewable by all" ON activities;
DROP POLICY IF EXISTS "Users can create own activities" ON activities;
DROP POLICY IF EXISTS "Activities are viewable by everyone" ON activities;
DROP POLICY IF EXISTS "Authenticated users can create activities" ON activities;

CREATE POLICY "Public activities viewable by all" ON activities FOR SELECT
  USING (COALESCE(is_public, true) = true OR auth.uid() = user_id);
CREATE POLICY "Users can create own activities" ON activities FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============ PROFILE VIEWS TABLE ============
CREATE TABLE IF NOT EXISTS profile_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  viewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT
);

ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile visitors" ON profile_views;
DROP POLICY IF EXISTS "Anyone can record view" ON profile_views;

CREATE POLICY "Users can view own profile visitors" ON profile_views FOR SELECT
  USING (auth.uid() = profile_id);
CREATE POLICY "Anyone can record view" ON profile_views FOR INSERT WITH CHECK (true);

-- ============================================================================
-- USER SETTINGS & PREFERENCES
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
  -- Privacy Settings
  show_email BOOLEAN DEFAULT false,
  show_online_status BOOLEAN DEFAULT true,
  allow_messages_from TEXT DEFAULT 'connections',
  show_profile_views BOOLEAN DEFAULT true,
  -- Notification Preferences
  email_notifications BOOLEAN DEFAULT true,
  push_notifications BOOLEAN DEFAULT true,
  notify_connection_requests BOOLEAN DEFAULT true,
  notify_messages BOOLEAN DEFAULT true,
  notify_project_stars BOOLEAN DEFAULT true,
  notify_comments BOOLEAN DEFAULT true,
  -- Display Preferences
  theme TEXT DEFAULT 'system',
  language TEXT DEFAULT 'en',
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can manage own settings" ON user_settings;

CREATE POLICY "Users can view own settings" ON user_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own settings" ON user_settings FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- MODERATION & REPORTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID REFERENCES profiles(id) ON DELETE SET NULL NOT NULL,
  reported_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reported_project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  reported_comment_id UUID REFERENCES project_comments(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  admin_notes TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can submit reports" ON reports;
DROP POLICY IF EXISTS "Users can view own reports" ON reports;

CREATE POLICY "Users can submit reports" ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Users can view own reports" ON reports FOR SELECT USING (auth.uid() = reporter_id);

-- ============================================================================
-- SEARCH & ANALYTICS
-- ============================================================================

CREATE TABLE IF NOT EXISTS search_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  query TEXT NOT NULL,
  search_type TEXT DEFAULT 'all',
  results_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE search_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own search history" ON search_history;

CREATE POLICY "Users can manage own search history" ON search_history FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to handle new user signup - creates profile and settings
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create profile (skip if exists)
  INSERT INTO profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- Create default settings (skip if exists)
  INSERT INTO user_settings (user_id) VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to increment project stats
CREATE OR REPLACE FUNCTION increment_project_stat(p_project_id UUID, stat_name TEXT)
RETURNS void AS $$
BEGIN
  EXECUTE format('UPDATE projects SET %I = %I + 1, updated_at = NOW() WHERE id = $1', 
    stat_name || '_count', stat_name || '_count')
  USING p_project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement project stats
CREATE OR REPLACE FUNCTION decrement_project_stat(p_project_id UUID, stat_name TEXT)
RETURNS void AS $$
BEGIN
  EXECUTE format('UPDATE projects SET %I = GREATEST(%I - 1, 0), updated_at = NOW() WHERE id = $1', 
    stat_name || '_count', stat_name || '_count')
  USING p_project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Auto-update star count when star is added/removed
CREATE OR REPLACE FUNCTION update_star_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Try stars_count first, then stars for backwards compatibility
    BEGIN
      UPDATE projects SET stars_count = COALESCE(stars_count, 0) + 1 WHERE id = NEW.project_id;
    EXCEPTION WHEN undefined_column THEN
      UPDATE projects SET stars = COALESCE(stars, 0) + 1 WHERE id = NEW.project_id;
    END;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    BEGIN
      UPDATE projects SET stars_count = GREATEST(COALESCE(stars_count, 0) - 1, 0) WHERE id = OLD.project_id;
    EXCEPTION WHEN undefined_column THEN
      UPDATE projects SET stars = GREATEST(COALESCE(stars, 0) - 1, 0) WHERE id = OLD.project_id;
    END;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_star_change ON project_stars;
CREATE TRIGGER on_star_change
  AFTER INSERT OR DELETE ON project_stars
  FOR EACH ROW EXECUTE FUNCTION update_star_count();

-- Trigger: Auto-update comment count
CREATE OR REPLACE FUNCTION update_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    BEGIN
      UPDATE projects SET comments_count = COALESCE(comments_count, 0) + 1 WHERE id = NEW.project_id;
    EXCEPTION WHEN undefined_column THEN
      NULL; -- Column doesn't exist, skip
    END;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    BEGIN
      UPDATE projects SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0) WHERE id = OLD.project_id;
    EXCEPTION WHEN undefined_column THEN
      NULL; -- Column doesn't exist, skip
    END;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_comment_change ON project_comments;
CREATE TRIGGER on_comment_change
  AFTER INSERT OR DELETE ON project_comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_count();

-- Trigger: Update follower counts on connection accept
CREATE OR REPLACE FUNCTION update_follower_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status = 'pending') THEN
    BEGIN
      UPDATE profiles SET following_count = COALESCE(following_count, 0) + 1 WHERE id = NEW.requester_id;
      UPDATE profiles SET followers_count = COALESCE(followers_count, 0) + 1 WHERE id = NEW.target_id;
    EXCEPTION WHEN undefined_column THEN
      NULL; -- Column doesn't exist, skip
    END;
  ELSIF OLD.status = 'accepted' AND NEW.status != 'accepted' THEN
    BEGIN
      UPDATE profiles SET following_count = GREATEST(COALESCE(following_count, 0) - 1, 0) WHERE id = NEW.requester_id;
      UPDATE profiles SET followers_count = GREATEST(COALESCE(followers_count, 0) - 1, 0) WHERE id = NEW.target_id;
    EXCEPTION WHEN undefined_column THEN
      NULL; -- Column doesn't exist, skip
    END;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_connection_update ON connections;
CREATE TRIGGER on_connection_update
  AFTER UPDATE ON connections
  FOR EACH ROW EXECUTE FUNCTION update_follower_counts();

-- Trigger: Update profile views count
CREATE OR REPLACE FUNCTION update_profile_views()
RETURNS TRIGGER AS $$
BEGIN
  BEGIN
    UPDATE profiles SET profile_views = COALESCE(profile_views, 0) + 1 WHERE id = NEW.profile_id;
  EXCEPTION WHEN undefined_column THEN
    NULL; -- Column doesn't exist, skip
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_view ON profile_views;
CREATE TRIGGER on_profile_view
  AFTER INSERT ON profile_views
  FOR EACH ROW EXECUTE FUNCTION update_profile_views();

-- Function: Update conversation last message time
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations SET last_message_at = NOW() WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_new_message ON messages;
CREATE TRIGGER on_new_message
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();

-- Function: Update user online status
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS void AS $$
BEGIN
  UPDATE profiles SET last_seen = NOW(), is_online = true WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get or create conversation between two users
CREATE OR REPLACE FUNCTION get_or_create_conversation(other_user_id UUID)
RETURNS UUID AS $$
DECLARE
  conv_id UUID;
  current_user_id UUID := auth.uid();
BEGIN
  -- Check if conversation exists (in either direction)
  SELECT id INTO conv_id FROM conversations 
  WHERE (participant_1 = current_user_id AND participant_2 = other_user_id)
     OR (participant_1 = other_user_id AND participant_2 = current_user_id)
  LIMIT 1;
  
  -- Create if not exists
  IF conv_id IS NULL THEN
    INSERT INTO conversations (participant_1, participant_2)
    VALUES (current_user_id, other_user_id)
    RETURNING id INTO conv_id;
  END IF;
  
  RETURN conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Create notification helper
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_from_user_id UUID DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  notif_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, from_user_id, reference_id, reference_type)
  VALUES (p_user_id, p_type, p_title, p_message, p_from_user_id, p_reference_id, p_reference_type)
  RETURNING id INTO notif_id;
  
  RETURN notif_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: User feed with activities from connections
CREATE OR REPLACE VIEW user_feed AS
SELECT 
  a.*,
  p.full_name as user_name,
  p.avatar_url as user_avatar
FROM activities a
JOIN profiles p ON a.user_id = p.id
WHERE COALESCE(a.is_public, true) = true
ORDER BY a.created_at DESC;

-- View: Popular projects
CREATE OR REPLACE VIEW popular_projects AS
SELECT 
  p.*,
  pr.full_name as owner_name,
  pr.avatar_url as owner_avatar
FROM projects p
JOIN profiles pr ON p.user_id = pr.id
WHERE COALESCE(p.is_public, true) = true
ORDER BY COALESCE(p.stars_count, p.stars, 0) DESC, COALESCE(p.views_count, 0) DESC;

-- View: User connections with profile info
CREATE OR REPLACE VIEW user_connections_view AS
SELECT 
  c.*,
  req.full_name as requester_name,
  req.avatar_url as requester_avatar,
  tgt.full_name as target_name,
  tgt.avatar_url as target_avatar
FROM connections c
JOIN profiles req ON c.requester_id = req.id
JOIN profiles tgt ON c.target_id = tgt.id;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- Create indexes only if columns exist
DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_profiles_full_name_trgm ON profiles USING gin(full_name gin_trgm_ops);
EXCEPTION WHEN undefined_column OR undefined_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_profiles_skills ON profiles USING gin(skills);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_profiles_course ON profiles(course);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_projects_name_trgm ON projects USING gin(name gin_trgm_ops);
EXCEPTION WHEN undefined_column OR undefined_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_projects_topics ON projects USING gin(topics);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_projects_technologies ON projects USING gin(technologies);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_connections_requester ON connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_connections_target ON connections(target_id);
CREATE INDEX IF NOT EXISTS idx_connections_status ON connections(status);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_activities_user ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON activities(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_project_comments_project ON project_comments(project_id);
CREATE INDEX IF NOT EXISTS idx_project_stars_project ON project_stars(project_id);

-- ============================================================================
-- ENABLE REALTIME
-- ============================================================================

-- Add tables to realtime publication (ignore errors if already added)
DO $$ 
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE connections;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE activities;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE project_comments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- SEED DATA: Default Skills
-- ============================================================================

INSERT INTO skills (name, category, icon_name, color) VALUES
  -- Programming Languages
  ('Dart', 'Programming', 'code', '#0175C2'),
  ('Python', 'Programming', 'code', '#3776AB'),
  ('JavaScript', 'Programming', 'code', '#F7DF1E'),
  ('TypeScript', 'Programming', 'code', '#3178C6'),
  ('Java', 'Programming', 'code', '#007396'),
  ('Kotlin', 'Programming', 'code', '#7F52FF'),
  ('Swift', 'Programming', 'code', '#FA7343'),
  ('C++', 'Programming', 'code', '#00599C'),
  ('C#', 'Programming', 'code', '#239120'),
  ('PHP', 'Programming', 'code', '#777BB4'),
  ('Ruby', 'Programming', 'code', '#CC342D'),
  ('Go', 'Programming', 'code', '#00ADD8'),
  ('Rust', 'Programming', 'code', '#000000'),
  -- Frameworks
  ('Flutter', 'Framework', 'smartphone', '#02569B'),
  ('React', 'Framework', 'web', '#61DAFB'),
  ('React Native', 'Framework', 'smartphone', '#61DAFB'),
  ('Vue.js', 'Framework', 'web', '#4FC08D'),
  ('Angular', 'Framework', 'web', '#DD0031'),
  ('Node.js', 'Framework', 'storage', '#339933'),
  ('Django', 'Framework', 'web', '#092E20'),
  ('Flask', 'Framework', 'web', '#000000'),
  ('Spring Boot', 'Framework', 'storage', '#6DB33F'),
  ('Laravel', 'Framework', 'web', '#FF2D20'),
  -- Databases
  ('PostgreSQL', 'Database', 'database', '#336791'),
  ('MySQL', 'Database', 'database', '#4479A1'),
  ('MongoDB', 'Database', 'database', '#47A248'),
  ('Firebase', 'Database', 'database', '#FFCA28'),
  ('Supabase', 'Database', 'database', '#3ECF8E'),
  ('Redis', 'Database', 'database', '#DC382D'),
  -- Cloud & DevOps
  ('AWS', 'Cloud', 'cloud', '#FF9900'),
  ('Google Cloud', 'Cloud', 'cloud', '#4285F4'),
  ('Azure', 'Cloud', 'cloud', '#0078D4'),
  ('Docker', 'DevOps', 'layers', '#2496ED'),
  ('Kubernetes', 'DevOps', 'layers', '#326CE5'),
  ('Git', 'DevOps', 'merge_type', '#F05032'),
  -- Design
  ('Figma', 'Design', 'brush', '#F24E1E'),
  ('Adobe XD', 'Design', 'brush', '#FF61F6'),
  ('UI/UX Design', 'Design', 'design_services', '#FF7262'),
  -- Other
  ('Machine Learning', 'AI/ML', 'psychology', '#FF6F00'),
  ('Data Science', 'AI/ML', 'analytics', '#3F51B5'),
  ('Cybersecurity', 'Security', 'security', '#E91E63'),
  ('Agile/Scrum', 'Methodology', 'groups', '#6200EA')
ON CONFLICT (name) DO NOTHING;
