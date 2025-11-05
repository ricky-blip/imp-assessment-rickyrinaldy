import 'package:flutter/material.dart';
import 'package:imp_assessment_flutter_dev/services/dummyjson_services.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _showScrollToTopButton = false;
  String? _errorMsg;

  // Pagination properties
  int _currentPage = 0;
  static const int _pageSize = 10;
  bool _hasMoreData = true;

  // Multiple selection state
  bool _isSelectionMode = false;
  Set<int> _selectedIds = {};
  final Set<int> _localPostIds = {};
  int _nextLocalId = 1000;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // Show/hide scroll to top button
    if (currentScroll > 300 && !_showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = true;
      });
    } else if (currentScroll <= 300 && _showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = false;
      });
    }

    // Load more when scroll to 80%
    if (currentScroll >= (maxScroll * 0.8) &&
        !_isLoadingMore &&
        _hasMoreData &&
        !_isLoading) {
      _loadMore();
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<bool?> _showConfirmationBottomSheet({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await _showConfirmationBottomSheet(
      title: 'Logout',
      message: 'Yakin ingin keluar dari akun Anda?',
      icon: Icons.logout_rounded,
      iconColor: Colors.orange,
      confirmText: 'Logout',
      confirmColor: Colors.orange,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final posts = await _apiService.getPosts();
      setState(() {
        _posts = (posts as List).take(_pageSize).toList();
        _currentPage = 1;
        _hasMoreData = posts.length > _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final allPosts = await _apiService.getPosts();
      final startIndex = _currentPage * _pageSize;
      final endIndex = startIndex + _pageSize;

      final newPosts = (allPosts as List).sublist(
        startIndex,
        endIndex > allPosts.length ? allPosts.length : endIndex,
      );

      setState(() {
        _posts.addAll(newPosts);
        _currentPage++;
        _hasMoreData = endIndex < allPosts.length;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal load more: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
      _posts.clear();
    });
    await _fetchPosts();
  }

  Future<void> _scrollToTop() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _addPost(String title, String body) async {
    _showLoadingDialog('Menambahkan post...');

    try {
      final newPost = await _apiService.addPost(title, body);
      _hideLoadingDialog();

      final localId = _nextLocalId++;
      newPost['id'] = localId;

      setState(() {
        _posts.insert(0, newPost);
        _localPostIds.add(localId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post berhasil ditambahkan! (Local only)'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _hideLoadingDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updatePost(int id, String title, String body) async {
    if (_localPostIds.contains(id)) {
      setState(() {
        final index = _posts.indexWhere((post) => post['id'] == id);
        if (index != -1) {
          _posts[index]['title'] = title;
          _posts[index]['body'] = body;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post lokal berhasil diupdate!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _showLoadingDialog('Mengupdate post...');

    try {
      final updatedPost = await _apiService.updatePost(id, title, body);
      _hideLoadingDialog();

      setState(() {
        final index = _posts.indexWhere((post) => post['id'] == id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post berhasil diupdate!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _hideLoadingDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deletePost(int id) async {
    if (_localPostIds.contains(id)) {
      setState(() {
        _posts.removeWhere((post) => post['id'] == id);
        _localPostIds.remove(id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post lokal berhasil dihapus!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _showLoadingDialog('Menghapus post...');

    try {
      await _apiService.deletePost(id);
      _hideLoadingDialog();

      setState(() {
        _posts.removeWhere((post) => post['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post berhasil dihapus!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _hideLoadingDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteMultiplePosts() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    _showLoadingDialog('Menghapus $count post...');

    try {
      for (int id in _selectedIds) {
        await _apiService.deletePost(id);
      }

      _hideLoadingDialog();

      setState(() {
        _posts.removeWhere((post) => _selectedIds.contains(post['id']));
        _selectedIds.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count post berhasil dihapus!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _hideLoadingDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal menghapus: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteVisiblePosts() async {
    final confirmed = await _showConfirmationBottomSheet(
      title: 'Hapus ${_posts.length} Posts yang Ditampilkan?',
      message: 'Hanya posts yang terlihat di layar akan dihapus.',
      icon: Icons.delete_rounded,
      iconColor: Colors.blue,
      confirmText: 'Hapus',
      confirmColor: Colors.blue,
    );

    if (confirmed == true) {
      final visibleIds = _posts.map((post) => post['id'] as int).toSet();
      setState(() {
        _selectedIds = visibleIds;
      });
      await _deleteMultiplePosts();
    }
  }

  Future<void> _deleteAllPostsFromDatabase() async {
    final confirmed = await _showConfirmationBottomSheet(
      title: 'Hapus SEMUA Posts?',
      message:
          'Ini akan mengunduh dan menghapus SEMUA posts dari database.\n\nTindakan ini tidak dapat dibatalkan!',
      icon: Icons.delete_sweep_rounded,
      iconColor: Colors.red,
      confirmText: 'Hapus Semua',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    _showLoadingDialog('Mengunduh dan menghapus semua posts...');

    try {
      final allPosts = await _apiService.getPosts();
      final allIds =
          (allPosts as List).map((post) => post['id'] as int).toList();

      for (int id in allIds) {
        await _apiService.deletePost(id);
      }

      _hideLoadingDialog();

      setState(() {
        _posts.clear();
        _selectedIds.clear();
        _isSelectionMode = false;
        _currentPage = 0;
        _hasMoreData = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${allIds.length} posts berhasil dihapus!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _hideLoadingDialog();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal menghapus: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllPosts() async {
    if (_posts.isEmpty) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded,
                  size: 32, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Posts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih posts mana yang ingin dihapus',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'visible'),
                icon: const Icon(Icons.visibility, color: Colors.blue),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hapus ${_posts.length} Posts yang Ditampilkan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hanya posts yang sedang terlihat di layar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.blue.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'all'),
                icon: const Icon(Icons.cloud_download, color: Colors.orange),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hapus SEMUA Posts (${_hasMoreData ? '${_posts.length}+' : _posts.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hapus semua posts yang ada di database',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.orange.shade300),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (result == 'visible') {
      await _deleteVisiblePosts();
    } else if (result == 'all') {
      await _deleteAllPostsFromDatabase();
    }
  }

  Future<void> _confirmMultipleDelete() async {
    final confirmed = await _showConfirmationBottomSheet(
      title: 'Hapus ${_selectedIds.length} Posts',
      message:
          'Yakin ingin menghapus ${_selectedIds.length} posts yang dipilih?',
      icon: Icons.delete_rounded,
      iconColor: Colors.red,
      confirmText: 'Hapus',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      await _deleteMultiplePosts();
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _posts.length) {
        _selectedIds.clear();
      } else {
        _selectedIds = _posts.map((post) => post['id'] as int).toSet();
      }
    });
  }

  void _onLongPress(int postId) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIds.add(postId);
      });
    }
  }

  void _showPostDialog({int? id, String? initialTitle, String? initialBody}) {
    final titleController = TextEditingController(text: initialTitle);
    final bodyController = TextEditingController(text: initialBody);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Tambah Post' : 'Edit Post'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Body tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                if (id == null) {
                  _addPost(
                    titleController.text.trim(),
                    bodyController.text.trim(),
                  );
                } else {
                  _updatePost(
                    id,
                    titleController.text.trim(),
                    bodyController.text.trim(),
                  );
                }
              }
            },
            child: Text(id == null ? 'Tambah' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(int id, String title) async {
    final confirmed = await _showConfirmationBottomSheet(
      title: 'Hapus Post',
      message: 'Yakin ingin menghapus post "$title"?',
      icon: Icons.delete_rounded,
      iconColor: Colors.red,
      confirmText: 'Hapus',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      _deletePost(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userData = args?['userData'];
    final userName = userData?['firstName'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isSelectionMode ? '${_selectedIds.length} dipilih' : 'Posts'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(_selectedIds.length == _posts.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank),
              onPressed: _toggleSelectAll,
              tooltip: 'Pilih Semua',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedIds.isEmpty ? null : _confirmMultipleDelete,
              tooltip: 'Hapus',
            ),
          ] else ...[
            if (_posts.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _deleteAllPosts,
                tooltip: 'Hapus Semua',
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _confirmLogout,
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!_isSelectionMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.deepPurple,
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
                            'Welcome, $userName!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Posts: ${_posts.length}${!_hasMoreData ? '' : '+'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_posts.isNotEmpty)
                                Text(
                                  '• Long press untuk select',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_posts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMsg != null
                      ? RefreshIndicator(
                          onRefresh: _refresh,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height - 200,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 60, color: Colors.red.shade300),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Text(
                                      _errorMsg!,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Swipe down to refresh',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : _posts.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _refresh,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height - 200,
                                  alignment: Alignment.center,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inbox,
                                          size: 80, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Tidak ada posts',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap + untuk menambah post baru',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              color: Colors.deepPurple,
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(8),
                                itemCount:
                                    _posts.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _posts.length) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          const CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.deepPurple),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Loading more posts...',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final post = _posts[index];
                                  final postId = post['id'] as int;
                                  final isSelected =
                                      _selectedIds.contains(postId);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    elevation: isSelected ? 4 : 1,
                                    color: isSelected
                                        ? Colors.deepPurple.shade50
                                        : null,
                                    child: ListTile(
                                      leading: _isSelectionMode
                                          ? Checkbox(
                                              value: isSelected,
                                              activeColor: Colors.deepPurple,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedIds.add(postId);
                                                  } else {
                                                    _selectedIds.remove(postId);
                                                  }
                                                });
                                              },
                                            )
                                          : CircleAvatar(
                                              backgroundColor:
                                                  Colors.deepPurple.shade100,
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.deepPurple,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              post['title'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.deepPurple
                                                    : null,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_localPostIds.contains(postId))
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'LOCAL',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        post['body'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: _isSelectionMode
                                          ? isSelected
                                              ? const Icon(Icons.check_circle,
                                                  color: Colors.deepPurple)
                                              : null
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _showPostDialog(
                                                    id: postId,
                                                    initialTitle: post['title'],
                                                    initialBody: post['body'],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _showDeleteConfirmation(
                                                    postId,
                                                    post['title'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                      onTap: _isSelectionMode
                                          ? () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedIds.remove(postId);
                                                } else {
                                                  _selectedIds.add(postId);
                                                }
                                              });
                                            }
                                          : null,
                                      onLongPress: () => _onLongPress(postId),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _confirmMultipleDelete,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete),
              label: Text('Hapus ${_selectedIds.length}'),
            )
          : Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Scroll to Top Button
                AnimatedOpacity(
                  opacity: _showScrollToTopButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: FloatingActionButton(
                      onPressed: _scrollToTop,
                      backgroundColor: Colors.deepPurple.shade600,
                      tooltip: 'Scroll to Top',
                      heroTag: 'scrollToTop',
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Add Post Button
                FloatingActionButton(
                  onPressed: () => _showPostDialog(),
                  backgroundColor: Colors.deepPurple,
                  tooltip: 'Tambah Post',
                  heroTag: 'addPost',
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
    );
  }
}
