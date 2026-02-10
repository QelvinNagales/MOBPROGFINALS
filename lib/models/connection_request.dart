/// Connection Request model for friend/connection system
/// Represents a pending connection request between users
enum ConnectionStatus {
  pending,
  accepted,
  rejected,
}

class ConnectionRequest {
  final String? id;
  final String senderId;
  final String receiverId;
  final ConnectionStatus status;
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Sender info (populated from join)
  final String? senderName;
  final String? senderAvatar;
  final String? senderBio;
  final String? senderCourse;

  // Receiver info (populated from join)
  final String? receiverName;
  final String? receiverAvatar;

  ConnectionRequest({
    this.id,
    required this.senderId,
    required this.receiverId,
    this.status = ConnectionStatus.pending,
    this.message,
    this.createdAt,
    this.updatedAt,
    this.senderName,
    this.senderAvatar,
    this.senderBio,
    this.senderCourse,
    this.receiverName,
    this.receiverAvatar,
  });

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) {
    final senderProfile = json['sender_profile'] as Map<String, dynamic>?;
    final receiverProfile = json['receiver_profile'] as Map<String, dynamic>?;

    return ConnectionRequest(
      id: json['id'] as String?,
      senderId: json['sender_id'] as String? ?? '',
      receiverId: json['receiver_id'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      senderName: senderProfile?['full_name'] as String?,
      senderAvatar: senderProfile?['avatar_url'] as String?,
      senderBio: senderProfile?['bio'] as String?,
      senderCourse: senderProfile?['course'] as String?,
      receiverName: receiverProfile?['full_name'] as String?,
      receiverAvatar: receiverProfile?['avatar_url'] as String?,
    );
  }

  static ConnectionStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return ConnectionStatus.accepted;
      case 'rejected':
        return ConnectionStatus.rejected;
      default:
        return ConnectionStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': status.name,
      if (message != null) 'message': message,
    };
  }
}
