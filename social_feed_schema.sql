-- Social Feed & Network Feature Tables
-- Run this SQL in your Supabase SQL Editor to add the social feed and networking features

-- ============================================================================
-- POSTS TABLE (Social Feed)
-- ============================================================================

CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT,
  content TEXT NOT NULL,
  images TEXT[] DEFAULT '{}',
  original_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
  quote_text TEXT,
  reposter_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_repost BOOLEAN DEFAULT false,
  is_quote_repost BOOLEAN DEFAULT false,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  reposts_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add new columns if table exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'posts' AND column_name = 'title') THEN
    ALTER TABLE posts ADD COLUMN title TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'posts' AND column_name = 'quote_text') THEN
    ALTER TABLE posts ADD COLUMN quote_text TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'posts' AND column_name = 'reposter_id') THEN
    ALTER TABLE posts ADD COLUMN reposter_id UUID REFERENCES profiles(id) ON DELETE SET NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'posts' AND column_name = 'is_quote_repost') THEN
    ALTER TABLE posts ADD COLUMN is_quote_repost BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Indexes for posts
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);

-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for posts
DROP POLICY IF EXISTS "Anyone can view posts" ON posts;
CREATE POLICY "Anyone can view posts" ON posts
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create their own posts" ON posts;
CREATE POLICY "Users can create their own posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
CREATE POLICY "Users can update their own posts" ON posts
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;
CREATE POLICY "Users can delete their own posts" ON posts
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- POST LIKES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS post_likes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);

-- Enable RLS
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Anyone can view post likes" ON post_likes;
CREATE POLICY "Anyone can view post likes" ON post_likes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can like posts" ON post_likes;
CREATE POLICY "Users can like posts" ON post_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike posts" ON post_likes;
CREATE POLICY "Users can unlike posts" ON post_likes
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- POST COMMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS post_comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_user_id ON post_comments(user_id);

-- Enable RLS
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Anyone can view comments" ON post_comments;
CREATE POLICY "Anyone can view comments" ON post_comments
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create comments" ON post_comments;
CREATE POLICY "Users can create comments" ON post_comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their comments" ON post_comments;
CREATE POLICY "Users can update their comments" ON post_comments
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their comments" ON post_comments;
CREATE POLICY "Users can delete their comments" ON post_comments
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- CONNECTION REQUESTS TABLE (Friend Requests)
-- ============================================================================

CREATE TABLE IF NOT EXISTS connection_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(sender_id, receiver_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_connection_requests_sender ON connection_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_connection_requests_receiver ON connection_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_connection_requests_status ON connection_requests(status);

-- Enable RLS
ALTER TABLE connection_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their connection requests" ON connection_requests;
CREATE POLICY "Users can view their connection requests" ON connection_requests
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send connection requests" ON connection_requests;
CREATE POLICY "Users can send connection requests" ON connection_requests
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Receivers can update connection requests" ON connection_requests;
CREATE POLICY "Receivers can update connection requests" ON connection_requests
  FOR UPDATE USING (auth.uid() = receiver_id);

-- ============================================================================
-- FRIENDSHIPS TABLE (Confirmed Connections)
-- ============================================================================

CREATE TABLE IF NOT EXISTS friendships (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);

-- Enable RLS
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their friendships" ON friendships;
CREATE POLICY "Users can view their friendships" ON friendships
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS "Users can create friendships" ON friendships;
CREATE POLICY "Users can create friendships" ON friendships
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their friendships" ON friendships;
CREATE POLICY "Users can delete their friendships" ON friendships
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCTIONS FOR POST COUNTS
-- ============================================================================

-- Increment post likes
CREATE OR REPLACE FUNCTION increment_post_likes(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET likes_count = likes_count + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement post likes
CREATE OR REPLACE FUNCTION decrement_post_likes(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment post comments
CREATE OR REPLACE FUNCTION increment_post_comments(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET comments_count = comments_count + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement post comments
CREATE OR REPLACE FUNCTION decrement_post_comments(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment post reposts
CREATE OR REPLACE FUNCTION increment_post_reposts(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET reposts_count = reposts_count + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANT EXECUTE PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION increment_post_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_post_likes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_post_comments(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_post_comments(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_post_reposts(UUID) TO authenticated;

-- ============================================================================
-- CONNECTION MANAGEMENT FUNCTIONS
-- ============================================================================

-- Accept a connection request and create bidirectional friendship
-- Uses SECURITY DEFINER to bypass RLS for creating both friendship records
CREATE OR REPLACE FUNCTION accept_connection_request(request_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_sender_id UUID;
  v_receiver_id UUID;
  v_current_user UUID;
BEGIN
  v_current_user := auth.uid();
  
  -- Get the request and verify the current user is the receiver
  SELECT sender_id, receiver_id INTO v_sender_id, v_receiver_id
  FROM connection_requests
  WHERE id = request_id AND status = 'pending';
  
  IF v_receiver_id IS NULL THEN
    RAISE EXCEPTION 'Request not found or already processed';
  END IF;
  
  IF v_receiver_id != v_current_user THEN
    RAISE EXCEPTION 'Only the receiver can accept this request';
  END IF;
  
  -- Update request status
  UPDATE connection_requests SET status = 'accepted', updated_at = NOW()
  WHERE id = request_id;
  
  -- Create bidirectional friendships
  INSERT INTO friendships (user_id, friend_id) VALUES (v_receiver_id, v_sender_id)
  ON CONFLICT (user_id, friend_id) DO NOTHING;
  
  INSERT INTO friendships (user_id, friend_id) VALUES (v_sender_id, v_receiver_id)
  ON CONFLICT (user_id, friend_id) DO NOTHING;
  
  -- Update followers_count for both users
  UPDATE profiles SET followers_count = COALESCE(followers_count, 0) + 1 WHERE id = v_sender_id;
  UPDATE profiles SET followers_count = COALESCE(followers_count, 0) + 1 WHERE id = v_receiver_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove a connection (unfriend)
CREATE OR REPLACE FUNCTION remove_connection(friend_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_user UUID;
BEGIN
  v_current_user := auth.uid();
  
  -- Delete both directions
  DELETE FROM friendships WHERE user_id = v_current_user AND friendships.friend_id = remove_connection.friend_id;
  DELETE FROM friendships WHERE user_id = remove_connection.friend_id AND friendships.friend_id = v_current_user;
  
  -- Update followers_count for both users
  UPDATE profiles SET followers_count = GREATEST(COALESCE(followers_count, 0) - 1, 0) WHERE id = friend_id;
  UPDATE profiles SET followers_count = GREATEST(COALESCE(followers_count, 0) - 1, 0) WHERE id = v_current_user;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION accept_connection_request(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_connection(UUID) TO authenticated;
