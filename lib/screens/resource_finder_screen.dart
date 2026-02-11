import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/services/storage_service.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class ResourceFinderScreen extends StatefulWidget {
  const ResourceFinderScreen({super.key});

  @override
  State<ResourceFinderScreen> createState() => _ResourceFinderScreenState();
}

class _ResourceFinderScreenState extends State<ResourceFinderScreen> {
  final List<Map<String, dynamic>> _resources = [];
  bool _isSearching = false;
  String _selectedFilter = 'All';

  void _findResources(AcademicEvent event) {
    setState(() {
      _isSearching = true;
    });

    // Simulate AI search through YouTube and web
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSearching = false;
        _resources.clear();
        _resources.addAll(_generateMockResources(event));
      });
    });
  }

  List<Map<String, dynamic>> _generateMockResources(AcademicEvent event) {
    final List<Map<String, dynamic>> resources = [];

    // Generate resources based on event type and description
    if (event.description.toLowerCase().contains('algorithm') ||
        event.description.toLowerCase().contains('data structure')) {
      resources.addAll([
        {
          'title': 'Data Structures and Algorithms Complete Course',
          'type': 'Video',
          'platform': 'YouTube',
          'duration': '4:32:15',
          'views': '2.1M views',
          'channel': 'FreeCodeCamp',
          'rating': 4.9,
          'thumbnail': 'https://i.ytimg.com/vi/RBSGKlAvoiM/maxresdefault.jpg',
          'url': 'youtube.com/watch?v=...',
        },
        {
          'title': 'Big O Notation Simplified',
          'type': 'Video',
          'platform': 'YouTube',
          'duration': '12:45',
          'views': '450K views',
          'channel': 'CS Dojo',
          'rating': 4.7,
          'thumbnail': '',
          'url': 'youtube.com/watch?v=...',
        },
      ]);
    }

    if (event.description.toLowerCase().contains('database') ||
        event.description.toLowerCase().contains('sql')) {
      resources.addAll([
        {
          'title': 'SQL Tutorial - Full Database Course for Beginners',
          'type': 'Video',
          'platform': 'YouTube',
          'duration': '4:20:44',
          'views': '5.2M views',
          'channel': 'FreeCodeCamp',
          'rating': 4.9,
          'thumbnail': '',
          'url': 'youtube.com/watch?v=...',
        },
        {
          'title': 'Database Normalization Explained',
          'type': 'Video',
          'platform': 'YouTube',
          'duration': '18:32',
          'views': '320K views',
          'channel': 'DatabaseStar',
          'rating': 4.6,
          'thumbnail': '',
          'url': 'youtube.com/watch?v=...',
        },
      ]);
    }

    if (event.description.toLowerCase().contains('software') ||
        event.description.toLowerCase().contains('design')) {
      resources.addAll([
        {
          'title': 'Software Design Patterns: Best Practices',
          'type': 'Video',
          'platform': 'YouTube',
          'duration': '1:45:30',
          'views': '890K views',
          'channel': 'Programming with Mosh',
          'rating': 4.8,
          'thumbnail': '',
          'url': 'youtube.com/watch?v=...',
        },
        {
          'title': 'SOLID Principles Explained with Examples',
          'type': 'Video',
          'platform': 'YouTube',
          'duration': '32:15',
          'views': '620K views',
          'channel': 'CodeAesthetic',
          'rating': 4.9,
          'thumbnail': '',
          'url': 'youtube.com/watch?v=...',
        },
      ]);
    }

    // Add some generic helpful resources
    resources.addAll([
      {
        'title': '${event.title} Study Guide',
        'type': 'Document',
        'platform': 'Web',
        'duration': 'PDF',
        'views': '12K downloads',
        'channel': 'Course Materials',
        'rating': 4.5,
        'thumbnail': '',
        'url': 'example.com/...',
      },
      {
        'title': 'Practice Problems and Solutions',
        'type': 'Interactive',
        'platform': 'Web',
        'duration': '50+ problems',
        'views': '8K users',
        'channel': 'LeetCode',
        'rating': 4.7,
        'thumbnail': '',
        'url': 'leetcode.com/...',
      },
      {
        'title': 'Quick Reference Cheat Sheet',
        'type': 'Document',
        'platform': 'Web',
        'duration': 'PDF',
        'views': '5K downloads',
        'channel': 'Cheat Sheets',
        'rating': 4.4,
        'thumbnail': '',
        'url': 'example.com/...',
      },
    ]);

    return resources;
  }

  List<Map<String, dynamic>> get filteredResources {
    if (_selectedFilter == 'All') return _resources;
    return _resources.where((r) => r['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as AcademicEvent?;

    if (event == null) {
      return _EventSelectionScreen(
        title: 'Resource Finder',
        subtitle: 'Select an event to find learning resources',
        routeName: '/resource-finder',
      );
    }

    // Auto-search on first load
    if (_resources.isEmpty && !_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _findResources(event);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Resource Finder'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.backgroundStart, AppConstants.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppConstants.accentColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.smart_display,
                                  color: AppConstants.accentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingM),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Instant Resource Finder',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'AI finds relevant videos & study materials',
                                      style: TextStyle(
                                        color: AppConstants.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Container(
                            padding: const EdgeInsets.all(
                              AppConstants.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  color: AppConstants.accentColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: AppConstants.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingS),
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppConstants.accentColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Powered by YouTube Data API & Gemini AI',
                              style: TextStyle(
                                color: AppConstants.accentColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_resources.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingM),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Video'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Document'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Interactive'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _isSearching
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppConstants.accentColor,
                            ),
                            SizedBox(height: AppConstants.spacingM),
                            Text(
                              'Searching YouTube and web for resources...',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredResources.isEmpty
                    ? const Center(
                        child: Text(
                          'No resources found',
                          style: TextStyle(color: AppConstants.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingL,
                        ),
                        itemCount: filteredResources.length,
                        itemBuilder: (context, index) {
                          return _buildResourceCard(filteredResources[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppConstants.accentColor, AppConstants.primaryColor],
                )
              : null,
          color: isSelected ? null : AppConstants.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppConstants.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final type = resource['type'] as String;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'Video':
        icon = Icons.play_circle_filled;
        iconColor = Colors.red;
        break;
      case 'Document':
        icon = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'Interactive':
        icon = Icons.code;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.link;
        iconColor = AppConstants.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        hasShadow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            resource['platform'] as String,
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Divider(color: AppConstants.glassBorder, height: 1),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppConstants.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  resource['channel'] as String,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  resource['rating'].toString(),
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppConstants.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  resource['duration'] as String,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                const Icon(
                  Icons.visibility,
                  color: AppConstants.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  resource['views'] as String,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening: ${resource['url']}'),
                          backgroundColor: AppConstants.successColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.accentColor,
                      side: const BorderSide(color: AppConstants.accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Resource saved to event!'),
                          backgroundColor: AppConstants.successColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_add, size: 16),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Event Selection Screen Widget
class _EventSelectionScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String routeName;

  const _EventSelectionScreen({
    required this.title,
    required this.subtitle,
    required this.routeName,
  });

  @override
  State<_EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<_EventSelectionScreen> {
  List<AcademicEvent> _allEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      // Import needed
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService.withPrefs(prefs);
      final courses = await storageService.getAllCourses();

      final List<AcademicEvent> events = [];
      for (var course in courses) {
        events.addAll(course.events);
      }

      // Sort by date (upcoming first)
      events.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.backgroundStart, AppConstants.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                )
              : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppConstants.errorColor,
                        size: 64,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'Error loading events',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _allEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy,
                        color: AppConstants.textSecondary,
                        size: 64,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      const Text(
                        'No Events Found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      const Text(
                        'Upload a syllabus to get started',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/upload');
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Syllabus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingL,
                            vertical: AppConstants.spacingM,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            '${_allEvents.length} ${_allEvents.length == 1 ? 'event' : 'events'} available',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingL,
                        ),
                        itemCount: _allEvents.length,
                        itemBuilder: (context, index) {
                          final event = _allEvents[index];
                          return _buildEventCard(event);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEventCard(AcademicEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(
          context,
          widget.routeName,
          arguments: event,
        );
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getEventColor(event).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventIcon(event),
                  color: _getEventColor(event),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.type.displayName,
                      style: TextStyle(
                        color: _getEventColor(event),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppConstants.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.dueDate),
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (event.weightage != null) ...[
                          const SizedBox(width: AppConstants.spacingM),
                          Icon(
                            Icons.show_chart,
                            size: 12,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.weightage}%',
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppConstants.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor(AcademicEvent event) {
    switch (event.priority) {
      case EventPriority.high:
        return AppConstants.errorColor;
      case EventPriority.medium:
        return AppConstants.warningColor;
      default:
        return AppConstants.successColor;
    }
  }

  IconData _getEventIcon(AcademicEvent event) {
    final type = event.type.name.toLowerCase();
    if (type.contains('exam')) return Icons.edit_note;
    if (type.contains('assignment')) return Icons.assignment;
    if (type.contains('quiz')) return Icons.quiz;
    if (type.contains('project')) return Icons.work;
    if (type.contains('lab')) return Icons.science;
    return Icons.event;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
