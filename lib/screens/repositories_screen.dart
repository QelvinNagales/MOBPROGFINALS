import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../widgets/repository_card.dart';

/// Repositories Screen
/// Displays user's projects/repositories in a list format.
class RepositoriesScreen extends StatefulWidget {
  const RepositoriesScreen({super.key});

  @override
  State<RepositoriesScreen> createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends State<RepositoriesScreen> {
  // Sample repository data
  final List<Repository> _repositories = [
    Repository(
      id: '1',
      name: 'apc-campus-guide',
      description:
          'A mobile app to help students navigate the APC campus with indoor mapping and event schedules.',
      language: 'Flutter',
      starsCount: 24,
      forksCount: 8,
      topics: ['flutter', 'dart', 'maps', 'education'],
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Repository(
      id: '2',
      name: 'student-budget-tracker',
      description:
          'Personal finance management app for students with expense tracking and budget alerts.',
      language: 'Dart',
      starsCount: 18,
      forksCount: 5,
      topics: ['finance', 'flutter', 'sqlite'],
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Repository(
      id: '3',
      name: 'weather-forecast-app',
      description:
          'Simple weather app with 7-day forecast and location-based updates.',
      language: 'Flutter',
      starsCount: 12,
      forksCount: 3,
      topics: ['weather', 'api', 'flutter'],
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Repository(
      id: '4',
      name: 'study-group-finder',
      description:
          'Platform for students to find and create study groups based on courses and interests.',
      language: 'Dart',
      starsCount: 8,
      forksCount: 2,
      isPublic: true,
      topics: ['social', 'education', 'networking'],
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Repository(
      id: '5',
      name: 'personal-portfolio',
      description: 'My personal portfolio website showcasing projects and skills.',
      language: 'JavaScript',
      starsCount: 5,
      forksCount: 1,
      topics: ['portfolio', 'web', 'html', 'css'],
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  String _searchQuery = '';
  String _filterType = 'All';
  String _sortBy = 'Updated';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
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
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Public'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Private'),
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
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredRepositories.length} repositories',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Repository List
          Expanded(
            child: _filteredRepositories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No projects found',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _filteredRepositories.length,
                    itemBuilder: (context, index) {
                      final repo = _filteredRepositories[index];
                      return RepositoryCard(
                        repository: repo,
                        onTap: () => _showRepositoryDetails(repo),
                        onStar: () {
                          setState(() {
                            final repoIndex = _repositories.indexOf(repo);
                            _repositories[repoIndex] = repo.copyWith(
                              stars: repo.stars + 1,
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Starred ${repo.name}!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        onFork: () {
                          setState(() {
                            final repoIndex = _repositories.indexOf(repo);
                            _repositories[repoIndex] = repo.copyWith(
                              forks: repo.forks + 1,
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Forked ${repo.name}!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRepositoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = label;
        });
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('Recently Updated'),
                trailing:
                    _sortBy == 'Updated' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'Updated');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Most Stars'),
                trailing: _sortBy == 'Stars' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'Stars');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Name'),
                trailing: _sortBy == 'Name' ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _sortBy = 'Name');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRepositoryDetails(Repository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

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
                        color: colorScheme.onSurface.withOpacity(0.2),
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
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          repo.name,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    repo.description,
                    style: Theme.of(context).textTheme.bodyLarge,
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
                              label: Text(topic),
                              backgroundColor: colorScheme.primaryContainer,
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
                      _buildStat(Icons.star, '${repo.stars}', 'Stars'),
                      _buildStat(Icons.call_split, '${repo.forks}', 'Forks'),
                      _buildStat(Icons.code, repo.language, 'Language'),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
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

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showAddRepositoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Project'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Project Name',
                        hintText: 'my-awesome-project',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'A brief description of your project',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Public'),
                      subtitle: Text(
                        isPublic
                            ? 'Anyone can see this project'
                            : 'Only you can see this project',
                      ),
                      value: isPublic,
                      onChanged: (value) {
                        setDialogState(() {
                          isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        _repositories.insert(
                          0,
                          Repository(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text.trim(),
                            description: descController.text.trim().isEmpty
                                ? 'No description provided'
                                : descController.text.trim(),
                            isPublic: isPublic,
                          ),
                        );
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Created ${nameController.text.trim()}!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
