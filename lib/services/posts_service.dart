import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/post_models.dart';

class PostsService {
  static const String _base = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();

  static Future<String?> _token() => _storage.read(key: 'jwt');
  static bool _isUnauthorized(http.Response r) => r.statusCode == 401;

  // Get all posts
  static Future<List<Post>?> fetchPosts({int skip = 0, int limit = 20}) async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/posts/?skip=$skip&limit=$limit'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (_isUnauthorized(res)) return null;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Post.fromJson(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  // Get specific post
  static Future<Post?> fetchPost(int postId) async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/posts/$postId'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (_isUnauthorized(res)) return null;

      if (res.statusCode == 200) {
        return Post.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // Toggle reaction
  static Future<bool> toggleReaction(int postId, String emoji) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/posts/$postId/react'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'emoji': emoji}),
      );

      if (_isUnauthorized(res)) return false;
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Mark post as viewed
  static Future<bool> markPostViewed(int postId) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/posts/$postId/view'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (_isUnauthorized(res)) return false;
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/posts/unread/count'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (_isUnauthorized(res)) return 0;

      if (res.statusCode == 200) {
        final data = UnreadCount.fromJson(jsonDecode(res.body));
        return data.unreadCount;
      }
    } catch (_) {}
    return 0;
  }

  // Admin: Create post
  static Future<Post?> createPost(PostCreate postCreate) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/admin/posts/'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(postCreate.toJson()),
      );

      if (_isUnauthorized(res)) return null;

      if (res.statusCode == 200) {
        return Post.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // Admin: Get all posts
  static Future<List<Post>?> fetchAllPostsAdmin({int skip = 0, int limit = 50}) async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/admin/posts/?skip=$skip&limit=$limit'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (_isUnauthorized(res)) return null;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Post.fromJson(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  // Admin: Delete post
  static Future<bool> deletePost(int postId) async {
    try {
      final jwt = await _token();
      final res = await http.delete(
        Uri.parse('$_base/admin/posts/$postId'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (_isUnauthorized(res)) return false;
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Admin: Toggle pin
  static Future<bool> togglePin(int postId) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/admin/posts/$postId/toggle-pin'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (_isUnauthorized(res)) return false;
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
