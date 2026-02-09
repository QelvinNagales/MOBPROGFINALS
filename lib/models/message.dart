/// Message model for direct messaging between users
class Message {
  final String? id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType; // 'text', 'image', 'file', 'link'
  final String? attachmentUrl;
  final bool isRead;
  final bool isEdited;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Sender profile info (populated from join)
  final String? senderName;
  final String? senderAvatar;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    this.attachmentUrl,
    this.isRead = false,
    this.isEdited = false,
    this.createdAt,
    this.updatedAt,
    this.senderName,
    this.senderAvatar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    
    return Message(
      id: json['id'] as String?,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      attachmentUrl: json['attachment_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      senderName: sender?['full_name'] as String?,
      senderAvatar: sender?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'is_read': isRead,
      'is_edited': isEdited,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? messageType,
    String? attachmentUrl,
    bool? isRead,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderName,
    String? senderAvatar,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }

  /// Format timestamp for display
  String get formattedTime {
    if (createdAt == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    }
  }

  @override
  String toString() => 'Message(id: $id, content: $content)';
}

/// Conversation model representing a chat between two users
class Conversation {
  final String? id;
  final String participant1;
  final String participant2;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  
  // Participant profiles (populated from join)
  final ConversationParticipant? participant1Profile;
  final ConversationParticipant? participant2Profile;
  
  // Last message preview
  final Message? lastMessage;
  final int unreadCount;

  Conversation({
    this.id,
    required this.participant1,
    required this.participant2,
    this.lastMessageAt,
    this.createdAt,
    this.participant1Profile,
    this.participant2Profile,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String?,
      participant1: json['participant_1'] as String,
      participant2: json['participant_2'] as String,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      participant1Profile: json['participant_1_profile'] != null
          ? ConversationParticipant.fromJson(json['participant_1_profile'])
          : null,
      participant2Profile: json['participant_2_profile'] != null
          ? ConversationParticipant.fromJson(json['participant_2_profile'])
          : null,
    );
  }

  /// Get the other participant's profile based on current user
  ConversationParticipant? getOtherParticipant(String currentUserId) {
    if (participant1 == currentUserId) {
      return participant2Profile;
    } else {
      return participant1Profile;
    }
  }

  /// Get display name for the conversation
  String getDisplayName(String currentUserId) {
    final other = getOtherParticipant(currentUserId);
    return other?.fullName ?? 'Unknown User';
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'participant_1': participant1,
      'participant_2': participant2,
    };
  }
}

/// Simplified participant info for conversations
class ConversationParticipant {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  ConversationParticipant({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }

  /// Get status text
  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }
}
