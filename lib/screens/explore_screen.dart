import 'package:flutter/material.dart';
import '../models/friends.dart';
import '../widgets/user_card.dart';
import '../services/theme_service.dart';

/// Explore Screen
/// Discover students and projects to connect with in a modern minimalist style.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final Set<String> _connectedUsers = {};

  // Sample users to discover
  final List<Friend> _discoverUsers = [
    Friend(
      name: 'Sofia Rodriguez',
      course: 'BS Computer Science',
      interest: 'Machine Learning',
    ),
    Friend(
      name: 'James Chen',
      course: 'BS Information Technology',
      interest: 'Cloud Computing',
    ),
    Friend(
      name: 'Nina Patel',
      course: 'BS Computer Science',
      interest: 'Cybersecurity',
    ),
    Friend(
      name: 'Marcus Lee',
      course: 'BS Information Systems',
      interest: 'Database Management',
    ),
    Friend(
      name: 'Elena Kim',
      course: 'BS Computer Science',
      interest: 'Mobile Development',
    ),
    Friend(
      name: 'David Johnson',
      course: 'BS Information Technology',
      interest: 'DevOps',
    ),
    Friend(
      name: 'Sarah Williams',
      course: 'BS Computer Science',
      interest: 'UI/UX Design',
    ),
    Friend(
      name: 'Alex Thompson',
      course: 'BS Information Systems',
      interest: 'Business Analytics',
    ),
  ];

  // Categories/interests for filtering
  final List<String> _categories = [
    'All',
    'Mobile Development',
    'Web Development',
    'Data Science',
    'Machine Learning',
    'Cybersecurity',
    'Cloud Computing',
    'UI/UX Design',
    'Game Development',
  ];

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Friend> get _filteredUsers {
    return _discoverUsers.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.course.toLowerCase().contains(query) ||
            user.interest.toLowerCase().contains(query);
      }
      // Category filter
      if (_selectedCategory != 'All') {
        return user.interest == _selectedCategory;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        title: Text(
          'Explore',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.darkText),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.white12 : AppColors.cardBorder),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('People'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Trending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // People Tab
          _buildPeopleTab(isDark),

          // Trending Tab
          _buildTrendingTab(isDark),
        ],
      ),
    );
  }

  Widget _buildPeopleTab(bool isDark) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: isDark ? Colors.white : AppColors.darkText),
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : AppColors.darkText.withValues(alpha: 0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        // Category chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white12 : AppColors.cardBorder),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black : (isDark ? Colors.white70 : AppColors.darkText.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Users Grid
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No students found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final isConnected = _connectedUsers.contains(user.name);

                    return UserCard(
                      user: user,
                      isConnected: isConnected,
                      onConnect: () {
                        setState(() {
                          _connectedUsers.add(user.name);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connection request sent to ${user.name}!'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      onTap: () => _showUserProfile(user),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrendingTab(bool isDark) {
    // Trending topics and skills
    final trendingTopics = [
      {'name': 'Flutter Development', 'count': 156},
      {'name': 'Machine Learning', 'count': 142},
      {'name': 'React Native', 'count': 128},
      {'name': 'Cloud Computing', 'count': 115},
      {'name': 'Cybersecurity', 'count': 98},
      {'name': 'Data Analytics', 'count': 87},
      {'name': 'Blockchain', 'count': 76},
      {'name': 'DevOps', 'count': 69},
    ];

    final trendingProjects = [
      {'name': 'APC Events App', 'stars': 45, 'author': 'Maria Santos'},
      {'name': 'Study Buddy Finder', 'stars': 38, 'author': 'Carlos Reyes'},
      {'name': 'Campus Navigator', 'stars': 32, 'author': 'Ana Garcia'},
      {'name': 'Grade Calculator', 'stars': 28, 'author': 'James Chen'},
      {'name': 'Library System', 'stars': 24, 'author': 'Sofia Rodriguez'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Trending Topics Section
        Text(
          'Trending Topics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
          ),
          child: Column(
            children: trendingTopics.asMap().entries.map((entry) {
              final index = entry.key;
              final topic = entry.value;
              final isLast = index == trendingTopics.length - 1;
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic['name'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.darkText,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${topic['count']} students interested',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      height: 1,
                      color: isDark ? Colors.white12 : AppColors.cardBorder,
                    ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 28),

        // Trending Projects Section
        Text(
          'Popular Projects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
          ),
          child: Column(
            children: trendingProjects.asMap().entries.map((entry) {
              final index = entry.key;
              final project = entry.value;
              final isLast = index == trendingProjects.length - 1;
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.primaryBlue,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project['name'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.darkText,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'by ${project['author']}',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${project['stars']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.primaryBlue : const Color(0xFFD97706),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      height: 1,
                      color: isDark ? Colors.white12 : AppColors.cardBorder,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showUserProfile(Friend user) {
    final isConnected = _connectedUsers.contains(user.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.primaryBlue : AppColors.darkText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.darkText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.course,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.interest,
                            style: TextStyle(
                              color: isDark ? AppColors.primaryBlue : const Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildProfileStat('5', 'Projects', isDark),
                        Container(width: 1, height: 40, color: isDark ? Colors.white12 : AppColors.cardBorder),
                        _buildProfileStat('24', 'Connections', isDark),
                        Container(width: 1, height: 40, color: isDark ? Colors.white12 : AppColors.cardBorder),
                        _buildProfileStat('12', 'Skills', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: isConnected
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.message_rounded, size: 20, color: AppColors.primaryBlue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Message',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : InkWell(
                                onTap: () {
                                  setState(() {
                                    _connectedUsers.add(user.name);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Connection request sent to ${user.name}!'),
                                      backgroundColor: AppColors.primaryBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_rounded, size: 20, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Connect',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? Colors.white12 : AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_rounded, size: 20, color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6)),
                                const SizedBox(width: 8),
                                Text(
                                  'Projects',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
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

  Widget _buildProfileStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : AppColors.darkText.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
