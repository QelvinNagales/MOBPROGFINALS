import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../widgets/repository_card.dart';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import 'add_project_screen.dart';
import 'user_profile_view_screen.dart';

/// Repositories Screen
/// Displays user's projects/repositories and explore public projects.
class RepositoriesScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const RepositoriesScreen({super.key, this.scaffoldKey});

  @override
  State<RepositoriesScreen> createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends State<RepositoriesScreen> with SingleTickerProviderStateMixin {
  List<Repository> _repositories = [];
  List<Map<String, dynamic>> _exploreProjects = [];
  bool _isLoading = true;
  bool _isLoadingExplore = true;
  late TabController _tabController;

  String _searchQuery = '';
  String _filterType = 'All';
  String _sortBy = 'Updated';
  
  String _exploreSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadProjects();
    _loadExploreProjects();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _exploreProjects.isEmpty && !_isLoadingExplore) {
      _loadExploreProjects();
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await SupabaseService.getMyProjects();
      
      if (mounted) {
        setState(() {
          _repositories = data.map((p) => Repository(
            id: p['id'] as String? ?? '',
            name: p['name'] as String? ?? 'Untitled Project',
            description: p['description'] as String? ?? '',
            language: p['language'] as String? ?? 'Unknown',
            starsCount: p['stars_count'] as int? ?? 0,
            forksCount: p['forks_count'] as int? ?? 0,
            isPublic: p['is_public'] as bool? ?? true,
            topics: (p['topics'] as List<dynamic>?)?.cast<String>() ?? [],
            updatedAt: DateTime.tryParse(p['updated_at'] as String? ?? ''),
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading projects: $e');
    }
  }

  List<Repository> get _filteredRepositories {
    var filtered = _repositories.where((repo) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return repo.name.toLowerCase().contains(query) ||
            repo.description.toLowerCase().contains(query) ||
            repo.topics.any((t) => t.toLowerCase().contains(query));
      }
      return true;
    }).where((repo) {
      // Type filter
      if (_filterType == 'Public') return repo.isPublic;
      if (_filterType == 'Private') return !repo.isPublic;
      return true;
    }).toList();

    // Sort
    if (_sortBy == 'Updated') {
      filtered.sort((a, b) => (b.lastUpdated ?? DateTime(1970)).compareTo(a.lastUpdated ?? DateTime(1970)));
    } else if (_sortBy == 'Stars') {
      filtered.sort((a, b) => b.stars.compareTo(a.stars));
    } else if (_sortBy == 'Name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  Future<void> _loadExploreProjects() async {
    setState(() => _isLoadingExplore = true);
    
    try {
      final data = await SupabaseService.getExploreProjects();
      
      if (mounted) {
        setState(() {
          _exploreProjects = data;
          _isLoadingExplore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingExplore = false);
      }
      debugPrint('Error loading explore projects: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredExploreProjects {
    if (_exploreSearchQuery.isEmpty) return _exploreProjects;
    
    final query = _exploreSearchQuery.toLowerCase();
    return _exploreProjects.where((project) {
      final name = (project['name'] as String? ?? '').toLowerCase();
      final description = (project['description'] as String? ?? '').toLowerCase();
      final language = (project['language'] as String? ?? '').toLowerCase();
      final topics = (project['topics'] as List<dynamic>?)?.cast<String>() ?? [];
      
      return name.contains(query) ||
          description.contains(query) ||
          language.contains(query) ||
          topics.any((t) => t.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: Text(
          'Projects',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.darkText),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(Icons.sort, color: isDark ? Colors.white70 : AppColors.darkText),
              onPressed: _showSortOptions,
              tooltip: 'Sort',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'My Projects'),
            Tab(text: 'Explore'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyProjectsTab(isDark, colorScheme),
          _buildExploreTab(isDark),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddRepositoryDialog,
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMyProjectsTab(bool isDark, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: AppColors.primaryBlue,
      child: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Public', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Private', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Repository count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 18,
                  color: isDark ? Colors.white54 : colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredRepositories.length} project${_filteredRepositories.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Repository list
          Expanded(
            child: _filteredRepositories.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _filteredRepositories.length,
                    itemBuilder: (context, index) {
                      final repo = _filteredRepositories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () => _showRepositoryDetails(repo),
                          child: RepositoryCard(repository: repo),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreTab(bool isDark) {
    if (_isLoadingExplore) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    return RefreshIndicator(
      onRefresh: _loadExploreProjects,
      color: AppColors.primaryBlue,
      child: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _exploreSearchQuery = value;
                });
              },
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
              decoration: InputDecoration(
                hintText: 'Discover public projects...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.explore, color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5)),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.public,
                  size: 18,
                  color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredExploreProjects.length} public project${_filteredExploreProjects.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Explore projects list
          Expanded(
            child: _filteredExploreProjects.isEmpty
                ? _buildExploreEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredExploreProjects.length,
                    itemBuilder: (context, index) {
                      final project = _filteredExploreProjects[index];
                      return _buildExploreProjectCard(project, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreProjectCard(Map<String, dynamic> project, bool isDark) {
    final profile = project['profiles'] as Map<String, dynamic>?;
    final ownerName = profile?['full_name'] ?? 'Unknown';
    final ownerAvatar = profile?['avatar_url'];
    final ownerId = profile?['id'];
    final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';
    
    final name = project['name'] ?? 'Untitled';
    final description = project['description'] ?? '';
    final language = project['language'] ?? 'Unknown';
    final stars = project['stars_count'] ?? 0;
    final topics = (project['topics'] as List<dynamic>?)?.cast<String>() ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.cardBorder,
          ),
        ),
        child: InkWell(
          onTap: () => _showExploreProjectDetails(project, isDark),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner info
                GestureDetector(
                  onTap: ownerId != null ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileViewScreen(userId: ownerId),
                      ),
                    );
                  } : null,
                  child: Row(
                    children: [
                      ownerAvatar != null && ownerAvatar.isNotEmpty
                          ? CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(ownerAvatar),
                            )
                          : CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                      const SizedBox(width: 8),
                      Text(
                        ownerName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Project name
                Row(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.darkText,
                        ),
                      ),
                    ),
                    // Star count
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$stars',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Language and topics
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        language,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (topics.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: topics.take(3).map((topic) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : AppColors.grey,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  topic,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExploreProjectDetails(Map<String, dynamic> project, bool isDark) {
    final profile = project['profiles'] as Map<String, dynamic>?;
    final ownerName = profile?['full_name'] ?? 'Unknown';
    final ownerAvatar = profile?['avatar_url'];
    final ownerId = profile?['id'];
    final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';
    
    final name = project['name'] ?? 'Untitled';
    final description = project['description'] ?? 'No description';
    final language = project['language'] ?? 'Unknown';
    final stars = project['stars_count'] ?? 0;
    final forks = project['forks_count'] ?? 0;
    final topics = (project['topics'] as List<dynamic>?)?.cast<String>() ?? [];
    final projectId = project['id'];

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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Owner info
                    GestureDetector(
                      onTap: ownerId != null ? () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileViewScreen(userId: ownerId),
                          ),
                        );
                      } : null,
                      child: Row(
                        children: [
                          ownerAvatar != null && ownerAvatar.isNotEmpty
                              ? CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(ownerAvatar),
                                )
                              : CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              Text(
                                'Tap to view profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Project name
                    Row(
                      children: [
                        Icon(Icons.folder_open_rounded, color: AppColors.warning, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Public badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public, size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Public',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            language,
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildExploreStat(Icons.star_rounded, '$stars', 'Stars', isDark),
                        _buildExploreStat(Icons.call_split_rounded, '$forks', 'Forks', isDark),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.darkText,
                        height: 1.5,
                      ),
                    ),
                    
                    if (topics.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Topics',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: topics.map((topic) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : AppColors.grey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Star button
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await SupabaseService.starProject(projectId);
                          Navigator.pop(context);
                          await _loadExploreProjects();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Starred $name'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Already starred or error: $e'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.star_border_rounded, color: Colors.white),
                      label: const Text('Star Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildExploreStat(IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 24, color: isDark ? Colors.white70 : AppColors.darkText),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildExploreEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off_rounded,
            size: 80,
            color: isDark ? Colors.white24 : AppColors.cardBorder,
          ),
          const SizedBox(height: 16),
          Text(
            'No public projects found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a public project!',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: isDark ? Colors.white24 : AppColors.darkText.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: TextStyle(
              color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project!',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _filterType == label;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? Colors.white 
              : (isDark ? Colors.white70 : AppColors.darkText),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = label;
        });
      },
      selectedColor: AppColors.primaryBlue,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white24 : Colors.grey.shade300),
      ),
    );
  }

  Future<void> _starProject(Repository repo) async {
    if (repo.id == null) return;
    
    try {
      await SupabaseService.starProject(repo.id!);
      await _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starred ${repo.name}!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starring project: $e');
    }
  }

  Future<void> _forkProject(Repository repo) async {
    // TODO: Implement fork functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Forked ${repo.name}!'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.update, color: isDark ? Colors.white70 : AppColors.darkText),
                title: Text('Recently Updated', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                trailing: _sortBy == 'Updated' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() => _sortBy = 'Updated');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.star, color: isDark ? Colors.white70 : AppColors.darkText),
                title: Text('Most Stars', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                trailing: _sortBy == 'Stars' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() => _sortBy = 'Stars');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.sort_by_alpha, color: isDark ? Colors.white70 : AppColors.darkText),
                title: Text('Name', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                trailing: _sortBy == 'Name' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() => _sortBy = 'Name');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showRepositoryDetails(Repository repo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      Icon(
                        repo.isPublic ? Icons.folder_open : Icons.lock,
                        size: 32,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          repo.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    repo.description.isEmpty ? 'No description' : repo.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Topics
                  if (repo.topics.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: repo.topics
                          .map(
                            (topic) => Chip(
                              label: Text(topic, style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
                              backgroundColor: isDark ? AppColors.darkBackground : AppColors.primaryBlue.withValues(alpha: 0.1),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(Icons.star, '${repo.stars}', 'Stars', isDark),
                      _buildStat(Icons.call_split, '${repo.forks}', 'Forks', isDark),
                      _buildStat(Icons.code, repo.language, 'Language', isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.code),
                          label: const Text('View Code'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteProject(repo);
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          label: const Text('Delete', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStat(IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 24, color: isDark ? Colors.white70 : AppColors.darkText),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteProject(Repository repo) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Project', style: TextStyle(color: isDark ? Colors.white : AppColors.darkText)),
        content: Text(
          'Are you sure you want to delete "${repo.name}"? This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : AppColors.darkText.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (repo.id == null) return;
      
      try {
        await SupabaseService.deleteProject(repo.id!);
        await _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${repo.name}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showAddRepositoryDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProjectScreen(),
      ),
    );
    
    // Refresh projects if a new one was created
    if (result == true) {
      await _loadProjects();
    }
  }
}
