-- Project Features Migration
-- Run this in your Supabase SQL Editor

-- ============ UPDATE PROJECTS TABLE ============

-- Add new columns to projects table
ALTER TABLE projects ADD COLUMN IF NOT EXISTS looking_for_team BOOLEAN DEFAULT false;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS screenshots TEXT[] DEFAULT '{}';
ALTER TABLE projects ADD COLUMN IF NOT EXISTS video_url TEXT;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS docs_url TEXT;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'in_progress', 'completed', 'on_hold'));

-- ============ PROJECT COMMENTS TABLE ============

CREATE TABLE IF NOT EXISTS project_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_project_comments_project_id ON project_comments(project_id);
CREATE INDEX IF NOT EXISTS idx_project_comments_user_id ON project_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_project_comments_created_at ON project_comments(created_at DESC);

-- Enable RLS
ALTER TABLE project_comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view comments on public projects" ON project_comments;
DROP POLICY IF EXISTS "Users can view comments on their own projects" ON project_comments;
DROP POLICY IF EXISTS "Authenticated users can create comments" ON project_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON project_comments;

-- RLS Policies for project_comments
CREATE POLICY "Anyone can view comments on public projects" ON project_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = project_comments.project_id 
      AND projects.is_public = true
    )
  );

CREATE POLICY "Users can view comments on their own projects" ON project_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM projects 
      WHERE projects.id = project_comments.project_id 
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create comments" ON project_comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON project_comments
  FOR DELETE USING (auth.uid() = user_id);

-- ============ COLLABORATION REQUESTS TABLE ============

CREATE TABLE IF NOT EXISTS collaboration_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent duplicate requests
  UNIQUE(project_id, requester_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_collab_requests_project_id ON collaboration_requests(project_id);
CREATE INDEX IF NOT EXISTS idx_collab_requests_requester_id ON collaboration_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_collab_requests_owner_id ON collaboration_requests(owner_id);
CREATE INDEX IF NOT EXISTS idx_collab_requests_status ON collaboration_requests(status);

-- Enable RLS
ALTER TABLE collaboration_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own sent requests" ON collaboration_requests;
DROP POLICY IF EXISTS "Project owners can view requests for their projects" ON collaboration_requests;
DROP POLICY IF EXISTS "Authenticated users can create requests" ON collaboration_requests;
DROP POLICY IF EXISTS "Project owners can update requests" ON collaboration_requests;

-- RLS Policies for collaboration_requests
CREATE POLICY "Users can view their own sent requests" ON collaboration_requests
  FOR SELECT USING (auth.uid() = requester_id);

CREATE POLICY "Project owners can view requests for their projects" ON collaboration_requests
  FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Authenticated users can create requests" ON collaboration_requests
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Project owners can update requests" ON collaboration_requests
  FOR UPDATE USING (auth.uid() = owner_id);

-- ============ PROJECT STARS TABLE (if not exists) ============

CREATE TABLE IF NOT EXISTS project_stars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, project_id)
);

CREATE INDEX IF NOT EXISTS idx_project_stars_user_id ON project_stars(user_id);
CREATE INDEX IF NOT EXISTS idx_project_stars_project_id ON project_stars(project_id);

ALTER TABLE project_stars ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view stars" ON project_stars;
DROP POLICY IF EXISTS "Authenticated users can star projects" ON project_stars;
DROP POLICY IF EXISTS "Users can unstar projects" ON project_stars;

CREATE POLICY "Anyone can view stars" ON project_stars
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can star projects" ON project_stars
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unstar projects" ON project_stars
  FOR DELETE USING (auth.uid() = user_id);

-- ============ RPC FUNCTIONS ============

-- Function to increment stars count
CREATE OR REPLACE FUNCTION increment_stars(project_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE projects 
  SET stars_count = COALESCE(stars_count, 0) + 1
  WHERE id = project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement stars count
CREATE OR REPLACE FUNCTION decrement_stars(project_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE projects 
  SET stars_count = GREATEST(COALESCE(stars_count, 0) - 1, 0)
  WHERE id = project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment views count
CREATE OR REPLACE FUNCTION increment_project_views(project_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE projects 
  SET views_count = COALESCE(views_count, 0) + 1
  WHERE id = project_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION increment_stars(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_stars(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_project_views(UUID) TO authenticated;

-- ============ UPDATED_AT TRIGGERS ============

-- Create trigger function if not exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
DROP TRIGGER IF EXISTS update_project_comments_updated_at ON project_comments;
CREATE TRIGGER update_project_comments_updated_at
  BEFORE UPDATE ON project_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_collaboration_requests_updated_at ON collaboration_requests;
CREATE TRIGGER update_collaboration_requests_updated_at
  BEFORE UPDATE ON collaboration_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
