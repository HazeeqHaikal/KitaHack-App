import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:due/models/course_info.dart';
import 'package:due/services/group_sync_service.dart';
import 'package:due/services/storage_service.dart';
import 'package:due/services/firebase_service.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class GroupSyncScreen extends StatefulWidget {
  const GroupSyncScreen({super.key});

  @override
  State<GroupSyncScreen> createState() => _GroupSyncScreenState();
}

class _GroupSyncScreenState extends State<GroupSyncScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ─────────────────────────────────────────────────────────────
  final _groupSyncService = GroupSyncService();
  final _storageService = StorageService();
  final _firebaseService = FirebaseService();

  // ── Tab Controller ────────────────────────────────────────────────────────
  late final TabController _tabController;

  // ── Share section state ───────────────────────────────────────────────────
  List<CourseInfo> _savedCourses = [];
  CourseInfo? _selectedCourse;
  bool _loadingCourses = true;
  String? _generatedCode;
  bool _isGeneratingCode = false;
  List<GroupCourseEntry> _myCodes = [];
  bool _loadingMyCodes = false;

  // ── Join section state ────────────────────────────────────────────────────
  final _codeController = TextEditingController();
  bool _isJoining = false;
  CourseInfo? _joinedCourse;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedCourses();
    _loadMyCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadSavedCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final courses = await _storageService.getAllCourses();
      if (mounted) setState(() => _savedCourses = courses);
    } catch (e) {
      _showError('Could not load saved courses: $e');
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadMyCodes() async {
    if (!_groupSyncService.isAvailable) return;
    setState(() => _loadingMyCodes = true);
    try {
      final codes = await _groupSyncService.getMyCreatedCodes();
      if (mounted) setState(() => _myCodes = codes);
    } catch (e) {
      print('Load my codes error: $e');
    } finally {
      if (mounted) setState(() => _loadingMyCodes = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _generateCode() async {
    if (_selectedCourse == null) {
      _showError('Please select a course first');
      return;
    }
    if (!_assertFirebase()) return;

    setState(() {
      _isGeneratingCode = true;
      _generatedCode = null;
    });

    try {
      final code = await _groupSyncService.createGroupCode(_selectedCourse!);
      if (!mounted) return;
      setState(() => _generatedCode = code);
      await _loadMyCodes();
      _showSuccess('Code generated! Share it with your classmates 🎉');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGeneratingCode = false);
    }
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showError('Please enter a course code');
      return;
    }
    if (code.length != 6) {
      _showError('Course code must be exactly 6 characters');
      return;
    }
    if (!_assertFirebase()) return;

    setState(() {
      _isJoining = true;
      _joinedCourse = null;
    });

    try {
      final course = await _groupSyncService.joinWithCode(code);
      await _storageService.saveCourse(course);

      if (!mounted) return;
      setState(() {
        _joinedCourse = course;
        _codeController.clear();
      });
      _showSuccess(
        '✅ Joined "${course.courseName}" – ${course.events.length} events added!',
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _deactivateCode(GroupCourseEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Deactivate Code?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Code "${entry.code}" will no longer be usable by classmates.',
          style: const TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _groupSyncService.deactivateCode(entry.code);
      await _loadMyCodes();
      if (mounted) _showSuccess('Code ${entry.code} deactivated');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Guards ────────────────────────────────────────────────────────────────

  bool _assertFirebase() {
    if (!_groupSyncService.isAvailable) {
      _showError(
        'Firebase is required for Group Sync. Please sign in and try again.',
      );
      return false;
    }
    if (_firebaseService.currentUser == null) {
      _showError('Please sign in to use Group Sync.');
      return false;
    }
    return true;
  }

  // ── Feedback helpers ──────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(
    String msg, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('📋 Copied to clipboard');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Group Sync'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: AppConstants.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Share Course'),
            Tab(icon: Icon(Icons.group_add), text: 'Join Course'),
          ],
        ),
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
          child: TabBarView(
            controller: _tabController,
            children: [_buildShareTab(), _buildJoinTab()],
          ),
        ),
      ),
    );
  }

  // ── Share Tab ─────────────────────────────────────────────────────────────

  Widget _buildShareTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadSavedCourses();
        await _loadMyCodes();
      },
      color: AppConstants.primaryColor,
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        children: [
          if (!_groupSyncService.isAvailable ||
              _firebaseService.currentUser == null) ...[
            _buildWarningBanner(),
            const SizedBox(height: AppConstants.spacingL),
          ],

          // Step 1 — select course
          _buildSectionHeader(
            icon: Icons.menu_book,
            color: AppConstants.primaryColor,
            title: 'Step 1 – Select Course to Share',
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildCourseSelector(),
          const SizedBox(height: AppConstants.spacingXL),

          // Step 2 — generate code
          _buildSectionHeader(
            icon: Icons.qr_code,
            color: AppConstants.secondaryColor,
            title: 'Step 2 – Generate Shareable Code',
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildGenerateSection(),
          const SizedBox(height: AppConstants.spacingXL),

          // Previously created codes
          if (_myCodes.isNotEmpty || _loadingMyCodes) ...[
            _buildSectionHeader(
              icon: Icons.history,
              color: AppConstants.accentColor,
              title: 'My Shared Codes',
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildMyCodesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    final notSignedIn = _firebaseService.currentUser == null;
    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: AppConstants.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.warningColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              notSignedIn ? Icons.person_off : Icons.cloud_off,
              color: AppConstants.warningColor,
              size: 22,
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Text(
                notSignedIn
                    ? 'Sign in to create or join group codes. Guest mode is not supported for this feature.'
                    : 'Firebase not available. Group Sync requires an internet connection.',
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: AppConstants.spacingS),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSelector() {
    if (_loadingCourses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingL),
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        ),
      );
    }

    if (_savedCourses.isEmpty) {
      return GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              const Icon(
                Icons.inbox_outlined,
                color: AppConstants.textSecondary,
                size: 40,
              ),
              const SizedBox(height: AppConstants.spacingM),
              const Text(
                'No saved courses found',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              const Text(
                'Upload a syllabus first, then come back to share it with your class.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Go Upload Syllabus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  side: const BorderSide(color: AppConstants.primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          children: _savedCourses
              .map(
                (course) => _CourseSelectTile(
                  course: course,
                  isSelected:
                      _selectedCourse?.courseCode == course.courseCode &&
                      _selectedCourse?.courseName == course.courseName,
                  onTap: () => setState(() => _selectedCourse = course),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildGenerateSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show generated code
            if (_generatedCode != null) ...[
              _buildCodeDisplay(_generatedCode!, AppConstants.successColor),
              const SizedBox(height: AppConstants.spacingL),
            ],

            // Selected course preview
            if (_selectedCourse != null && _generatedCode == null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppConstants.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        'Ready to share: ${_selectedCourse!.courseName}',
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],

            ElevatedButton.icon(
              onPressed: (_isGeneratingCode || _selectedCourse == null)
                  ? null
                  : _generateCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppConstants.primaryColor.withOpacity(
                  0.3,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isGeneratingCode
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _generatedCode != null
                          ? Icons.refresh
                          : Icons.generating_tokens,
                    ),
              label: Text(
                _isGeneratingCode
                    ? 'Generating…'
                    : _generatedCode != null
                    ? 'Generate New Code'
                    : 'Generate Code',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (_selectedCourse == null) ...[
              const SizedBox(height: AppConstants.spacingS),
              const Text(
                'Select a course above to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCodeDisplay(String code, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            'Share this code with your classmates',
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              IconButton(
                onPressed: () => _copyToClipboard(code),
                icon: const Icon(Icons.copy),
                color: color,
                tooltip: 'Copy code',
              ),
            ],
          ),
          Text(
            'Valid for 30 days',
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCodesList() {
    if (_loadingMyCodes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingL),
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        ),
      );
    }
    return Column(children: _myCodes.map(_buildCodeTile).toList());
  }

  Widget _buildCodeTile(GroupCourseEntry entry) {
    final Color statusColor = !entry.isActive
        ? AppConstants.textSecondary
        : entry.isExpired
        ? AppConstants.errorColor
        : AppConstants.successColor;

    final String statusLabel = !entry.isActive
        ? 'Deactivated'
        : entry.isExpired
        ? 'Expired'
        : '${entry.daysRemaining}d left';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              // Code badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  entry.code,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.courseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.people, color: statusColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.joinCount} joined  •  $statusLabel',
                          style: TextStyle(color: statusColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (entry.isValid)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      color: AppConstants.primaryColor,
                      tooltip: 'Copy code',
                      onPressed: () => _copyToClipboard(entry.code),
                    ),
                    IconButton(
                      icon: const Icon(Icons.block, size: 18),
                      color: AppConstants.errorColor,
                      tooltip: 'Deactivate',
                      onPressed: () => _deactivateCode(entry),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Join Tab ──────────────────────────────────────────────────────────────

  Widget _buildJoinTab() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      children: [
        if (!_groupSyncService.isAvailable ||
            _firebaseService.currentUser == null) ...[
          _buildWarningBanner(),
          const SizedBox(height: AppConstants.spacingL),
        ],

        _buildHowItWorks(),
        const SizedBox(height: AppConstants.spacingXL),

        _buildSectionHeader(
          icon: Icons.vpn_key,
          color: AppConstants.accentColor,
          title: 'Enter Course Code',
        ),
        const SizedBox(height: AppConstants.spacingM),

        GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: const TextStyle(
                      color: AppConstants.textSecondary,
                      letterSpacing: 4,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppConstants.accentColor,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.tag,
                      color: AppConstants.accentColor,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _joinWithCode(),
                ),
                const SizedBox(height: AppConstants.spacingL),
                ElevatedButton.icon(
                  onPressed: _isJoining ? null : _joinWithCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppConstants.accentColor
                        .withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _isJoining ? 'Joining…' : 'Join Course',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Result card after successful join
        if (_joinedCourse != null) ...[
          const SizedBox(height: AppConstants.spacingL),
          _buildJoinedCourseCard(_joinedCourse!),
        ],
      ],
    );
  }

  Widget _buildJoinedCourseCard(CourseInfo course) {
    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        decoration: BoxDecoration(
          color: AppConstants.successColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.successColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.check_circle,
                  color: AppConstants.successColor,
                  size: 22,
                ),
                SizedBox(width: AppConstants.spacingS),
                Text(
                  'Course Joined Successfully!',
                  style: TextStyle(
                    color: AppConstants.successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            _infoRow(Icons.book, 'Course', course.courseName),
            if (course.courseCode.isNotEmpty)
              _infoRow(Icons.code, 'Course Code', course.courseCode),
            if (course.instructor != null)
              _infoRow(Icons.person, 'Instructor', course.instructor!),
            _infoRow(
              Icons.event,
              'Events Added',
              '${course.events.length} events added to your courses',
            ),
            const SizedBox(height: AppConstants.spacingM),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.successColor,
                side: const BorderSide(color: AppConstants.successColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.textSecondary, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How Group Sync Works',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildStep(
              '1',
              AppConstants.primaryColor,
              'Class rep uploads syllabus',
              'One upload generates a shareable 6-character code',
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildStep(
              '2',
              AppConstants.secondaryColor,
              'Share the code',
              'Via WhatsApp, Telegram, or any messaging app',
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildStep(
              '3',
              AppConstants.accentColor,
              'Everyone joins instantly',
              'Enter the code – all events sync to your account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, Color color, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Course Select Tile widget ─────────────────────────────────────────────────

class _CourseSelectTile extends StatelessWidget {
  final CourseInfo course;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourseSelectTile({
    required this.course,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: AppConstants.animationDurationShort,
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor.withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.6)
                  : Colors.white.withOpacity(0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (course.courseCode.isNotEmpty ||
                        course.events.isNotEmpty)
                      Text(
                        [
                          if (course.courseCode.isNotEmpty) course.courseCode,
                          '${course.events.length} events',
                        ].join('  •  '),
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
