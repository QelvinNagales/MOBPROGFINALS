import 'dart:async';
import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../models/connection_request.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import 'user_profile_view_screen.dart';

/// Network Screen (Friends)
/// Find and connect with other students, manage connection requests.
class FriendsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const FriendsScreen({super.key, this.scaffoldKey});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Data
  List<Profile> _searchResults = [];
  List<Profile> _suggestions = [];
  List<ConnectionRequest> _pendingRequests = [];
  List<Map<String, dynamic>> _connections = [];

  // State
  bool _isSearching = false;
  bool _isLoadingSuggestions = true;
  bool _isLoadingRequests = true;
  bool _isLoadingConnections = true;
  String _searchQuery = '';
  final Set<String> _pendingSentRequests = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSuggestions(),
      _loadPendingRequests(),
      _loadConnections(),
    ]);
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoadingSuggestions = true);
    
    try {
      final data = await SupabaseService.getFriendSuggestions(limit: 20);
      if (mounted) {
        setState(() {
          _suggestions = data.map((p) => Profile.fromJson(p)).toList();
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    
    try {
      final data = await SupabaseService.getPendingRequests();
      if (mounted) {
        setState(() {
          _pendingRequests = data.map((r) => ConnectionRequest.fromJson(r)).toList();
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoadingConnections = true);
    
    try {
      final data = await SupabaseService.getConnections();
      if (mounted) {
        setState(() {
          _connections = data;
          _isLoadingConnections = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingConnections = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }
    
    setState(() => _searchQuery = query);
    
    // Debounce search by 400ms
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchPeople(query);
    });
  }

  Future<void> _searchPeople(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await SupabaseService.searchProfiles(query);
      if (mounted) {
        setState(() {
          _searchResults = results.map((p) => Profile.fromJson(p)).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendConnectionRequest(Profile profile) async {
    if (profile.id == null) return;

    setState(() => _pendingSentRequests.add(profile.id!));

    try {
      final success = await SupabaseService.sendConnectionRequest(profile.id!);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${profile.fullName}!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Remove from suggestions
        setState(() {
          _suggestions.removeWhere((s) => s.id == profile.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pendingSentRequests.remove(profile.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptRequest(ConnectionRequest request) async {
    if (request.id == null) return;

    try {
      final success = await SupabaseService.acceptConnectionRequest(request.id!);
      
      if (success && mounted) {
        // Show LinkedIn-style notification
        _showConnectionAcceptedNotification(request.senderName ?? 'User');
        
        // Reload data
        await Future.wait([
          _loadPendingRequests(),
          _loadConnections(),
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectRequest(ConnectionRequest request) async {
    if (request.id == null) return;

    try {
      await SupabaseService.rejectConnectionRequest(request.id!);
      await _loadPendingRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showConnectionAcceptedNotification(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'You\'re now connected!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You and $name are now connected. Start a conversation!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : AppColors.cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Maybe later',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to messages
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Say Hi!'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: Text(
          'Network',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
            indicatorColor: AppColors.primaryBlue,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('Discover'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('Requests${_pendingRequests.isNotEmpty ? ' (${_pendingRequests.length})' : ''}'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('Connections'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTab(isDark),
          _buildRequestsTab(isDark),
          _buildConnectionsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(bool isDark) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
              decoration: InputDecoration(
                hintText: 'Search for students by name, email, or skills...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),

        // Results or Suggestions
        Expanded(
          child: _searchQuery.isNotEmpty
              ? _buildSearchResults(isDark)
              : _buildSuggestions(isDark),
        ),
      ],
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: isDark ? Colors.white24 : AppColors.darkText.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildPersonCard(_searchResults[index], isDark);
      },
    );
  }

  Widget _buildSuggestions(bool isDark) {
    if (_isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: isDark ? Colors.white24 : AppColors.darkText.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      color: AppColors.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Text(
            'People you may know',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          ..._suggestions.map((profile) => _buildPersonCard(profile, isDark)),
        ],
      ),
    );
  }

  Widget _buildPersonCard(Profile profile, bool isDark) {
    final displayName = profile.fullName.isNotEmpty ? profile.fullName : 'Unknown User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final isPending = _pendingSentRequests.contains(profile.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(
              userId: profile.id!,
              userName: displayName,
              userAvatar: profile.avatarUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Avatar
            profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      profile.avatarUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatar(initial, isDark),
                    ),
                  )
                : _buildAvatar(initial, isDark),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  if (profile.course != null && profile.course!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.course!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Connect button
            ElevatedButton(
              onPressed: isPending ? null : () => _sendConnectionRequest(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending
                    ? (isDark ? Colors.white12 : AppColors.cardBorder)
                    : AppColors.primaryBlue,
                foregroundColor: isPending
                    ? (isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5))
                    : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPending ? Icons.schedule_rounded : Icons.person_add_rounded,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPending ? 'Pending' : 'Connect',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(bool isDark) {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 56,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No pending requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone sends you a connection\nrequest, it will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(_pendingRequests[index], isDark);
        },
      ),
    );
  }

  Widget _buildRequestCard(ConnectionRequest request, bool isDark) {
    final name = request.senderName ?? 'Unknown User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(
              userId: request.senderId,
              userName: name,
              userAvatar: request.senderAvatar,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                request.senderAvatar != null && request.senderAvatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          request.senderAvatar!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatar(initial, isDark),
                        ),
                      )
                    : _buildAvatar(initial, isDark),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      if (request.senderCourse != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          request.senderCourse!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      if (request.senderBio != null && request.senderBio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          request.senderBio!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectRequest(request),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : AppColors.cardBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Ignore',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsTab(bool isDark) {
    if (_isLoadingConnections) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (_connections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No connections yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start connecting with other students\nto grow your network',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Find People',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConnections,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _connections.length,
        itemBuilder: (context, index) {
          return _buildConnectionCard(_connections[index], isDark);
        },
      ),
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> connection, bool isDark) {
    final friend = connection['friend'] as Map<String, dynamic>?;
    if (friend == null) return const SizedBox.shrink();

    final friendId = friend['id'] as String?;
    final name = friend['full_name'] as String? ?? 'Unknown User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = friend['avatar_url'] as String?;
    final bio = friend['bio'] as String?;
    final course = friend['course'] as String?;

    return GestureDetector(
      onTap: () {
        if (friendId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileViewScreen(
                userId: friendId,
                userName: name,
                userAvatar: avatarUrl,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Avatar
            avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      avatarUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatar(initial, isDark),
                    ),
                  )
                : _buildAvatar(initial, isDark),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.darkText,
                    ),
                  ),
                  if (course != null && course.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      course,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Message button
            IconButton(
              onPressed: () {
                // TODO: Open chat
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial, bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.primaryBlue : AppColors.darkText,
          ),
        ),
      ),
    );
  }
}
