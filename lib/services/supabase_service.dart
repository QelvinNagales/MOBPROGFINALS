import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration and Service
/// Handles all Supabase interactions including auth and database operations.
/// Enhanced for full-stack implementation with messaging, comments, skills, and more.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Supabase project credentials
  static const String supabaseUrl = 'https://jjuluneovkumyghxtsjt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqdWx1bmVvdmt1bXlnaHh0c2p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzNzkxMjIsImV4cCI6MjA4NTk1NTEyMn0.pCEV4jIfM4NqokO7Lhc_P9Jf1NsX0Ailvl5RI4Ggx1E';

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  /// Get current user ID
  static String? get userId => currentUser?.id;

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    
    // Profile is automatically created by database trigger (handle_new_user)
    // No need to manually create it here
    
    return response;
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ============ PROFILES ============

  /// Create a new profile
  static Future<void> createProfile({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    await client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'email': email,
      'bio': '',
      'pronouns': '',
      'facebook_username': '',
      'linkedin_username': '',
      'skills': [],
      'projects': [],
      'followers_count': 0,
      'following_count': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get current user's profile
  static Future<Map<String, dynamic>?> getProfile() async {
    if (userId == null) return null;
    
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId!)
        .single();
    
    return response;
  }

  /// Get profile by user ID
  static Future<Map<String, dynamic>?> getProfileById(String id) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .single();
    
    return response;
  }

  /// Update profile
  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (userId == null) return;
    
    data['updated_at'] = DateTime.now().toIso8601String();
    
    await client
        .from('profiles')
        .update(data)
        .eq('id', userId!);
  }

  /// Get all profiles (for explore)
  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final response = await client
        .from('profiles')
        .select()
        .neq('id', userId ?? '')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Search profiles
  static Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    final response = await client
        .from('profiles')
        .select()
        .or('full_name.ilike.%$query%,skills.cs.{$query}')
        .neq('id', userId ?? '');
    
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ PROJECTS/REPOSITORIES ============

  /// Create a new project
  static Future<Map<String, dynamic>> createProject({
    required String name,
    required String description,
    String language = 'Dart',
    bool isPublic = true,
    List<String> topics = const [],
  }) async {
    final response = await client.from('projects').insert({
      'user_id': userId,
      'name': name,
      'description': description,
      'language': language,
      'is_public': isPublic,
      'topics': topics,
      'stars': 0,
      'forks': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();
    
    return response;
  }

  /// Get current user's projects
  static Future<List<Map<String, dynamic>>> getMyProjects() async {
    if (userId == null) return [];
    
    final response = await client
        .from('projects')
        .select()
        .eq('user_id', userId!)
        .order('updated_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get projects by user ID
  static Future<List<Map<String, dynamic>>> getProjectsByUserId(String id) async {
    final response = await client
        .from('projects')
        .select()
        .eq('user_id', id)
        .eq('is_public', true)
        .order('updated_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update project
  static Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    
    await client
        .from('projects')
        .update(data)
        .eq('id', projectId);
  }

  /// Delete project
  static Future<void> deleteProject(String projectId) async {
    await client
        .from('projects')
        .delete()
        .eq('id', projectId);
  }

  /// Star a project
  static Future<void> starProject(String projectId) async {
    // Add to stars table
    await client.from('project_stars').insert({
      'user_id': userId,
      'project_id': projectId,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Increment star count
    await client.rpc('increment_stars', params: {'project_id': projectId});
  }

  /// Unstar a project
  static Future<void> unstarProject(String projectId) async {
    await client
        .from('project_stars')
        .delete()
        .eq('user_id', userId!)
        .eq('project_id', projectId);
    
    await client.rpc('decrement_stars', params: {'project_id': projectId});
  }

  // ============ CONNECTIONS/FRIENDS ============

  /// Send connection request
  static Future<void> sendConnectionRequest(String targetUserId) async {
    await client.from('connections').insert({
      'requester_id': userId,
      'target_id': targetUserId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Create notification for target user
    await createNotification(
      targetUserId: targetUserId,
      type: 'connection_request',
      title: 'New Connection Request',
      message: 'Someone wants to connect with you',
    );
  }

  /// Accept connection request
  static Future<void> acceptConnection(String connectionId) async {
    await client
        .from('connections')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', connectionId);
    
    // Update follower counts
    // This would be handled by database triggers ideally
  }

  /// Reject connection request
  static Future<void> rejectConnection(String connectionId) async {
    await client
        .from('connections')
        .update({
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', connectionId);
  }

  /// Get my connections
  static Future<List<Map<String, dynamic>>> getMyConnections() async {
    if (userId == null) return [];
    
    final response = await client
        .from('connections')
        .select('*, profiles!connections_target_id_fkey(*)')
        .eq('requester_id', userId!)
        .eq('status', 'accepted');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get pending connection requests
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    if (userId == null) return [];
    
    final response = await client
        .from('connections')
        .select('*, profiles!connections_requester_id_fkey(*)')
        .eq('target_id', userId!)
        .eq('status', 'pending');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Check if connected with user
  static Future<bool> isConnectedWith(String targetUserId) async {
    if (userId == null) return false;
    
    final response = await client
        .from('connections')
        .select()
        .or('and(requester_id.eq.$userId,target_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,target_id.eq.$userId)')
        .eq('status', 'accepted');
    
    return (response as List).isNotEmpty;
  }

  // ============ NOTIFICATIONS ============

  /// Create notification
  static Future<void> createNotification({
    required String targetUserId,
    required String type,
    required String title,
    required String message,
  }) async {
    await client.from('notifications').insert({
      'user_id': targetUserId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get my notifications
  static Future<List<Map<String, dynamic>>> getMyNotifications() async {
    if (userId == null) return [];
    
    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Mark notification as read
  static Future<void> markNotificationRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsRead() async {
    if (userId == null) return;
    
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId!);
  }

  /// Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    if (userId == null) return 0;
    
    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId!)
        .eq('is_read', false);
    
    return (response as List).length;
  }

  // ============ ACTIVITIES ============

  /// Create activity
  static Future<void> createActivity({
    required String type,
    required String title,
    required String description,
    String? targetUserId,
    String? targetProjectId,
  }) async {
    await client.from('activities').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'target_user_id': targetUserId,
      'target_project_id': targetProjectId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get my activities
  static Future<List<Map<String, dynamic>>> getMyActivities() async {
    if (userId == null) return [];
    
    final response = await client
        .from('activities')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false)
        .limit(20);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get feed activities (from connections)
  static Future<List<Map<String, dynamic>>> getFeedActivities() async {
    if (userId == null) return [];
    
    // Get activities from user and their connections
    final response = await client
        .from('activities')
        .select('*, profiles!activities_user_id_fkey(full_name, email)')
        .order('created_at', ascending: false)
        .limit(50);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // ============ REAL-TIME SUBSCRIPTIONS ============

  /// Subscribe to notifications
  static RealtimeChannel subscribeToNotifications(
    void Function(Map<String, dynamic>) onNotification,
  ) {
    return client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to connection requests
  static RealtimeChannel subscribeToConnectionRequests(
    void Function(Map<String, dynamic>) onRequest,
  ) {
    return client
        .channel('connections:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'connections',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_id',
            value: userId,
          ),
          callback: (payload) {
            onRequest(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  // ============================================================================
  // MESSAGING SYSTEM
  // ============================================================================

  /// Get or create a conversation with another user
  static Future<String> getOrCreateConversation(String otherUserId) async {
    final response = await client.rpc('get_or_create_conversation', params: {
      'other_user_id': otherUserId,
    });
    return response as String;
  }

  /// Get all conversations for current user
  static Future<List<Map<String, dynamic>>> getConversations() async {
    if (userId == null) return [];
    
    final response = await client
        .from('conversations')
        .select('''
          *,
          participant_1_profile:profiles!conversations_participant_1_fkey(id, full_name, avatar_url, is_online, last_seen),
          participant_2_profile:profiles!conversations_participant_2_fkey(id, full_name, avatar_url, is_online, last_seen)
        ''')
        .or('participant_1.eq.$userId,participant_2.eq.$userId')
        .order('last_message_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get messages in a conversation
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    final response = await client
        .from('messages')
        .select('''
          *,
          sender:profiles!messages_sender_id_fkey(id, full_name, avatar_url)
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Send a message
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    final response = await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();
    
    return response;
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String conversationId) async {
    await client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId!);
  }

  /// Get unread messages count
  static Future<int> getUnreadMessagesCount() async {
    if (userId == null) return 0;
    
    // Get all conversations user is part of
    final conversations = await client
        .from('conversations')
        .select('id')
        .or('participant_1.eq.$userId,participant_2.eq.$userId');
    
    if ((conversations as List).isEmpty) return 0;
    
    final convIds = conversations.map((c) => c['id']).toList();
    
    final response = await client
        .from('messages')
        .select()
        .inFilter('conversation_id', convIds)
        .eq('is_read', false)
        .neq('sender_id', userId!);
    
    return (response as List).length;
  }

  /// Subscribe to new messages in a conversation
  static RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Map<String, dynamic>) onMessage,
  ) {
    return client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  // ============================================================================
  // PROJECT COMMENTS
  // ============================================================================

  /// Get comments for a project
  static Future<List<Map<String, dynamic>>> getProjectComments(String projectId) async {
    final response = await client
        .from('project_comments')
        .select('''
          *,
          user:profiles!project_comments_user_id_fkey(id, full_name, avatar_url)
        ''')
        .eq('project_id', projectId)
        .isFilter('parent_comment_id', null) // Get top-level comments only
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get replies to a comment
  static Future<List<Map<String, dynamic>>> getCommentReplies(String commentId) async {
    final response = await client
        .from('project_comments')
        .select('''
          *,
          user:profiles!project_comments_user_id_fkey(id, full_name, avatar_url)
        ''')
        .eq('parent_comment_id', commentId)
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a comment to a project
  static Future<Map<String, dynamic>> addComment({
    required String projectId,
    required String content,
    String? parentCommentId,
  }) async {
    final response = await client.from('project_comments').insert({
      'project_id': projectId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'created_at': DateTime.now().toIso8601String(),
    }).select('''
      *,
      user:profiles!project_comments_user_id_fkey(id, full_name, avatar_url)
    ''').single();
    
    // Create notification for project owner
    final project = await client.from('projects').select('user_id, name').eq('id', projectId).single();
    if (project['user_id'] != userId) {
      await createNotification(
        targetUserId: project['user_id'],
        type: 'project_comment',
        title: 'New Comment',
        message: 'Someone commented on "${project['name']}"',
      );
    }
    
    return response;
  }

  /// Update a comment
  static Future<void> updateComment(String commentId, String content) async {
    await client
        .from('project_comments')
        .update({
          'content': content,
          'is_edited': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', commentId);
  }

  /// Delete a comment
  static Future<void> deleteComment(String commentId) async {
    await client.from('project_comments').delete().eq('id', commentId);
  }

  // ============================================================================
  // SKILLS MANAGEMENT
  // ============================================================================

  /// Get all available skills
  static Future<List<Map<String, dynamic>>> getAllSkills() async {
    final response = await client
        .from('skills')
        .select()
        .order('category')
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get skills by category
  static Future<List<Map<String, dynamic>>> getSkillsByCategory(String category) async {
    final response = await client
        .from('skills')
        .select()
        .eq('category', category)
        .order('name');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Search skills
  static Future<List<Map<String, dynamic>>> searchSkills(String query) async {
    final response = await client
        .from('skills')
        .select()
        .ilike('name', '%$query%')
        .order('usage_count', ascending: false)
        .limit(20);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user's skills with details
  static Future<List<Map<String, dynamic>>> getUserSkills(String profileId) async {
    final response = await client
        .from('user_skills')
        .select('''
          *,
          skill:skills(*)
        ''')
        .eq('user_id', profileId)
        .order('is_primary', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add skill to user profile
  static Future<void> addUserSkill({
    required String skillId,
    int proficiencyLevel = 3,
    double yearsExperience = 0,
    bool isPrimary = false,
  }) async {
    await client.from('user_skills').insert({
      'user_id': userId,
      'skill_id': skillId,
      'proficiency_level': proficiencyLevel,
      'years_experience': yearsExperience,
      'is_primary': isPrimary,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Update skill usage count
    await client.rpc('increment_skill_usage', params: {'skill_id': skillId});
  }

  /// Update user skill
  static Future<void> updateUserSkill({
    required String userSkillId,
    int? proficiencyLevel,
    double? yearsExperience,
    bool? isPrimary,
  }) async {
    final updates = <String, dynamic>{};
    if (proficiencyLevel != null) updates['proficiency_level'] = proficiencyLevel;
    if (yearsExperience != null) updates['years_experience'] = yearsExperience;
    if (isPrimary != null) updates['is_primary'] = isPrimary;
    
    if (updates.isNotEmpty) {
      await client.from('user_skills').update(updates).eq('id', userSkillId);
    }
  }

  /// Remove skill from user profile
  static Future<void> removeUserSkill(String userSkillId) async {
    await client.from('user_skills').delete().eq('id', userSkillId);
  }

  /// Create a new skill (if doesn't exist)
  static Future<Map<String, dynamic>> createSkill({
    required String name,
    String category = 'General',
  }) async {
    final response = await client.from('skills').insert({
      'name': name,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();
    
    return response;
  }

  // ============================================================================
  // PROFILE VIEWS & ANALYTICS
  // ============================================================================

  /// Record a profile view
  static Future<void> recordProfileView(String profileId) async {
    // Don't record self-views
    if (profileId == userId) return;
    
    await client.from('profile_views').insert({
      'profile_id': profileId,
      'viewer_id': userId,
      'viewed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get profile viewers (who viewed my profile)
  static Future<List<Map<String, dynamic>>> getProfileViewers({int limit = 20}) async {
    if (userId == null) return [];
    
    final response = await client
        .from('profile_views')
        .select('''
          *,
          viewer:profiles!profile_views_viewer_id_fkey(id, full_name, avatar_url, course, year_level)
        ''')
        .eq('profile_id', userId!)
        .order('viewed_at', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get profile view count for a specific period
  static Future<int> getProfileViewCount({int days = 30}) async {
    if (userId == null) return 0;
    
    final startDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    
    final response = await client
        .from('profile_views')
        .select()
        .eq('profile_id', userId!)
        .gte('viewed_at', startDate);
    
    return (response as List).length;
  }

  // ============================================================================
  // USER SETTINGS
  // ============================================================================

  /// Get user settings
  static Future<Map<String, dynamic>?> getUserSettings() async {
    if (userId == null) return null;
    
    try {
      final response = await client
          .from('user_settings')
          .select()
          .eq('user_id', userId!)
          .single();
      return response;
    } catch (e) {
      // Settings don't exist, create default
      await client.from('user_settings').insert({'user_id': userId});
      return getUserSettings();
    }
  }

  /// Update user settings
  static Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    if (userId == null) return;
    
    settings['updated_at'] = DateTime.now().toIso8601String();
    
    await client
        .from('user_settings')
        .update(settings)
        .eq('user_id', userId!);
  }

  // ============================================================================
  // PROJECT COLLABORATORS
  // ============================================================================

  /// Get project collaborators
  static Future<List<Map<String, dynamic>>> getProjectCollaborators(String projectId) async {
    final response = await client
        .from('project_collaborators')
        .select('''
          *,
          user:profiles!project_collaborators_user_id_fkey(id, full_name, avatar_url, email)
        ''')
        .eq('project_id', projectId)
        .order('role');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add collaborator to project
  static Future<void> addCollaborator({
    required String projectId,
    required String userId,
    String role = 'contributor',
  }) async {
    await client.from('project_collaborators').insert({
      'project_id': projectId,
      'user_id': userId,
      'role': role,
      'joined_at': DateTime.now().toIso8601String(),
    });
    
    // Create notification
    await createNotification(
      targetUserId: userId,
      type: 'collaboration_started',
      title: 'Project Collaboration',
      message: 'You have been added as a collaborator',
    );
  }

  /// Update collaborator role
  static Future<void> updateCollaboratorRole(String collaboratorId, String role) async {
    await client
        .from('project_collaborators')
        .update({'role': role})
        .eq('id', collaboratorId);
  }

  /// Remove collaborator
  static Future<void> removeCollaborator(String collaboratorId) async {
    await client.from('project_collaborators').delete().eq('id', collaboratorId);
  }

  /// Get projects where user is a collaborator
  static Future<List<Map<String, dynamic>>> getCollaboratingProjects() async {
    if (userId == null) return [];
    
    final response = await client
        .from('project_collaborators')
        .select('''
          *,
          project:projects(*)
        ''')
        .eq('user_id', userId!)
        .order('joined_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================================
  // SEARCH FUNCTIONALITY
  // ============================================================================

  /// Search everything (users, projects, skills)
  static Future<Map<String, List<Map<String, dynamic>>>> globalSearch(String query) async {
    final results = <String, List<Map<String, dynamic>>>{
      'users': [],
      'projects': [],
      'skills': [],
    };
    
    // Search users
    final users = await client
        .from('profiles')
        .select()
        .or('full_name.ilike.%$query%,email.ilike.%$query%,course.ilike.%$query%')
        .neq('id', userId ?? '')
        .limit(10);
    results['users'] = List<Map<String, dynamic>>.from(users);
    
    // Search projects
    final projects = await client
        .from('projects')
        .select('''
          *,
          owner:profiles!projects_user_id_fkey(id, full_name, avatar_url)
        ''')
        .eq('is_public', true)
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .limit(10);
    results['projects'] = List<Map<String, dynamic>>.from(projects);
    
    // Search skills
    final skills = await client
        .from('skills')
        .select()
        .ilike('name', '%$query%')
        .limit(10);
    results['skills'] = List<Map<String, dynamic>>.from(skills);
    
    // Record search history
    await _recordSearchHistory(query, 'all', 
      results['users']!.length + results['projects']!.length + results['skills']!.length);
    
    return results;
  }

  /// Record search history
  static Future<void> _recordSearchHistory(String query, String searchType, int resultsCount) async {
    if (userId == null) return;
    
    await client.from('search_history').insert({
      'user_id': userId,
      'query': query,
      'search_type': searchType,
      'results_count': resultsCount,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get recent searches
  static Future<List<String>> getRecentSearches({int limit = 10}) async {
    if (userId == null) return [];
    
    final response = await client
        .from('search_history')
        .select('query')
        .eq('user_id', userId!)
        .order('created_at', ascending: false)
        .limit(limit);
    
    final searches = (response as List).map((s) => s['query'] as String).toSet().toList();
    return searches;
  }

  /// Clear search history
  static Future<void> clearSearchHistory() async {
    if (userId == null) return;
    await client.from('search_history').delete().eq('user_id', userId!);
  }

  // ============================================================================
  // REPORTS & MODERATION
  // ============================================================================

  /// Report a user
  static Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String description = '',
  }) async {
    await client.from('reports').insert({
      'reporter_id': userId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Report a project
  static Future<void> reportProject({
    required String projectId,
    required String reason,
    String description = '',
  }) async {
    await client.from('reports').insert({
      'reporter_id': userId,
      'reported_project_id': projectId,
      'reason': reason,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Report a comment
  static Future<void> reportComment({
    required String commentId,
    required String reason,
    String description = '',
  }) async {
    await client.from('reports').insert({
      'reporter_id': userId,
      'reported_comment_id': commentId,
      'reason': reason,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================================
  // ENHANCED PROJECT METHODS
  // ============================================================================

  /// Get popular projects
  static Future<List<Map<String, dynamic>>> getPopularProjects({int limit = 20}) async {
    final response = await client
        .from('projects')
        .select('''
          *,
          owner:profiles!projects_user_id_fkey(id, full_name, avatar_url)
        ''')
        .eq('is_public', true)
        .order('stars_count', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get recent projects
  static Future<List<Map<String, dynamic>>> getRecentProjects({int limit = 20}) async {
    final response = await client
        .from('projects')
        .select('''
          *,
          owner:profiles!projects_user_id_fkey(id, full_name, avatar_url)
        ''')
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Record project view
  static Future<void> recordProjectView(String projectId) async {
    await client.rpc('increment_project_stat', params: {
      'p_project_id': projectId,
      'stat_name': 'views',
    });
  }

  /// Check if user starred a project
  static Future<bool> hasStarredProject(String projectId) async {
    if (userId == null) return false;
    
    final response = await client
        .from('project_stars')
        .select()
        .eq('user_id', userId!)
        .eq('project_id', projectId);
    
    return (response as List).isNotEmpty;
  }

  // ============================================================================
  // ONLINE STATUS
  // ============================================================================

  /// Update online status
  static Future<void> updateOnlineStatus(bool isOnline) async {
    if (userId == null) return;
    
    await client
        .from('profiles')
        .update({
          'is_online': isOnline,
          'last_seen': DateTime.now().toIso8601String(),
        })
        .eq('id', userId!);
  }

  /// Set user online
  static Future<void> setOnline() async {
    await updateOnlineStatus(true);
  }

  /// Set user offline
  static Future<void> setOffline() async {
    await updateOnlineStatus(false);
  }

  // ============================================================================
  // STORAGE - IMAGE UPLOADS
  // ============================================================================

  /// Upload profile picture
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadProfilePicture(List<int> imageBytes, String fileName) async {
    if (userId == null) return null;
    
    try {
      final String filePath = 'avatars/$userId/$fileName';
      
      // Upload to Supabase Storage
      await client.storage
          .from('profiles')
          .uploadBinary(
            filePath,
            imageBytes as dynamic,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get public URL
      final String publicUrl = client.storage
          .from('profiles')
          .getPublicUrl(filePath);
      
      // Update profile with new avatar URL
      await updateProfile({'avatar_url': publicUrl});
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Upload project image
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadProjectImage(List<int> imageBytes, String fileName, {String? projectId}) async {
    if (userId == null) return null;
    
    try {
      final String id = projectId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = 'projects/$userId/$id/$fileName';
      
      // Upload to Supabase Storage
      await client.storage
          .from('projects')
          .uploadBinary(
            filePath,
            imageBytes as dynamic,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get public URL
      final String publicUrl = client.storage
          .from('projects')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading project image: $e');
      return null;
    }
  }

  /// Delete image from storage
  static Future<bool> deleteImage(String bucket, String filePath) async {
    try {
      await client.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
}
