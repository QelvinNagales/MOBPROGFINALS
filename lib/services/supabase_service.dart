import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

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

  /// Delete account - fully deletes user from database (including auth.users)
  /// After deletion, the user cannot log in again
  /// Requires password re-confirmation for security
  static Future<({bool success, String? error})> deleteAccountWithPassword(String password) async {
    if (userId == null) return (success: false, error: 'Not logged in');
    
    final email = client.auth.currentUser?.email;
    if (email == null) return (success: false, error: 'No email found');

    try {
      // Step 1: Verify password by attempting to sign in again
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('Password verified successfully');
      
      // Step 2: Call the RPC function that deletes profile AND auth.users entry
      final result = await client
          .rpc('delete_user_account')
          .timeout(const Duration(seconds: 10));
      
      debugPrint('delete_user_account RPC result: $result');
      
      // Step 3: Sign out locally
      try {
        await signOut();
      } catch (e) {
        debugPrint('Sign out after delete: $e');
      }
      
      return (success: result == true, error: result == true ? null : 'Failed to delete from database');
    } on AuthException catch (e) {
      debugPrint('Auth error during delete: ${e.message}');
      return (success: false, error: 'Incorrect password');
    } catch (e) {
      debugPrint('Error in deleteAccountWithPassword: $e');
      return (success: false, error: e.toString());
    }
  }

  /// Delete account without password (legacy method)
  static Future<bool> deleteAccount() async {
    final result = await deleteAccountWithPassword('');
    return result.success;
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
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error fetching profile for id $id: $e');
      return null;
    }
  }

  /// Alias for getProfileById (used by UserProfileViewScreen)
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return getProfileById(userId);
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

  /// Search profiles by name, email, username, or bio
  static Future<List<Map<String, dynamic>>> searchProfiles(String query) async {
    final response = await client
        .from('profiles')
        .select()
        .or('full_name.ilike.%$query%,username.ilike.%$query%,email.ilike.%$query%,bio.ilike.%$query%')
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
    String? thumbnailUrl,
    String status = 'in_progress',
    List<String> technologies = const [],
    String? githubUrl,
    String? demoUrl,
    String? longDescription,
  }) async {
    // Build data map with only non-null optional fields
    // This provides compatibility with both basic and enhanced schemas
    final Map<String, dynamic> data = {
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
    };
    
    // Add optional enhanced fields only if provided
    if (longDescription != null && longDescription.isNotEmpty) {
      data['long_description'] = longDescription;
    }
    if (technologies.isNotEmpty) {
      data['technologies'] = technologies;
    }
    if (status != 'in_progress') {
      data['status'] = status;
    }
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      data['thumbnail_url'] = thumbnailUrl;
    }
    if (githubUrl != null && githubUrl.isNotEmpty) {
      data['github_url'] = githubUrl;
    }
    if (demoUrl != null && demoUrl.isNotEmpty) {
      data['demo_url'] = demoUrl;
    }
    
    final response = await client.from('projects').insert(data).select().single();
    
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

  /// Alias for getProjectsByUserId (used by UserProfileViewScreen)
  static Future<List<Map<String, dynamic>>> getUserRepositories(String userId) async {
    return getProjectsByUserId(userId);
  }

  /// Get all public projects from other users (for explore feature)
  static Future<List<Map<String, dynamic>>> getExploreProjects() async {
    final response = await client
        .from('projects')
        .select('''
          *,
          profiles!projects_user_id_fkey (
            id,
            full_name,
            avatar_url
          )
        ''')
        .eq('is_public', true)
        .neq('user_id', userId ?? '')
        .order('stars_count', ascending: false)
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
    
    // Notify the project owner
    try {
      final project = await client
          .from('projects')
          .select('user_id, name')
          .eq('id', projectId)
          .maybeSingle();
      
      if (project != null && project['user_id'] != userId) {
        final myProfile = await getProfile();
        final myName = myProfile?['full_name'] ?? 'Someone';
        final projectName = project['name'] ?? 'your project';
        
        await createNotification(
          targetUserId: project['user_id'],
          type: 'project_star',
          title: 'New Star!',
          message: '$myName starred your project "$projectName"',
          fromUserId: userId,
        );
      }
    } catch (e) {
      debugPrint('Error sending star notification: $e');
    }
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

  /// Check if user has starred a project
  static Future<bool> hasStarredProject(String projectId) async {
    if (userId == null) return false;
    
    final response = await client
        .from('project_stars')
        .select('id')
        .eq('user_id', userId!)
        .eq('project_id', projectId)
        .maybeSingle();
    
    return response != null;
  }

  /// Get IDs of all projects starred by current user
  static Future<Set<String>> getStarredProjectIds() async {
    if (userId == null) return {};
    
    final response = await client
        .from('project_stars')
        .select('project_id')
        .eq('user_id', userId!);
    
    return (response as List)
        .map((e) => e['project_id'] as String)
        .toSet();
  }

  /// Get project by ID with owner details
  static Future<Map<String, dynamic>?> getProjectById(String projectId) async {
    final response = await client
        .from('projects')
        .select('''
          *,
          profiles!projects_user_id_fkey (
            id,
            full_name,
            avatar_url,
            course,
            email
          )
        ''')
        .eq('id', projectId)
        .maybeSingle();
    
    return response;
  }

  /// Increment project view count
  static Future<void> incrementProjectViews(String projectId) async {
    await client.rpc('increment_project_views', params: {'project_id': projectId});
  }

  // ============ PROJECT COMMENTS ============

  /// Get comments for a project
  static Future<List<Map<String, dynamic>>> getProjectComments(String projectId) async {
    final response = await client
        .from('project_comments')
        .select('''
          *,
          profiles!project_comments_user_id_fkey (
            id,
            full_name,
            avatar_url
          )
        ''')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add comment to a project
  static Future<Map<String, dynamic>> addProjectComment({
    required String projectId,
    required String content,
  }) async {
    final response = await client
        .from('project_comments')
        .insert({
          'project_id': projectId,
          'user_id': userId,
          'content': content,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('''
          *,
          profiles!project_comments_user_id_fkey (
            id,
            full_name,
            avatar_url
          )
        ''')
        .single();
    
    // Notify the project owner
    try {
      final project = await client
          .from('projects')
          .select('user_id, name')
          .eq('id', projectId)
          .maybeSingle();
      
      if (project != null && project['user_id'] != userId) {
        final myProfile = await getProfile();
        final myName = myProfile?['full_name'] ?? 'Someone';
        final projectName = project['name'] ?? 'your project';
        final commentPreview = content.length > 50 ? '${content.substring(0, 50)}...' : content;
        
        await createNotification(
          targetUserId: project['user_id'],
          type: 'project_comment',
          title: 'New Comment',
          message: '$myName commented on "$projectName": "$commentPreview"',
          fromUserId: userId,
        );
      }
    } catch (e) {
      debugPrint('Error sending comment notification: $e');
    }
    
    return response;
  }

  /// Delete a comment
  static Future<void> deleteProjectComment(String commentId) async {
    await client
        .from('project_comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', userId!);
  }

  // ============ COLLABORATION REQUESTS ============

  /// Send a collaboration request
  static Future<void> sendCollaborationRequest({
    required String projectId,
    required String ownerId,
    required String message,
  }) async {
    await client.from('collaboration_requests').insert({
      'project_id': projectId,
      'requester_id': userId,
      'owner_id': ownerId,
      'message': message,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Notify project owner
    final profile = await getProfile();
    await createNotification(
      targetUserId: ownerId,
      type: 'collaboration_request',
      title: 'Collaboration Request',
      message: '${profile?['full_name'] ?? 'Someone'} wants to collaborate on your project',
      fromUserId: userId,
    );
  }

  /// Get collaboration requests for my projects
  static Future<List<Map<String, dynamic>>> getMyCollaborationRequests() async {
    if (userId == null) return [];
    
    final response = await client
        .from('collaboration_requests')
        .select('''
          *,
          profiles!collaboration_requests_requester_id_fkey (
            id,
            full_name,
            avatar_url,
            course
          ),
          projects!collaboration_requests_project_id_fkey (
            id,
            name
          )
        ''')
        .eq('owner_id', userId!)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get my sent collaboration requests
  static Future<List<Map<String, dynamic>>> getMySentCollaborationRequests() async {
    if (userId == null) return [];
    
    final response = await client
        .from('collaboration_requests')
        .select('''
          *,
          projects!collaboration_requests_project_id_fkey (
            id,
            name,
            profiles!projects_user_id_fkey (
              id,
              full_name,
              avatar_url
            )
          )
        ''')
        .eq('requester_id', userId!)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Accept collaboration request
  static Future<void> acceptCollaborationRequest(String requestId) async {
    final request = await client
        .from('collaboration_requests')
        .select('requester_id, project_id, projects(name)')
        .eq('id', requestId)
        .single();
    
    await client
        .from('collaboration_requests')
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId);
    
    // Notify the requester
    final projectName = request['projects']?['name'] ?? 'a project';
    await createNotification(
      targetUserId: request['requester_id'],
      type: 'collaboration_accepted',
      title: 'Request Accepted!',
      message: 'Your collaboration request for "$projectName" was accepted',
    );
  }

  /// Reject collaboration request
  static Future<void> rejectCollaborationRequest(String requestId) async {
    final request = await client
        .from('collaboration_requests')
        .select('requester_id, project_id, projects(name)')
        .eq('id', requestId)
        .single();
    
    await client
        .from('collaboration_requests')
        .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId);
    
    // Notify the requester
    final projectName = request['projects']?['name'] ?? 'a project';
    await createNotification(
      targetUserId: request['requester_id'],
      type: 'collaboration_rejected',
      title: 'Request Declined',
      message: 'Your collaboration request for "$projectName" was declined',
    );
  }

  /// Check if user already requested collaboration
  static Future<bool> hasRequestedCollaboration(String projectId) async {
    if (userId == null) return false;
    
    final response = await client
        .from('collaboration_requests')
        .select('id')
        .eq('project_id', projectId)
        .eq('requester_id', userId!)
        .inFilter('status', ['pending', 'accepted'])
        .maybeSingle();
    
    return response != null;
  }

  // NOTE: Connection methods (sendConnectionRequest, acceptConnectionRequest, 
  // rejectConnectionRequest, getPendingRequests, getConnections, etc.) 
  // are defined at the bottom of this file in the CONNECTIONS / FRIEND REQUESTS section.

  // ============ NOTIFICATIONS ============

  /// Create notification
  static Future<void> createNotification({
    required String targetUserId,
    required String type,
    required String title,
    required String message,
    String? fromUserId,
  }) async {
    try {
      await client.from('notifications').insert({
        'user_id': targetUserId,
        'type': type,
        'title': title,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        if (fromUserId != null) 'from_user_id': fromUserId,
      });
      debugPrint('Notification created for user $targetUserId: $title');
    } catch (e) {
      debugPrint('Error creating notification: $e');
      // Don't rethrow - notifications are non-critical
    }
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
  static Future<String?> uploadProfilePicture(Uint8List imageBytes, String fileName) async {
    if (userId == null) return null;
    
    try {
      // Clean filename and add timestamp to avoid conflicts
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final String filePath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';
      
      // Upload to Supabase Storage
      await client.storage
          .from('profiles')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
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
      rethrow;
    }
  }

  /// Upload cover photo
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadCoverPhoto(Uint8List imageBytes, String fileName) async {
    if (userId == null) return null;
    
    try {
      // Clean filename and add timestamp to avoid conflicts
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final String filePath = '$userId/covers/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';
      
      // Upload to Supabase Storage (in 'profiles' bucket under 'covers' folder)
      await client.storage
          .from('profiles')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get public URL
      final String publicUrl = client.storage
          .from('profiles')
          .getPublicUrl(filePath);
      
      // Update profile with new cover URL
      await updateProfile({'cover_photo_url': publicUrl});
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      rethrow;
    }
  }

  /// Upload project image
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadProjectImage(Uint8List imageBytes, String fileName, {String? projectId}) async {
    if (userId == null) return null;
    
    try {
      // Clean filename and add timestamp
      final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final String id = projectId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '$userId/$id/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';
      
      // Upload to Supabase Storage
      await client.storage
          .from('projects')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
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
      rethrow;
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

  // ============================================================================
  // POSTS / SOCIAL FEED
  // ============================================================================

  /// Get all posts for the feed
  static Future<List<Map<String, dynamic>>> getPosts({int limit = 50, int offset = 0}) async {
    try {
      final response = await client
          .from('posts')
          .select('''
            *,
            profiles:user_id (id, full_name, avatar_url, bio),
            reposter:reposter_id (id, full_name, avatar_url),
            original_post:original_post_id (
              id, user_id, title, content, images, likes_count, comments_count, reposts_count, created_at,
              profiles:user_id (id, full_name, avatar_url, bio)
            )
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      // Return empty list if table doesn't exist
      return [];
    }
  }

  /// Get posts by a specific user
  static Future<List<Map<String, dynamic>>> getUserPosts(String targetUserId, {int limit = 50}) async {
    try {
      final response = await client
          .from('posts')
          .select('''
            *,
            profiles:user_id (id, full_name, avatar_url, bio)
          ''')
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return [];
    }
  }

  /// Create a new post
  static Future<Map<String, dynamic>?> createPost({
    required String content,
    String? title,
    List<String> images = const [],
  }) async {
    if (userId == null) {
      debugPrint('Error creating post: User not logged in');
      return null;
    }

    try {
      debugPrint('Creating post for user: $userId');
      
      final response = await client.from('posts').insert({
        'user_id': userId,
        if (title != null && title.isNotEmpty) 'title': title,
        'content': content,
        'images': images,
        'likes_count': 0,
        'comments_count': 0,
        'reposts_count': 0,
        'is_repost': false,
        'is_quote_repost': false,
      }).select('''
        *,
        profiles:user_id (id, full_name, avatar_url, bio)
      ''').single();

      debugPrint('Post created successfully: ${response['id']}');
      
      // Notify connections about the new post
      await _notifyConnectionsAboutPost(response['id'], title ?? content.substring(0, content.length > 50 ? 50 : content.length));
      
      return response;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  /// Notify all connections when user creates a post
  static Future<void> _notifyConnectionsAboutPost(String postId, String postTitle) async {
    if (userId == null) return;
    
    try {
      // Get user's name
      final profile = await getProfile();
      final userName = profile?['full_name'] ?? 'Someone';
      
      // Get all connections
      final connections = await getConnections();
      
      // Create notification for each connection
      for (final connection in connections) {
        final friend = connection['friend'] as Map<String, dynamic>?;
        final friendId = friend?['id'] as String?;
        
        if (friendId != null) {
          await createNotification(
            targetUserId: friendId,
            type: 'new_post',
            title: 'New Post',
            message: '$userName posted "$postTitle"',
          );
        }
      }
    } catch (e) {
      debugPrint('Error notifying connections about post: $e');
    }
  }

  /// Repost a post (simple repost - shows "User reposted")
  static Future<Map<String, dynamic>?> repost(String originalPostId) async {
    if (userId == null) return null;

    try {
      // For a simple repost, the current user is the poster with a link to original
      // The original content is shown via original_post relationship
      final response = await client.from('posts').insert({
        'user_id': userId, // Current user is the reposter
        'content': '', // Content comes from original_post
        'original_post_id': originalPostId,
        'is_repost': true,
        'is_quote_repost': false,
        'images': [],
        'likes_count': 0,
        'comments_count': 0,
        'reposts_count': 0,
      }).select('''
        *,
        profiles:user_id (id, full_name, avatar_url, bio),
        original_post:original_post_id (
          id, user_id, title, content, images, likes_count, comments_count, reposts_count, created_at,
          profiles:user_id (id, full_name, avatar_url, bio)
        )
      ''').single();

      // Increment reposts count on original
      await client.rpc('increment_post_reposts', params: {'post_id': originalPostId});
      
      // Notify the original post owner
      try {
        final originalPost = await client
            .from('posts')
            .select('user_id, content')
            .eq('id', originalPostId)
            .maybeSingle();
        
        if (originalPost != null && originalPost['user_id'] != userId) {
          final myProfile = await getProfile();
          final myName = myProfile?['full_name'] ?? 'Someone';
          
          await createNotification(
            targetUserId: originalPost['user_id'],
            type: 'post_repost',
            title: 'New Repost',
            message: '$myName reposted your post',
            fromUserId: userId,
          );
        }
      } catch (e) {
        debugPrint('Error sending repost notification: $e');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error reposting: $e');
      return null;
    }
  }

  /// Quote repost (repost with your own comment)
  static Future<Map<String, dynamic>?> quoteRepost(String originalPostId, String quoteText) async {
    if (userId == null) return null;

    try {
      final response = await client.from('posts').insert({
        'user_id': userId,
        'original_post_id': originalPostId,
        'quote_text': quoteText,
        'content': quoteText,
        'is_repost': true,
        'is_quote_repost': true,
        'images': [],
        'likes_count': 0,
        'comments_count': 0,
        'reposts_count': 0,
      }).select('''
        *,
        profiles:user_id (id, full_name, avatar_url, bio),
        original_post:original_post_id (
          id, user_id, title, content, images, likes_count, comments_count, reposts_count, created_at,
          profiles:user_id (id, full_name, avatar_url, bio)
        )
      ''').single();

      // Increment reposts count on original
      await client.rpc('increment_post_reposts', params: {'post_id': originalPostId});
      
      // Notify the original post owner
      try {
        final originalPost = await client
            .from('posts')
            .select('user_id')
            .eq('id', originalPostId)
            .maybeSingle();
        
        if (originalPost != null && originalPost['user_id'] != userId) {
          final myProfile = await getProfile();
          final myName = myProfile?['full_name'] ?? 'Someone';
          final quotePreview = quoteText.length > 40 ? '${quoteText.substring(0, 40)}...' : quoteText;
          
          await createNotification(
            targetUserId: originalPost['user_id'],
            type: 'post_quote_repost',
            title: 'New Quote Repost',
            message: '$myName quoted your post: "$quotePreview"',
            fromUserId: userId,
          );
        }
      } catch (e) {
        debugPrint('Error sending quote repost notification: $e');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error quote reposting: $e');
      return null;
    }
  }

  /// Upload post image
  static Future<String?> uploadPostImage(dynamic imageBytes, String fileName) async {
    if (userId == null) return null;

    try {
      final path = 'posts/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await client.storage.from('post-images').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      final publicUrl = client.storage.from('post-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      return null;
    }
  }

  /// Update a post
  static Future<bool> updatePost({
    required String postId,
    String? title,
    String? content,
  }) async {
    if (userId == null) return false;

    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      
      await client
          .from('posts')
          .update(updates)
          .eq('id', postId)
          .eq('user_id', userId!);
      
      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }

  /// Delete a post
  static Future<bool> deletePost(String postId) async {
    try {
      await client.from('posts').delete().eq('id', postId).eq('user_id', userId ?? '');
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  /// Like a post
  static Future<bool> likePost(String postId) async {
    if (userId == null) return false;

    try {
      await client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      
      // Increment likes count
      await client.rpc('increment_post_likes', params: {'post_id': postId});
      
      // Notify the post owner
      try {
        final post = await client
            .from('posts')
            .select('user_id, content')
            .eq('id', postId)
            .maybeSingle();
        
        if (post != null && post['user_id'] != userId) {
          final myProfile = await getProfile();
          final myName = myProfile?['full_name'] ?? 'Someone';
          final postPreview = (post['content'] as String? ?? '').length > 30 
              ? '${(post['content'] as String).substring(0, 30)}...' 
              : post['content'] ?? 'your post';
          
          await createNotification(
            targetUserId: post['user_id'],
            type: 'post_like',
            title: 'New Like',
            message: '$myName liked your post: "$postPreview"',
            fromUserId: userId,
          );
        }
      } catch (e) {
        debugPrint('Error sending like notification: $e');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error liking post: $e');
      return false;
    }
  }

  /// Unlike a post
  static Future<bool> unlikePost(String postId) async {
    if (userId == null) return false;

    try {
      await client.from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId!);
      
      // Decrement likes count
      await client.rpc('decrement_post_likes', params: {'post_id': postId});
      return true;
    } catch (e) {
      debugPrint('Error unliking post: $e');
      return false;
    }
  }

  /// Batch get all liked post IDs for current user (fixes N+1 query)
  static Future<Set<String>> getLikedPostIds(List<String> postIds) async {
    if (userId == null || postIds.isEmpty) return {};

    try {
      final response = await client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId!)
          .inFilter('post_id', postIds);
      
      return (response as List)
          .map((row) => row['post_id'] as String)
          .toSet();
    } catch (e) {
      debugPrint('Error getting liked post IDs: $e');
      return {};
    }
  }

  /// Check if user liked a post
  static Future<bool> hasLikedPost(String postId) async {
    if (userId == null) return false;

    try {
      final response = await client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId!)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get comments for a post
  static Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final response = await client
          .from('post_comments')
          .select('''
            *,
            profiles:user_id (full_name, avatar_url)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  /// Add a comment to a post
  static Future<Map<String, dynamic>?> addPostComment({
    required String postId,
    required String content,
  }) async {
    if (userId == null) return null;

    try {
      final response = await client.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
      }).select('''
        *,
        profiles:user_id (full_name, avatar_url)
      ''').single();

      // Increment comments count
      await client.rpc('increment_post_comments', params: {'post_id': postId});
      
      // Notify the post owner
      try {
        final post = await client
            .from('posts')
            .select('user_id')
            .eq('id', postId)
            .maybeSingle();
        
        if (post != null && post['user_id'] != userId) {
          final myProfile = await getProfile();
          final myName = myProfile?['full_name'] ?? 'Someone';
          final commentPreview = content.length > 40 ? '${content.substring(0, 40)}...' : content;
          
          await createNotification(
            targetUserId: post['user_id'],
            type: 'post_comment',
            title: 'New Comment',
            message: '$myName commented on your post: "$commentPreview"',
            fromUserId: userId,
          );
        }
      } catch (e) {
        debugPrint('Error sending comment notification: $e');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  /// Repost a post
  static Future<Map<String, dynamic>?> repostPost(String originalPostId, {String? comment}) async {
    if (userId == null) return null;

    try {
      final response = await client.from('posts').insert({
        'user_id': userId,
        'content': comment ?? '',
        'original_post_id': originalPostId,
        'is_repost': true,
        'likes_count': 0,
        'comments_count': 0,
        'reposts_count': 0,
      }).select().single();

      // Increment reposts count on original
      await client.rpc('increment_post_reposts', params: {'post_id': originalPostId});
      
      // Notify the original post owner
      try {
        final originalPost = await client
            .from('posts')
            .select('user_id')
            .eq('id', originalPostId)
            .maybeSingle();
        
        if (originalPost != null && originalPost['user_id'] != userId) {
          final myProfile = await getProfile();
          final myName = myProfile?['full_name'] ?? 'Someone';
          
          await createNotification(
            targetUserId: originalPost['user_id'],
            type: 'post_repost',
            title: 'New Repost',
            message: comment != null && comment.isNotEmpty 
                ? '$myName reposted your post with a comment'
                : '$myName reposted your post',
            fromUserId: userId,
          );
        }
      } catch (e) {
        debugPrint('Error sending repost notification: $e');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error reposting: $e');
      return null;
    }
  }

  // ============================================================================
  // CONNECTIONS / FRIEND REQUESTS
  // ============================================================================

  /// Send a connection request
  static Future<bool> sendConnectionRequest(String receiverId, {String? message}) async {
    if (userId == null || userId == receiverId) return false;

    try {
      // Check if request already exists
      final existingRequest = await client
          .from('connection_requests')
          .select('id, status')
          .eq('sender_id', userId!)
          .eq('receiver_id', receiverId)
          .maybeSingle();
      
      if (existingRequest != null) {
        debugPrint('Connection request already exists with status: ${existingRequest['status']}');
        return existingRequest['status'] == 'pending';
      }
      
      await client.from('connection_requests').insert({
        'sender_id': userId,
        'receiver_id': receiverId,
        'status': 'pending',
        if (message != null) 'message': message,
      });
      
      debugPrint('Connection request inserted successfully');
      
      // Get sender's name for notification
      final senderProfile = await getProfile();
      final senderName = senderProfile?['full_name'] ?? 'Someone';
      
      // Create notification for the receiver
      await createNotification(
        targetUserId: receiverId,
        type: 'connection_request',
        title: 'New Connection Request',
        message: '$senderName wants to connect with you',
        fromUserId: userId,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error sending connection request: $e');
      return false;
    }
  }

  /// Accept a connection request
  static Future<bool> acceptConnectionRequest(String requestId) async {
    try {
      // First, get the request details for notification
      final request = await client
          .from('connection_requests')
          .select('sender_id')
          .eq('id', requestId)
          .single();
      
      final senderId = request['sender_id'] as String;
      
      // Use RPC function to handle both friendship creation and count update
      // This bypasses RLS to create bidirectional friendships
      await client.rpc('accept_connection_request', params: {'request_id': requestId});
      
      // Get accepter's name for notification
      final accepterProfile = await getProfile();
      final accepterName = accepterProfile?['full_name'] ?? 'Someone';
      
      // Notify the original sender that their request was accepted
      await createNotification(
        targetUserId: senderId,
        type: 'connection_accepted',
        title: 'Connection Accepted',
        message: '$accepterName accepted your connection request',
        fromUserId: userId,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error accepting connection: $e');
      return false;
    }
  }

  /// Reject a connection request
  static Future<bool> rejectConnectionRequest(String requestId) async {
    try {
      await client
          .from('connection_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId)
          .eq('receiver_id', userId ?? '');
      return true;
    } catch (e) {
      debugPrint('Error rejecting connection: $e');
      return false;
    }
  }

  /// Get pending connection requests (received)
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    if (userId == null) return [];

    try {
      final response = await client
          .from('connection_requests')
          .select('''
            *,
            sender_profile:profiles!sender_id(full_name, avatar_url, bio, course)
          ''')
          .eq('receiver_id', userId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      debugPrint('Pending requests response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching pending requests: $e');
      return [];
    }
  }

  /// Get sent connection requests
  static Future<List<Map<String, dynamic>>> getSentRequests() async {
    if (userId == null) return [];

    try {
      final response = await client
          .from('connection_requests')
          .select('''
            *,
            receiver_profile:profiles!receiver_id(full_name, avatar_url, bio)
          ''')
          .eq('sender_id', userId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching sent requests: $e');
      return [];
    }
  }

  /// Alias for getSentRequests (used by UserProfileViewScreen)
  static Future<List<Map<String, dynamic>>> getPendingConnectionRequests() async {
    return getSentRequests();
  }

  /// Check connection status between current user and another user
  static Future<String> getConnectionStatus(String otherUserId) async {
    if (userId == null) return 'none';

    try {
      // Check if already friends
      final friendship = await client
          .from('friendships')
          .select('id')
          .eq('user_id', userId!)
          .eq('friend_id', otherUserId)
          .maybeSingle();
      
      if (friendship != null) return 'connected';

      // Check for pending request sent by current user
      final sentRequest = await client
          .from('connection_requests')
          .select('id')
          .eq('sender_id', userId!)
          .eq('receiver_id', otherUserId)
          .eq('status', 'pending')
          .maybeSingle();
      
      if (sentRequest != null) return 'pending_sent';

      // Check for pending request received
      final receivedRequest = await client
          .from('connection_requests')
          .select('id')
          .eq('sender_id', otherUserId)
          .eq('receiver_id', userId!)
          .eq('status', 'pending')
          .maybeSingle();
      
      if (receivedRequest != null) return 'pending_received';

      return 'none';
    } catch (e) {
      debugPrint('Error checking connection status: $e');
      return 'none';
    }
  }

  /// Get friend suggestions (users not yet connected)
  static Future<List<Map<String, dynamic>>> getFriendSuggestions({int limit = 10}) async {
    if (userId == null) return [];

    try {
      // Get list of current friends
      final friendships = await client
          .from('friendships')
          .select('friend_id')
          .eq('user_id', userId!);
      
      final friendIds = (friendships as List).map((f) => f['friend_id'] as String).toList();
      friendIds.add(userId!); // Exclude self

      // Get pending request user IDs
      final pendingRequests = await client
          .from('connection_requests')
          .select('sender_id, receiver_id')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'pending');
      
      final pendingIds = <String>{};
      for (final req in pendingRequests as List) {
        pendingIds.add(req['sender_id'] as String);
        pendingIds.add(req['receiver_id'] as String);
      }

      // Get profiles excluding friends and pending
      final excludeIds = {...friendIds, ...pendingIds};
      
      final response = await client
          .from('profiles')
          .select()
          .not('id', 'in', '(${excludeIds.join(",")})')
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching friend suggestions: $e');
      // Fallback: just get other profiles
      return getAllProfiles();
    }
  }

  /// Get user's friends/connections
  static Future<List<Map<String, dynamic>>> getConnections() async {
    if (userId == null) return [];

    try {
      final response = await client
          .from('friendships')
          .select('''
            *,
            friend:friend_id (id, full_name, avatar_url, bio, course)
          ''')
          .eq('user_id', userId!)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching connections: $e');
      return [];
    }
  }

  /// Remove a connection/friend
  static Future<bool> removeConnection(String friendId) async {
    if (userId == null) return false;

    try {
      // Use RPC function to handle bidirectional deletion and count update
      await client.rpc('remove_connection', params: {'friend_id': friendId});
      return true;
    } catch (e) {
      debugPrint('Error removing connection: $e');
      return false;
    }
  }

  // ============================================================================
  // MESSAGING / CHAT
  // ============================================================================

  /// Get all conversations for current user
  static Future<List<Map<String, dynamic>>> getConversations() async {
    if (userId == null) return [];

    try {
      // Get conversations where user is participant
      final response = await client
          .from('conversations')
          .select('''
            id,
            participant1_id,
            participant2_id,
            created_at,
            updated_at
          ''')
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('updated_at', ascending: false);

      List<Map<String, dynamic>> conversations = [];
      
      for (final conv in response) {
        final otherUserId = conv['participant1_id'] == userId 
            ? conv['participant2_id'] 
            : conv['participant1_id'];
        
        // Get other user's profile
        final otherUserResponse = await client
            .from('profiles')
            .select('id, full_name, avatar_url, is_online')
            .eq('id', otherUserId)
            .maybeSingle();
        
        // Get last message
        final lastMessageResponse = await client
            .from('messages')
            .select('*')
            .eq('conversation_id', conv['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        // Get unread count
        final unreadResponse = await client
            .from('messages')
            .select('id')
            .eq('conversation_id', conv['id'])
            .eq('sender_id', otherUserId)
            .eq('is_read', false);
        
        conversations.add({
          ...conv,
          'other_user': otherUserResponse,
          'last_message': lastMessageResponse,
          'unread_count': (unreadResponse as List).length,
        });
      }
      
      // Sort by last message time
      conversations.sort((a, b) {
        final aTime = a['last_message']?['created_at'] ?? a['created_at'];
        final bTime = b['last_message']?['created_at'] ?? b['created_at'];
        return bTime.compareTo(aTime);
      });
      
      return conversations;
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get or create a conversation with another user
  static Future<String?> getOrCreateConversation(String otherUserId) async {
    if (userId == null) return null;

    try {
      // Check for existing conversation
      final existing = await client
          .from('conversations')
          .select('id')
          .or('and(participant1_id.eq.$userId,participant2_id.eq.$otherUserId),and(participant1_id.eq.$otherUserId,participant2_id.eq.$userId)')
          .maybeSingle();
      
      if (existing != null) {
        return existing['id'] as String;
      }
      
      // Create new conversation
      final newConv = await client
          .from('conversations')
          .insert({
            'participant1_id': userId,
            'participant2_id': otherUserId,
          })
          .select('id')
          .single();
      
      return newConv['id'] as String;
    } catch (e) {
      debugPrint('Error getting/creating conversation: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  static Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await client
          .from('messages')
          .select('''
            *,
            sender:sender_id (full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      
      return (response as List).map((msg) {
        final senderData = msg['sender'] as Map<String, dynamic>?;
        return Message(
          id: msg['id'],
          conversationId: msg['conversation_id'],
          senderId: msg['sender_id'],
          content: msg['content'] ?? '',
          messageType: msg['message_type'] ?? 'text',
          attachmentUrl: msg['attachment_url'],
          isRead: msg['is_read'] ?? false,
          isEdited: msg['is_edited'] ?? false,
          createdAt: DateTime.parse(msg['created_at']),
          updatedAt: msg['updated_at'] != null ? DateTime.parse(msg['updated_at']) : null,
          senderName: senderData?['full_name'],
          senderAvatar: senderData?['avatar_url'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Send a message
  static Future<Message?> sendMessage({
    required String conversationId,
    required String recipientId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    if (userId == null) return null;

    try {
      final response = await client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'message_type': messageType,
            'attachment_url': attachmentUrl,
            'is_read': false,
            'is_edited': false,
          })
          .select()
          .single();

      // Update conversation's updated_at
      await client
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
      
      // Create notification for recipient
      await createNotification(
        targetUserId: recipientId,
        type: 'message',
        title: 'New message',
        message: content.length > 50 ? '${content.substring(0, 50)}...' : content,
      );

      return Message(
        id: response['id'],
        conversationId: response['conversation_id'],
        senderId: response['sender_id'],
        content: response['content'],
        messageType: response['message_type'],
        attachmentUrl: response['attachment_url'],
        isRead: response['is_read'],
        isEdited: response['is_edited'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: response['updated_at'] != null ? DateTime.parse(response['updated_at']) : null,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String conversationId, String senderId) async {
    if (userId == null) return;

    try {
      await client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('sender_id', senderId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Get unread message count
  static Future<int> getUnreadMessageCount() async {
    if (userId == null) return 0;

    try {
      // Get all conversation IDs for current user
      final conversations = await client
          .from('conversations')
          .select('id')
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId');
      
      if ((conversations as List).isEmpty) return 0;
      
      final conversationIds = conversations.map((c) => c['id']).toList();
      
      // Count unread messages where sender is not current user
      final response = await client
          .from('messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .neq('sender_id', userId!)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // ============================================================================
  // GROUP CHAT
  // ============================================================================

  /// Create a group chat with multiple participants
  /// Returns the group conversation ID if successful
  static Future<String?> createGroupChat(String groupName, List<String> memberIds) async {
    if (userId == null) return null;
    
    try {
      // First, create a group_conversations entry
      final groupConv = await client
          .from('group_conversations')
          .insert({
            'name': groupName,
            'creator_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      
      final groupId = groupConv['id'] as String;
      
      // Add all members including the creator
      final allMembers = [userId!, ...memberIds];
      final participantInserts = allMembers.map((memberId) => {
        'group_id': groupId,
        'user_id': memberId,
        'joined_at': DateTime.now().toIso8601String(),
      }).toList();
      
      await client.from('group_participants').insert(participantInserts);
      
      return groupId;
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      // If the group tables don't exist yet, show a helpful message
      if (e.toString().contains('group_conversations') || 
          e.toString().contains('does not exist')) {
        throw Exception('Group chat feature requires database setup. Please run the group chat migration SQL.');
      }
      rethrow;
    }
  }

  /// Get group chat messages
  static Future<List<Message>> getGroupMessages(String groupId) async {
    try {
      final response = await client
          .from('group_messages')
          .select('''
            *,
            sender:sender_id (full_name, avatar_url)
          ''')
          .eq('group_id', groupId)
          .order('created_at', ascending: true);
      
      return (response as List).map((msg) {
        final senderData = msg['sender'] as Map<String, dynamic>?;
        return Message(
          id: msg['id'],
          conversationId: groupId,
          senderId: msg['sender_id'],
          content: msg['content'] ?? '',
          messageType: msg['message_type'] ?? 'text',
          attachmentUrl: msg['attachment_url'],
          isRead: false,
          isEdited: msg['is_edited'] ?? false,
          createdAt: DateTime.parse(msg['created_at']),
          updatedAt: msg['updated_at'] != null ? DateTime.parse(msg['updated_at']) : null,
          senderName: senderData?['full_name'],
          senderAvatar: senderData?['avatar_url'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching group messages: $e');
      return [];
    }
  }

  /// Send a message to a group chat
  static Future<Message?> sendGroupMessage({
    required String groupId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    if (userId == null) return null;
    
    try {
      final result = await client
          .from('group_messages')
          .insert({
            'group_id': groupId,
            'sender_id': userId,
            'content': content,
            'message_type': messageType,
            'attachment_url': attachmentUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            sender:sender_id (full_name, avatar_url)
          ''')
          .single();
      
      final senderData = result['sender'] as Map<String, dynamic>?;
      return Message(
        id: result['id'],
        conversationId: groupId,
        senderId: result['sender_id'],
        content: result['content'] ?? '',
        messageType: result['message_type'] ?? 'text',
        attachmentUrl: result['attachment_url'],
        isRead: false,
        isEdited: false,
        createdAt: DateTime.parse(result['created_at']),
        senderName: senderData?['full_name'],
        senderAvatar: senderData?['avatar_url'],
      );
    } catch (e) {
      debugPrint('Error sending group message: $e');
      return null;
    }
  }

  /// Get list of group chats for current user
  static Future<List<Map<String, dynamic>>> getGroupChats() async {
    if (userId == null) return [];
    
    try {
      // First get the group IDs the user is a participant in
      final participantRows = await client
          .from('group_participants')
          .select('group_id')
          .eq('user_id', userId!);
      
      if ((participantRows as List).isEmpty) return [];
      
      final groupIds = participantRows.map((p) => p['group_id']).toList();
      
      // Then fetch the group details
      final groups = await client
          .from('group_conversations')
          .select('*')
          .inFilter('id', groupIds)
          .order('last_message_at', ascending: false);
      
      return (groups as List).map((g) {
        return {
          'id': g['id'],
          'name': g['name'] ?? 'Unknown Group',
          'avatar_url': g['avatar_url'],
          'creator_id': g['creator_id'],
          'is_group': true,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching group chats: $e');
      return [];
    }
  }

  /// Get group details by ID
  static Future<Map<String, dynamic>?> getGroupDetails(String groupId) async {
    try {
      final response = await client
          .from('group_conversations')
          .select('*')
          .eq('id', groupId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching group details: $e');
      return null;
    }
  }

  /// Get group members with their profiles
  static Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final response = await client
          .from('group_participants')
          .select('''
            id,
            user_id,
            role,
            joined_at,
            profile:user_id (
              id,
              full_name,
              avatar_url,
              bio
            )
          ''')
          .eq('group_id', groupId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching group members: $e');
      return [];
    }
  }

  /// Check if current user is group admin
  static Future<bool> isGroupAdmin(String groupId) async {
    if (userId == null) return false;
    
    try {
      // Check if user is the creator
      final group = await client
          .from('group_conversations')
          .select('creator_id')
          .eq('id', groupId)
          .single();
      
      if (group['creator_id'] == userId) return true;
      
      // Check if user has admin role
      final participant = await client
          .from('group_participants')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', userId!)
          .maybeSingle();
      
      return participant?['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Update group info (name, avatar, description)
  static Future<void> updateGroupInfo(String groupId, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    
    await client
        .from('group_conversations')
        .update(data)
        .eq('id', groupId);
  }

  /// Delete a group (admin only)
  static Future<void> deleteGroup(String groupId) async {
    await client
        .from('group_conversations')
        .delete()
        .eq('id', groupId);
  }

  /// Remove member from group (admin only)
  static Future<void> removeGroupMember(String groupId, String memberId) async {
    await client
        .from('group_participants')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', memberId);
  }

  /// Update member role (admin only)
  static Future<void> updateMemberRole(String groupId, String memberId, String role) async {
    await client
        .from('group_participants')
        .update({'role': role})
        .eq('group_id', groupId)
        .eq('user_id', memberId);
  }

  /// Leave a group
  static Future<void> leaveGroup(String groupId) async {
    if (userId == null) return;
    
    await client
        .from('group_participants')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId!);
  }

  /// Add members to existing group (admin only)
  static Future<void> addGroupMembers(String groupId, List<String> memberIds) async {
    final inserts = memberIds.map((memberId) => {
      'group_id': groupId,
      'user_id': memberId,
      'role': 'member',
      'joined_at': DateTime.now().toIso8601String(),
    }).toList();
    
    await client.from('group_participants').insert(inserts);
  }
}
