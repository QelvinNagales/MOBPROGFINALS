import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';
import 'user_profile_view_screen.dart';

/// ChatScreen - Individual conversation with a user or group
/// Shows messages and allows sending new messages
class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final String? conversationId;
  final bool isGroupChat;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatar,
    this.conversationId,
    this.isGroupChat = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAdmin = false;
  RealtimeChannel? _messagesSubscription;
  Map<String, dynamic>? _recipientProfile;
  Map<String, dynamic>? _groupDetails;
  String _groupName = '';

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _groupName = widget.recipientName;
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messagesSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    if (widget.isGroupChat) {
      // For group chats, use the recipientId as the group ID
      _conversationId = widget.recipientId;
      
      // Load group details and check admin status
      _groupDetails = await SupabaseService.getGroupDetails(widget.recipientId);
      _isAdmin = await SupabaseService.isGroupAdmin(widget.recipientId);
      if (_groupDetails != null) {
        _groupName = _groupDetails!['name'] ?? widget.recipientName;
      }
      
      await _loadMessages();
      _setupRealtimeSubscription();
    } else {
      // Load recipient profile for DMs
      try {
        _recipientProfile = await SupabaseService.getProfileById(widget.recipientId);
      } catch (e) {
        debugPrint('Error loading recipient profile: $e');
      }
      
      // Get or create conversation
      if (_conversationId == null) {
        _conversationId = await SupabaseService.getOrCreateConversation(widget.recipientId);
      }
      
      if (_conversationId != null) {
        await _loadMessages();
        _setupRealtimeSubscription();
        _markMessagesAsRead();
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    
    try {
      final messages = widget.isGroupChat
          ? await SupabaseService.getGroupMessages(_conversationId!)
          : await SupabaseService.getMessages(_conversationId!);
      if (mounted) {
        setState(() => _messages = messages);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void _setupRealtimeSubscription() {
    if (_conversationId == null) return;

    final tableName = widget.isGroupChat ? 'group_messages' : 'messages';

    // Remove existing subscription first
    _messagesSubscription?.unsubscribe();

    // Use a simpler subscription without filter - filter client-side
    _messagesSubscription = SupabaseService.client
        .channel('chat:${tableName}_$_conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            debugPrint('Realtime: New message in $tableName');
            final newRecord = payload.newRecord;
            final targetId = widget.isGroupChat ? newRecord['group_id'] : newRecord['conversation_id'];
            
            // Only reload if the message is for this conversation
            if (targetId == _conversationId && mounted) {
              // Sound notification is handled by home_screen globally
              _loadMessages();
            }
          },
        )
        .subscribe((status, error) {
          debugPrint('Realtime status: $status');
          if (error != null) debugPrint('Realtime error: $error');
        });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    if (_conversationId == null) return;
    await SupabaseService.markMessagesAsRead(_conversationId!, widget.recipientId);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      if (widget.isGroupChat) {
        // Send group message
        final message = await SupabaseService.sendGroupMessage(
          groupId: widget.recipientId,
          content: content,
        );
        
        if (message != null && mounted) {
          setState(() {
            if (!_messages.any((m) => m.id == message.id)) {
              _messages.add(message);
            }
          });
          _scrollToBottom();
        }
      } else {
        // DM logic
        _conversationId ??= await SupabaseService.getOrCreateConversation(widget.recipientId);
        
        if (_conversationId != null) {
          final message = await SupabaseService.sendMessage(
            conversationId: _conversationId!,
            recipientId: widget.recipientId,
            content: content,
          );
          
          if (message != null && mounted) {
            setState(() {
              if (!_messages.any((m) => m.id == message.id)) {
                _messages.add(message);
              }
            });
            _scrollToBottom();
          }
          
          if (_messagesSubscription == null) {
            _setupRealtimeSubscription();
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _viewProfile() {
    if (widget.isGroupChat) {
      // Show group info dialog for group chats
      _showGroupInfo();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileViewScreen(userId: widget.recipientId),
        ),
      );
    }
  }

  void _showGroupInfo() {
    _showGroupSettings();
  }

  void _showGroupSettings() {
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
                    widget.recipientAvatar != null && widget.recipientAvatar!.isNotEmpty
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(widget.recipientAvatar!),
                          )
                        : CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.group_rounded,
                              color: AppColors.primaryBlue,
                              size: 32,
                            ),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _groupName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _isAdmin ? Icons.admin_panel_settings : Icons.person,
                                size: 14,
                                color: _isAdmin ? AppColors.warning : (isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAdmin ? 'Admin' : 'Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isAdmin ? AppColors.warning : (isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // View Members
                    _buildSettingsItem(
                      icon: Icons.people_rounded,
                      title: 'View Members',
                      subtitle: 'See who\'s in this group',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        _showGroupMembers();
                      },
                    ),
                    
                    // Edit Group (Admin only)
                    if (_isAdmin)
                      _buildSettingsItem(
                        icon: Icons.edit_rounded,
                        title: 'Edit Group',
                        subtitle: 'Change name and photo',
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          _showEditGroupDialog();
                        },
                      ),
                    
                    // Add Members (Admin only)
                    if (_isAdmin)
                      _buildSettingsItem(
                        icon: Icons.person_add_rounded,
                        title: 'Add Members',
                        subtitle: 'Invite connections to this group',
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          _showAddMembersDialog();
                        },
                      ),
                    
                    const Divider(height: 24),
                    
                    // Leave Group
                    _buildSettingsItem(
                      icon: Icons.exit_to_app_rounded,
                      title: 'Leave Group',
                      subtitle: 'You will no longer see this group',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _confirmLeaveGroup();
                      },
                    ),
                    
                    // Delete Group (Admin only)
                    if (_isAdmin)
                      _buildSettingsItem(
                        icon: Icons.delete_rounded,
                        title: 'Delete Group',
                        subtitle: 'This will remove the group for everyone',
                        isDark: isDark,
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeleteGroup();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : (isDark ? Colors.white : AppColors.darkText);
    final iconColor = isDestructive ? Colors.red : AppColors.primaryBlue;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.5),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showGroupMembers() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = await SupabaseService.getGroupMembers(widget.recipientId);
    final creatorId = _groupDetails?['creator_id'];
    
    if (!mounted) return;
    
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.darkText),
                    ),
                    Text(
                      'Members (${members.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final profile = member['profile'] as Map<String, dynamic>?;
                    final memberId = member['user_id'];
                    final memberRole = member['role'] ?? 'member';
                    final isCreator = memberId == creatorId;
                    final isMemberAdmin = memberRole == 'admin' || isCreator;
                    final isCurrentUser = memberId == SupabaseService.userId;
                    
                    final name = profile?['full_name'] ?? 'Unknown';
                    final avatar = profile?['avatar_url'];
                    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                    
                    return ListTile(
                      leading: avatar != null && avatar.isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(avatar))
                          : CircleAvatar(
                              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                              child: Text(initial, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                            ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isCurrentUser ? '$name (You)' : name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.darkText,
                              ),
                            ),
                          ),
                          if (isCreator)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Creator',
                                style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600),
                              ),
                            )
                          else if (isMemberAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        profile?['bio'] ?? 'No bio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
                      ),
                      trailing: _isAdmin && !isCurrentUser && !isCreator
                          ? PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
                              color: isDark ? AppColors.darkCard : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) async {
                                if (value == 'make_admin') {
                                  await SupabaseService.updateMemberRole(widget.recipientId, memberId, 'admin');
                                  Navigator.pop(context);
                                  _showGroupMembers();
                                } else if (value == 'remove_admin') {
                                  await SupabaseService.updateMemberRole(widget.recipientId, memberId, 'member');
                                  Navigator.pop(context);
                                  _showGroupMembers();
                                } else if (value == 'kick') {
                                  await SupabaseService.removeGroupMember(widget.recipientId, memberId);
                                  Navigator.pop(context);
                                  _showGroupMembers();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$name has been removed'), behavior: SnackBarBehavior.floating),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                if (!isMemberAdmin)
                                  PopupMenuItem(
                                    value: 'make_admin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.admin_panel_settings, size: 20, color: AppColors.primaryBlue),
                                        const SizedBox(width: 8),
                                        Text('Make Admin', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                                      ],
                                    ),
                                  ),
                                if (isMemberAdmin && !isCreator)
                                  PopupMenuItem(
                                    value: 'remove_admin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.remove_moderator, size: 20, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Text('Remove Admin', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                                      ],
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'kick',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_remove, size: 20, color: Colors.red),
                                      const SizedBox(width: 8),
                                      const Text('Remove from Group', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : null,
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

  void _showEditGroupDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: _groupName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Group',
          style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.grey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != _groupName) {
                await SupabaseService.updateGroupInfo(widget.recipientId, {'name': newName});
                setState(() => _groupName = newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group name updated'), behavior: SnackBarBehavior.floating),
                );
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connections = await SupabaseService.getConnections();
    final currentMembers = await SupabaseService.getGroupMembers(widget.recipientId);
    final currentMemberIds = currentMembers.map((m) => m['user_id'] as String).toSet();
    
    // Filter out existing members
    final availableConnections = connections.where((c) {
      final friend = c['friend'] as Map<String, dynamic>?;
      return friend != null && !currentMemberIds.contains(friend['id']);
    }).toList();
    
    if (!mounted) return;
    
    if (availableConnections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All your connections are already in this group'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    final Set<String> selectedIds = {};
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: isDark ? Colors.white : AppColors.darkText),
                        ),
                        Expanded(
                          child: Text(
                            'Add Members',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.darkText,
                            ),
                          ),
                        ),
                        if (selectedIds.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await SupabaseService.addGroupMembers(widget.recipientId, selectedIds.toList());
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${selectedIds.length} member(s) added'), behavior: SnackBarBehavior.floating),
                              );
                            },
                            child: Text(
                              'Add (${selectedIds.length})',
                              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: availableConnections.length,
                      itemBuilder: (context, index) {
                        final connection = availableConnections[index];
                        final friend = connection['friend'] as Map<String, dynamic>;
                        final friendId = friend['id'] as String;
                        final name = friend['full_name'] ?? 'Unknown';
                        final avatar = friend['avatar_url'];
                        final isSelected = selectedIds.contains(friendId);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setSheetState(() {
                              if (value == true) {
                                selectedIds.add(friendId);
                              } else {
                                selectedIds.remove(friendId);
                              }
                            });
                          },
                          secondary: avatar != null && avatar.isNotEmpty
                              ? CircleAvatar(backgroundImage: NetworkImage(avatar))
                              : CircleAvatar(
                                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                                  child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue)),
                                ),
                          title: Text(name, style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                          activeColor: AppColors.primaryBlue,
                          checkColor: Colors.white,
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

  void _confirmLeaveGroup() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Leave Group', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
        content: Text(
          'Are you sure you want to leave "$_groupName"? You will no longer see messages from this group.',
          style: TextStyle(color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.leaveGroup(widget.recipientId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close chat
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('You left the group'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Group', style: TextStyle(color: Colors.red)),
        content: Text(
          'Are you sure you want to delete "$_groupName"? This will remove the group and all messages for everyone. This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.deleteGroup(widget.recipientId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close chat
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Group deleted'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = SupabaseService.userId;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _messages.isEmpty
                    ? _buildEmptyChat(isDark)
                    : _buildMessageList(isDark, currentUserId),
          ),
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final displayName = widget.isGroupChat ? _groupName : widget.recipientName;
    final initial = displayName.isNotEmpty 
        ? displayName[0].toUpperCase() 
        : '?';

    return AppBar(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppColors.darkText,
        ),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: _viewProfile,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              widget.recipientAvatar != null && widget.recipientAvatar!.isNotEmpty
                  ? CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.recipientAvatar!),
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                      child: widget.isGroupChat
                          ? Icon(Icons.group_rounded, color: AppColors.primaryBlue, size: 20)
                          : Text(
                              initial,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
              const SizedBox(width: 12),
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
                    if (widget.isGroupChat)
                      Text(
                        'Tap for group info',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
                        ),
                      )
                    else if (_recipientProfile?['is_online'] == true)
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
          color: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'profile') {
              _viewProfile();
            } else if (value == 'group_settings') {
              _showGroupSettings();
            } else if (value == 'members') {
              _showGroupMembers();
            } else if (value == 'leave') {
              _confirmLeaveGroup();
            } else if (value == 'delete') {
              _confirmDeleteGroup();
            }
          },
          itemBuilder: (context) => widget.isGroupChat
              ? [
                  PopupMenuItem(
                    value: 'group_settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          size: 20,
                          color: isDark ? Colors.white70 : AppColors.darkText,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Group Settings',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'members',
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 20,
                          color: isDark ? Colors.white70 : AppColors.darkText,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'View Members',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.exit_to_app_rounded,
                          size: 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Leave Group',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  if (_isAdmin)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Delete Group',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                ]
              : [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: isDark ? Colors.white70 : AppColors.darkText,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'View Profile',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
        ),
      ],
    );
  }

  Widget _buildEmptyChat(bool isDark) {
    final displayName = widget.isGroupChat ? _groupName : widget.recipientName;
    final initial = displayName.isNotEmpty 
        ? displayName[0].toUpperCase() 
        : '?';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.recipientAvatar != null && widget.recipientAvatar!.isNotEmpty
              ? CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(widget.recipientAvatar!),
                )
              : CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                  child: widget.isGroupChat
                      ? Icon(Icons.group_rounded, color: AppColors.primaryBlue, size: 48)
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 36,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isGroupChat
                ? 'Send a message to start the group conversation!'
                : 'Say hello to start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark, String? currentUserId) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == currentUserId;
        final messageTime = message.createdAt ?? DateTime.now();
        final prevMessageTime = index > 0 ? _messages[index - 1].createdAt ?? DateTime.now() : null;
        final showDate = index == 0 || (prevMessageTime != null && !_isSameDay(prevMessageTime, messageTime));
        
        return Column(
          children: [
            if (showDate) _buildDateHeader(messageTime, isDark),
            _buildMessageBubble(message, isMe, isDark),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark) {
    final now = DateTime.now();
    String label;
    
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = '${_monthName(date.month)} ${date.day}, ${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryBlue
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.darkText),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.createdAt ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : (isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4)),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.isRead ? Colors.white : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkBackground 
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkText,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: isDark 
                        ? Colors.white38 
                        : AppColors.darkText.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
