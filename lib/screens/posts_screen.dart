import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_models.dart';
import '../services/posts_service.dart';
import '../widgets/bottom_nav_bar.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({Key? key}) : super(key: key);

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<Post> posts = [];
  bool loading = true;
  String? error;
  int unreadCount = 0;

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
      final fetchedPosts = await PostsService.fetchPosts();
      if (fetchedPosts != null) {
        setState(() {
          posts = fetchedPosts;
          loading = false;
        });
        
        // Mark posts as viewed and update unread count
        _markPostsAsViewed();
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

  Future<void> _markPostsAsViewed() async {
    // Mark unread posts as viewed
    final unreadPosts = posts.where((p) => !p.isViewed).toList();
    for (final post in unreadPosts) {
      await PostsService.markPostViewed(post.id);
    }

    // Update unread count
    final count = await PostsService.getUnreadCount();
    setState(() {
      unreadCount = count;
    });
  }

  Future<void> _toggleReaction(int postId, String emoji) async {
    final success = await PostsService.toggleReaction(postId, emoji);
    if (success) {
      _fetchPosts(); // Refresh to get updated reaction counts
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
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
            // Header
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
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
            
            // Content with clickable links
            _buildRichContent(post.content),
            
            if (post.totalReactions > 0) ...[
              const SizedBox(height: 16),
              _buildReactionBar(post),
            ],
            
            const SizedBox(height: 12),
            
            // Reaction Buttons
            _buildReactionButtons(post),
          ],
        ),
      ),
    );
  }

  Widget _buildRichContent(String content) {
    final urlPattern = RegExp(r'https?://[^\s]+');
    final matches = urlPattern.allMatches(content);
    
    if (matches.isEmpty) {
      return Text(
        content,
        style: GoogleFonts.nunito(
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      );
    }

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in matches) {
      // Add text before URL
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: content.substring(currentIndex, match.start),
          style: GoogleFonts.nunito(fontSize: 15, height: 1.5, color: Colors.black87),
        ));
      }

      // Add URL as clickable link
      final url = content.substring(match.start, match.end);
      spans.add(TextSpan(
        text: url,
        style: GoogleFonts.nunito(
          fontSize: 15,
          height: 1.5,
          color: Colors.blue.shade600,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchURL(url),
      ));

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(currentIndex),
        style: GoogleFonts.nunito(fontSize: 15, height: 1.5, color: Colors.black87),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildReactionBar(Post post) {
    return Wrap(
      spacing: 8,
      children: post.reactionCounts.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${entry.key} ${entry.value}',
            style: GoogleFonts.nunito(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReactionButtons(Post post) {
    const reactions = ['👍', '❤️', '😊', '🎉', '😮', '😢'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: reactions.map((emoji) {
        final isSelected = post.userReactions.contains(emoji);
        return InkWell(
          onTap: () => _toggleReaction(post.id, emoji),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Posts",
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
                            "No Posts Yet",
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Check back later for company announcements",
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
      bottomNavigationBar: MyBottomNavBar(
        currentIndex: 1,
        unreadCount: unreadCount, // ✅ Pass unread count
      ),
    );
  }
}
