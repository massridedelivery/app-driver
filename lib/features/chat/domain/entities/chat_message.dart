/// Domain entity representing a single chat message between driver and customer.
class ChatMessage {
  final String id;
  final String jobId;
  final String senderId;
  final String senderType; // 'driver' or 'customer'
  final String content;
  final String msgType; // 'text' or 'image'
  final String mediaUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.msgType,
    required this.mediaUrl,
    required this.createdAt,
  });

  /// Check if the sender of this message is the driver.
  bool get isDriver => senderType == 'driver';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? json['room_id']?.toString()?.replaceAll('job:', '') ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? json['sender_role']?.toString() ?? '',
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      msgType: json['msg_type']?.toString() ?? 'text',
      mediaUrl: json['media_url']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['sent_at'] != null ? DateTime.parse(json['sent_at'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'sender_id': senderId,
      'sender_type': senderType,
      'content': content,
      'msg_type': msgType,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
