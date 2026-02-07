import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/models/course_info.dart';
import 'package:due/services/storage_service.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final StorageService _storageService = StorageService();
  List<CourseInfo> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _storageService.getAllCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Select Course'),
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
                    color: AppConstants.secondaryColor,
                  ),
                )
              : _courses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return _buildCourseCard(context, course);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_outlined,
                size: 80,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(height: AppConstants.spacingL),
              const Text(
                'No Courses Yet',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              const Text(
                'Start by uploading a course syllabus to automatically extract deadlines and events.',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Syllabus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL * 2,
                    vertical: AppConstants.spacingM,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseInfo course) {
    final upcomingCount = course.upcomingEvents.length;
    final highPriorityCount = course.highPriorityEvents.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassContainer(
        hasShadow: true,
        child: InkWell(
          onTap: () {
            // Navigate to result screen with course data
            Navigator.pushNamed(
              context,
              '/result',
              arguments: {'courseCode': course.courseCode},
            );
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingS),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppConstants.primaryColor,
                            AppConstants.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.courseCode,
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            course.courseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppConstants.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      course.instructor ?? 'N/A',
                      style: const TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    const Icon(
                      Icons.calendar_month,
                      size: 14,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      course.semester ?? 'N/A',
                      style: const TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                const Divider(color: AppConstants.glassBorder, height: 1),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCourseStatItem(
                      icon: Icons.event,
                      label: 'Total',
                      value: course.totalEvents.toString(),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppConstants.glassBorder,
                    ),
                    _buildCourseStatItem(
                      icon: Icons.upcoming,
                      label: 'Upcoming',
                      value: upcomingCount.toString(),
                      color: AppConstants.successColor,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppConstants.glassBorder,
                    ),
                    _buildCourseStatItem(
                      icon: Icons.priority_high,
                      label: 'Priority',
                      value: highPriorityCount.toString(),
                      color: AppConstants.errorColor,
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

  Widget _buildCourseStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppConstants.textSecondary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
