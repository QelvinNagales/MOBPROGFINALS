import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

/// MessagesScreen - List of all conversations
/// Shows all chat conversations with connected users
class MessagesScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const MessagesScreen({super.key, this.scaffoldKey});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _groupChats = [];
  List<Map<String, dynamic>> _connections = [];
  bool _isLoading = true;
  RealtimeChannel? _messagesSubscription;
  RealtimeChannel? _connectionsSubscription;
  RealtimeChannel? _groupMessagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messagesSubscription?.unsubscribe();
    _connectionsSubscription?.unsubscribe();
    _groupMessagesSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final userId = SupabaseService.userId;
    if (userId == null) return;

    _messagesSubscription = SupabaseService.client
        .channel('messages_screen:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // Sound is handled by home_screen toast notification
            _loadConversations();
          },
        )
        .subscribe();

    // Subscribe to connection changes
    _connectionsSubscription = SupabaseService.client
        .channel('connections_screen:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'connections',
          callback: (payload) {
            _loadConnections();
          },
        )
        .subscribe();

    // Subscribe to group message changes
    _groupMessagesSubscription = SupabaseService.client
        .channel('group_messages_screen:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_messages',
          callback: (payload) {
            // Sound is handled by home_screen toast notification
            _loadGroupChats();
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadConversations(),
      _loadConnections(),
      _loadGroupChats(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await SupabaseService.getConversations();
      if (mounted) {
        setState(() => _conversations = conversations);
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  Future<void> _loadConnections() async {
    try {
      final connections = await SupabaseService.getConnections();
      if (mounted) {
        setState(() => _connections = connections);
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
    }
  }

  Future<void> _loadGroupChats() async {
    try {
      final groups = await SupabaseService.getGroupChats();
      if (mounted) {
        setState(() => _groupChats = groups);
      }
    } catch (e) {
      debugPrint('Error loading group chats: $e');
    }
  }

  // Combine DM conversations and group chats into a single list
  List<Map<String, dynamic>> get _allConversations {
    final all = <Map<String, dynamic>>[];
    
    // Add DM conversations
    for (final conv in _conversations) {
      all.add({...conv, 'is_group': false});
    }
    
    // Add group chats
    for (final group in _groupChats) {
      all.add({...group, 'is_group': true});
    }
    
    return all;
  }

  void _startNewConversation() async {
    // Refresh connections before showing modal
    await _loadConnections();
    
    if (!mounted) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'New Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    // Group chat button
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateGroupChat();
                      },
                      icon: Icon(
                        Icons.group_add_rounded,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                      label: Text(
                        'Group',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white54 : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _connections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: isDark ? Colors.white24 : AppColors.darkText.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No connections yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect with people to start chatting',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _connections.length,
                        itemBuilder: (context, index) {
                          final connection = _connections[index];
                          final friend = connection['friend'] as Map<String, dynamic>?;
                          if (friend == null) return const SizedBox.shrink();
                          
                          final name = friend['full_name'] ?? 'Unknown';
                          final avatar = friend['avatar_url'];
                          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                          
                          return ListTile(
                            leading: avatar != null && avatar.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(avatar),
                                  )
                                : CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.darkText,
                              ),
                            ),
                            subtitle: Text(
                              friend['bio'] ?? 'No bio',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _openChat(friend['id'], name, avatar);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateGroupChat() async {
    // Refresh connections to get latest list
    await _loadConnections();
    
    if (!mounted) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Set<String> selectedUserIds = {};
    final TextEditingController groupNameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? Colors.white70 : AppColors.darkText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Group Chat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                        ),
                        const Spacer(),
                        if (selectedUserIds.length >= 2)
                          TextButton(
                            onPressed: () {
                              if (groupNameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enter a group name'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              _createGroupChat(
                                groupNameController.text.trim(),
                                selectedUserIds.toList(),
                              );
                            },
                            child: Text(
                              'Create',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Group name field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: groupNameController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Group name',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.group_rounded,
                          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkBackground : AppColors.grey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Selected count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Select members (${selectedUserIds.length} selected)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Min 2 required',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Connection list with checkboxes
                  Expanded(
                    child: _connections.isEmpty
                        ? Center(
                            child: Text(
                              'No connections to add',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _connections.length,
                            itemBuilder: (context, index) {
                              final connection = _connections[index];
                              final friend = connection['friend'] as Map<String, dynamic>?;
                              if (friend == null) return const SizedBox.shrink();
                              
                              final userId = friend['id'] as String;
                              final name = friend['full_name'] ?? 'Unknown';
                              final avatar = friend['avatar_url'];
                              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                              final isSelected = selectedUserIds.contains(userId);
                              
                              return ListTile(
                                leading: Stack(
                                  children: [
                                    avatar != null && avatar.isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(avatar),
                                          )
                                        : CircleAvatar(
                                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                    if (isSelected)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? AppColors.darkCard : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            size: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.darkText,
                                  ),
                                ),
                                subtitle: Text(
                                  friend['bio'] ?? 'No bio',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        selectedUserIds.add(userId);
                                      } else {
                                        selectedUserIds.remove(userId);
                                      }
                                    });
                                  },
                                  activeColor: AppColors.primaryBlue,
                                  checkColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selectedUserIds.remove(userId);
                                    } else {
                                      selectedUserIds.add(userId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createGroupChat(String groupName, List<String> memberIds) async {
    try {
      // Create group chat
      final groupId = await SupabaseService.createGroupChat(groupName, memberIds);
      
      if (groupId != null && mounted) {
        // Refresh group chats list
        await _loadGroupChats();
        
        // Open the group chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              recipientId: groupId,
              recipientName: groupName,
              recipientAvatar: null,
              conversationId: groupId,
              isGroupChat: true,
            ),
          ),
        ).then((_) => _loadGroupChats());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$groupName" created!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _openChat(String recipientId, String recipientName, String? recipientAvatar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipientId: recipientId,
          recipientName: recipientName,
          recipientAvatar: recipientAvatar,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _startNewConversation,
            icon: Icon(
              Icons.edit_square,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primaryBlue,
              child: _allConversations.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildConversationList(isDark),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your connections',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewConversation,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('New Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _allConversations.length,
      itemBuilder: (context, index) {
        final conv = _allConversations[index];
        return _buildConversationItem(conv, isDark);
      },
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conv, bool isDark) {
    final isGroup = conv['is_group'] == true;
    
    if (isGroup) {
      return _buildGroupChatItem(conv, isDark);
    } else {
      return _buildDMConversationItem(conv, isDark);
    }
  }

  Widget _buildGroupChatItem(Map<String, dynamic> conv, bool isDark) {
    final name = conv['name'] ?? 'Unknown Group';
    final avatar = conv['avatar_url'];
    final groupId = conv['id'] ?? '';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            recipientId: groupId,
            recipientName: name,
            recipientAvatar: avatar,
            conversationId: groupId,
            isGroupChat: true,
          ),
        ),
      ).then((_) => _loadGroupChats()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Group Avatar
            Stack(
              children: [
                avatar != null && avatar.isNotEmpty
                    ? CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(avatar),
                      )
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.group_rounded,
                          color: AppColors.primaryBlue,
                          size: 28,
                        ),
                      ),
                // Group badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBackground : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Group conversation',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDMConversationItem(Map<String, dynamic> conv, bool isDark) {
    final otherUser = conv['other_user'] as Map<String, dynamic>?;
    final lastMessage = conv['last_message'] as Map<String, dynamic>?;
    final unreadCount = conv['unread_count'] as int? ?? 0;
    
    final name = otherUser?['full_name'] ?? 'Unknown User';
    final avatar = otherUser?['avatar_url'];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final lastMessageContent = lastMessage?['content'] ?? 'No messages yet';
    final lastMessageTime = lastMessage?['created_at'] != null
        ? _formatTime(DateTime.parse(lastMessage!['created_at']))
        : '';
    final isLastMessageMine = lastMessage?['sender_id'] == SupabaseService.userId;

    return InkWell(
      onTap: () => _openChat(
        otherUser?['id'] ?? '',
        name,
        avatar,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                avatar != null && avatar.isNotEmpty
                    ? CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(avatar),
                      )
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                if (otherUser?['is_online'] == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Message info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        lastMessageTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? AppColors.primaryBlue
                              : (isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isLastMessageMine)
                        Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: lastMessage?['is_read'] == true
                              ? AppColors.primaryBlue
                              : (isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4)),
                        ),
                      if (isLastMessageMine) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lastMessageContent,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: unreadCount > 0
                                ? (isDark ? Colors.white : AppColors.darkText)
                                : (isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
