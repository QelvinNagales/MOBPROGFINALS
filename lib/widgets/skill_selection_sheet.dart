import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';

/// Skill Selection Widget - Bumble-inspired skill picker
/// Allows users to select skills from predefined categories
/// or add custom skills if not found
class SkillSelectionSheet extends StatefulWidget {
  final List<String> selectedSkills;
  final Function(List<String>) onSkillsChanged;

  const SkillSelectionSheet({
    super.key,
    required this.selectedSkills,
    required this.onSkillsChanged,
  });

  @override
  State<SkillSelectionSheet> createState() => _SkillSelectionSheetState();
}

class _SkillSelectionSheetState extends State<SkillSelectionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customSkillController = TextEditingController();

  List<Map<String, dynamic>> _allSkills = [];
  List<String> _selectedSkills = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Predefined skill categories with icons
  final Map<String, IconData> _categoryIcons = {
    'Programming Languages': Icons.code_rounded,
    'Frameworks': Icons.widgets_rounded,
    'Databases': Icons.storage_rounded,
    'DevOps': Icons.cloud_rounded,
    'Design': Icons.palette_rounded,
    'Soft Skills': Icons.psychology_rounded,
    'Languages': Icons.translate_rounded,
    'Tools': Icons.build_rounded,
    'General': Icons.star_rounded,
    'Mobile': Icons.phone_android_rounded,
    'Web': Icons.web_rounded,
    'AI/ML': Icons.smart_toy_rounded,
    'Methodology': Icons.groups_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedSkills = List.from(widget.selectedSkills);
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await SupabaseService.getAllSkills();
      if (mounted) {
        setState(() {
          _allSkills = skills;
          _categories = skills
              .map((s) => s['category'] as String? ?? 'General')
              .toSet()
              .toList()
            ..sort();
          _tabController = TabController(length: _categories.length + 1, vsync: this);
          _isLoading = false;
        });
      }
    } catch (e) {
      // If skills table doesn't exist, use default skills
      if (mounted) {
        setState(() {
          _allSkills = _getDefaultSkills();
          _categories = _allSkills
              .map((s) => s['category'] as String)
              .toSet()
              .toList()
            ..sort();
          _tabController = TabController(length: _categories.length + 1, vsync: this);
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultSkills() {
    return [
      // Programming Languages
      {'name': 'Python', 'category': 'Programming Languages', 'color': '#3776AB'},
      {'name': 'JavaScript', 'category': 'Programming Languages', 'color': '#F7DF1E'},
      {'name': 'TypeScript', 'category': 'Programming Languages', 'color': '#3178C6'},
      {'name': 'Java', 'category': 'Programming Languages', 'color': '#007396'},
      {'name': 'C++', 'category': 'Programming Languages', 'color': '#00599C'},
      {'name': 'C#', 'category': 'Programming Languages', 'color': '#512BD4'},
      {'name': 'Dart', 'category': 'Programming Languages', 'color': '#0175C2'},
      {'name': 'Kotlin', 'category': 'Programming Languages', 'color': '#7F52FF'},
      {'name': 'Swift', 'category': 'Programming Languages', 'color': '#FA7343'},
      {'name': 'Go', 'category': 'Programming Languages', 'color': '#00ADD8'},
      {'name': 'Rust', 'category': 'Programming Languages', 'color': '#000000'},
      {'name': 'PHP', 'category': 'Programming Languages', 'color': '#777BB4'},
      {'name': 'Ruby', 'category': 'Programming Languages', 'color': '#CC342D'},
      // Frameworks
      {'name': 'Flutter', 'category': 'Frameworks', 'color': '#02569B'},
      {'name': 'React', 'category': 'Frameworks', 'color': '#61DAFB'},
      {'name': 'React Native', 'category': 'Frameworks', 'color': '#61DAFB'},
      {'name': 'Angular', 'category': 'Frameworks', 'color': '#DD0031'},
      {'name': 'Vue.js', 'category': 'Frameworks', 'color': '#4FC08D'},
      {'name': 'Node.js', 'category': 'Frameworks', 'color': '#339933'},
      {'name': 'Express.js', 'category': 'Frameworks', 'color': '#000000'},
      {'name': 'Django', 'category': 'Frameworks', 'color': '#092E20'},
      {'name': 'Flask', 'category': 'Frameworks', 'color': '#000000'},
      {'name': 'Spring Boot', 'category': 'Frameworks', 'color': '#6DB33F'},
      {'name': '.NET', 'category': 'Frameworks', 'color': '#512BD4'},
      {'name': 'Next.js', 'category': 'Frameworks', 'color': '#000000'},
      {'name': 'Laravel', 'category': 'Frameworks', 'color': '#FF2D20'},
      // Databases
      {'name': 'MySQL', 'category': 'Databases', 'color': '#4479A1'},
      {'name': 'PostgreSQL', 'category': 'Databases', 'color': '#4169E1'},
      {'name': 'MongoDB', 'category': 'Databases', 'color': '#47A248'},
      {'name': 'Redis', 'category': 'Databases', 'color': '#DC382D'},
      {'name': 'Firebase', 'category': 'Databases', 'color': '#FFCA28'},
      {'name': 'Supabase', 'category': 'Databases', 'color': '#3ECF8E'},
      {'name': 'SQLite', 'category': 'Databases', 'color': '#003B57'},
      // DevOps
      {'name': 'Docker', 'category': 'DevOps', 'color': '#2496ED'},
      {'name': 'Kubernetes', 'category': 'DevOps', 'color': '#326CE5'},
      {'name': 'AWS', 'category': 'DevOps', 'color': '#FF9900'},
      {'name': 'Google Cloud', 'category': 'DevOps', 'color': '#4285F4'},
      {'name': 'Azure', 'category': 'DevOps', 'color': '#0078D4'},
      {'name': 'Git', 'category': 'DevOps', 'color': '#F05032'},
      {'name': 'GitHub', 'category': 'DevOps', 'color': '#181717'},
      {'name': 'CI/CD', 'category': 'DevOps', 'color': '#2088FF'},
      // Design
      {'name': 'Figma', 'category': 'Design', 'color': '#F24E1E'},
      {'name': 'Adobe XD', 'category': 'Design', 'color': '#FF61F6'},
      {'name': 'Photoshop', 'category': 'Design', 'color': '#31A8FF'},
      {'name': 'Illustrator', 'category': 'Design', 'color': '#FF9A00'},
      {'name': 'UI/UX Design', 'category': 'Design', 'color': '#FF6B6B'},
      {'name': 'Canva', 'category': 'Design', 'color': '#00C4CC'},
      // Soft Skills
      {'name': 'Leadership', 'category': 'Soft Skills', 'color': '#FFD700'},
      {'name': 'Communication', 'category': 'Soft Skills', 'color': '#4CAF50'},
      {'name': 'Problem Solving', 'category': 'Soft Skills', 'color': '#2196F3'},
      {'name': 'Teamwork', 'category': 'Soft Skills', 'color': '#9C27B0'},
      {'name': 'Time Management', 'category': 'Soft Skills', 'color': '#FF5722'},
      {'name': 'Critical Thinking', 'category': 'Soft Skills', 'color': '#607D8B'},
      {'name': 'Creativity', 'category': 'Soft Skills', 'color': '#E91E63'},
      {'name': 'Adaptability', 'category': 'Soft Skills', 'color': '#00BCD4'},
      // AI/ML
      {'name': 'Machine Learning', 'category': 'AI/ML', 'color': '#FF6F00'},
      {'name': 'Deep Learning', 'category': 'AI/ML', 'color': '#FF6F00'},
      {'name': 'TensorFlow', 'category': 'AI/ML', 'color': '#FF6F00'},
      {'name': 'PyTorch', 'category': 'AI/ML', 'color': '#EE4C2C'},
      {'name': 'Computer Vision', 'category': 'AI/ML', 'color': '#4CAF50'},
      {'name': 'NLP', 'category': 'AI/ML', 'color': '#2196F3'},
      // Methodology
      {'name': 'Agile', 'category': 'Methodology', 'color': '#6200EA'},
      {'name': 'Scrum', 'category': 'Methodology', 'color': '#6200EA'},
      {'name': 'Kanban', 'category': 'Methodology', 'color': '#00BFA5'},
    ];
  }

  List<Map<String, dynamic>> _getFilteredSkills(String? category) {
    List<Map<String, dynamic>> filtered = _allSkills;

    if (category != null) {
      filtered = filtered.where((s) => s['category'] == category).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              (s['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _toggleSkill(String skillName) {
    setState(() {
      if (_selectedSkills.contains(skillName)) {
        _selectedSkills.remove(skillName);
      } else {
        _selectedSkills.add(skillName);
      }
    });
  }

  Future<void> _addCustomSkill() async {
    final skillName = _customSkillController.text.trim();
    if (skillName.isEmpty) return;

    // Check if skill already exists
    final exists = _allSkills.any(
        (s) => (s['name'] as String).toLowerCase() == skillName.toLowerCase());
    
    if (exists) {
      // Just add it to selected
      if (!_selectedSkills.contains(skillName)) {
        setState(() {
          _selectedSkills.add(skillName);
        });
      }
    } else {
      // Add new custom skill
      try {
        await SupabaseService.createSkill(name: skillName);
      } catch (e) {
        // Ignore errors, just add locally
      }
      
      setState(() {
        _allSkills.add({
          'name': skillName,
          'category': 'Custom',
          'color': '#7C4DFF',
        });
        _selectedSkills.add(skillName);
      });
    }

    _customSkillController.clear();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showAddCustomSkillDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            const Text('Add Custom Skill'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Can't find your skill? Add it here!",
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customSkillController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter skill name',
                prefixIcon: const Icon(Icons.lightbulb_outline_rounded),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addCustomSkill,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Skill'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _customSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Your Skills',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_selectedSkills.length} skills selected',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onSkillsChanged(_selectedSkills);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search skills...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.grey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selected Skills Preview
          if (_selectedSkills.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedSkills.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_selectedSkills[index]),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _toggleSkill(_selectedSkills[index]),
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_selectedSkills.isNotEmpty) const SizedBox(height: 12),

          // Loading or Content
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Category Tabs
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.primaryBlue,
                      unselectedLabelColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      indicatorColor: AppColors.primaryBlue,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                      tabs: [
                        const Tab(text: 'All'),
                        ..._categories.map((cat) => Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _categoryIcons[cat] ?? Icons.code_rounded,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(cat),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),

                  // Skills Grid
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSkillsGrid(null),
                        ..._categories.map((cat) => _buildSkillsGrid(cat)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Add Custom Skill Button
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAddCustomSkillDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Can't find your skill? Add it!"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsGrid(String? category) {
    final skills = _getFilteredSkills(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No skills found',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showAddCustomSkillDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Skill'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final skillName = skill['name'] as String;
        final isSelected = _selectedSkills.contains(skillName);
        final color = _parseColor(skill['color'] as String? ?? '#3D3D8F');

        return GestureDetector(
          onTap: () => _toggleSkill(skillName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : (isDark ? AppColors.darkCard : AppColors.grey),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: color,
                    ),
                  ),
                Flexible(
                  child: Text(
                    skillName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? color
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppColors.primaryBlue;
    }
  }
}

/// Helper function to show skill selection sheet
Future<void> showSkillSelectionSheet(
  BuildContext context, {
  required List<String> selectedSkills,
  required Function(List<String>) onSkillsChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SkillSelectionSheet(
      selectedSkills: selectedSkills,
      onSkillsChanged: onSkillsChanged,
    ),
  );
}
