class Post {
  final int id;
  final String title;
  final String content;
  final int authorId;
  final String? authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String status;
  final Map<String, int> reactionCounts;
  final List<String> userReactions;
  final bool isViewed;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    this.authorName,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.status,
    required this.reactionCounts,
    required this.userReactions,
    required this.isViewed,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      authorId: json['author_id'],
      authorName: json['author_name'],
      createdAt: _parseISTDateTime(json['created_at']),      // ✅ FIXED: IST parsing
      updatedAt: _parseISTDateTime(json['updated_at']),      // ✅ FIXED: IST parsing
      isPinned: json['is_pinned'] ?? false,
      status: json['status'] ?? 'published',
      reactionCounts: Map<String, int>.from(json['reaction_counts'] ?? {}),
      userReactions: List<String>.from(json['user_reactions'] ?? []),
      isViewed: json['is_viewed'] ?? false,
    );
  }

  // ✅ ADD this helper method inside the Post class:
  static DateTime _parseISTDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    
    try {
      // Backend sends IST format: "2025-10-06 00:18:30"
      // Parse it directly as IST timezone equivalent
      return DateTime.parse(dateStr.replaceAll(' ', 'T'));
    } catch (e) {
      print('Error parsing IST datetime: $dateStr, Error: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned,
      'status': status,
      'reaction_counts': reactionCounts,
      'user_reactions': userReactions,
      'is_viewed': isViewed,
    };
  }

  String get timeAgo {
    // Use current IST time for accurate comparison
    final nowIST = DateTime.now();
    
    // Calculate difference with proper timezone handling
    final difference = nowIST.difference(createdAt);
    
    if (difference.inDays > 7) {
      // Show date for posts older than a week
      return formattedDate;
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Add formatted time display methods
  String get formattedTime {
    final hour = createdAt.hour > 12 
        ? createdAt.hour - 12 
        : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final ampm = createdAt.hour >= 12 ? "PM" : "AM";
    final min = createdAt.minute.toString().padLeft(2, '0');
    return "$hour:$min $ampm";
  }

  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    return "$day-$month-$year";
  }


  int get totalReactions {
    return reactionCounts.values.fold(0, (sum, count) => sum + count);
  }
}

class PostCreate {
  final String title;
  final String content;
  final bool isPinned;

  const PostCreate({
    required this.title,
    required this.content,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'is_pinned': isPinned,
    };
  }
}

class UnreadCount {
  final int unreadCount;

  const UnreadCount({required this.unreadCount});

  factory UnreadCount.fromJson(Map<String, dynamic> json) {
    return UnreadCount(unreadCount: json['unread_count']);
  }
}
