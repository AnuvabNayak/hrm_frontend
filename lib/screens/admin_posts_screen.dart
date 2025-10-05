import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post_models.dart';
import '../services/posts_service.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import 'admin_create_post_screen.dart';

class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  List<Post> posts = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final fetchedPosts = await PostsService.fetchAllPostsAdmin();
      if (fetchedPosts != null) {
        setState(() {
          posts = fetchedPosts;
          loading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load posts';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error';
        loading = false;
      });
    }
  }

  Future<void> _togglePin(int postId) async {
    final success = await PostsService.togglePin(postId);
    if (success) {
      _showSnackBar('Post pin status updated');
      _fetchPosts(); // Refresh
    } else {
      _showSnackBar('Failed to update pin status', isError: true);
    }
  }

  Future<void> _deletePost(int postId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Post',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.nunito()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PostsService.deletePost(postId);
      if (success) {
        _showSnackBar('Post deleted successfully');
        _fetchPosts(); // Refresh
      } else {
        _showSnackBar('Failed to delete post', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.nunito()),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Row(
              children: [
                if (post.isPinned) ...[
                  Icon(Icons.push_pin, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    post.title,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'pin') {
                      _togglePin(post.id);
                    } else if (value == 'delete') {
                      _deletePost(post.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            post.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.isPinned ? 'Unpin' : 'Pin',
                            style: GoogleFonts.nunito(),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: GoogleFonts.nunito(color: Colors.red.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Author & Time
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  post.authorName ?? 'Unknown',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  post.timeAgo,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content preview
            Text(
              post.content.length > 150
                  ? '${post.content.substring(0, 150)}...'
                  : post.content,
              style: GoogleFonts.nunito(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            
            if (post.totalReactions > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${post.totalReactions} reactions',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Manage Posts",
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade600),
            onPressed: _fetchPosts,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPosts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            "No Posts Created",
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap + to create your first post",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPosts,
                      child: ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) => _buildPostCard(posts[index]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminCreatePostScreen()),
          );
          if (result == true) {
            _fetchPosts(); // Refresh after creating post
          }
        },
        backgroundColor: Colors.red.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 4),
    );
  }
}

