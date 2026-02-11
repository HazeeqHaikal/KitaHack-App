import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class GroupSyncScreen extends StatefulWidget {
  const GroupSyncScreen({super.key});

  @override
  State<GroupSyncScreen> createState() => _GroupSyncScreenState();
}

class _GroupSyncScreenState extends State<GroupSyncScreen> {
  final _codeController = TextEditingController();
  bool _isCreatingCode = false;
  String? _generatedCode;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Group Sync'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mock Feature Banner
                GlassContainer(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.construction,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '🚧 Mock Feature (Phase 3)',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'UI complete - backend implementation pending',
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
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),

                // Create Course Code Section
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.upload_file,
                              color: AppConstants.primaryColor,
                              size: 28,
                            ),
                            SizedBox(width: AppConstants.spacingM),
                            Expanded(
                              child: Text(
                                'Create Course Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        const Text(
                          'As a class representative, upload your syllabus once and share the course code with your classmates.',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingL),
                        if (_generatedCode != null) ...[
                          Container(
                            padding: const EdgeInsets.all(
                              AppConstants.spacingM,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppConstants.successColor.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Your Course Code',
                                  style: TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _generatedCode!,
                                      style: const TextStyle(
                                        color: AppConstants.successColor,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppConstants.spacingM,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      color: AppConstants.successColor,
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: _generatedCode!),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✅ Code copied to clipboard',
                                            ),
                                            backgroundColor:
                                                AppConstants.successColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Share this code with your classmates',
                                  style: TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                        ],
                        ElevatedButton.icon(
                          onPressed: _isCreatingCode ? null : _mockGenerateCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isCreatingCode
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_circle),
                          label: Text(
                            _isCreatingCode
                                ? 'Generating...'
                                : 'Upload Syllabus & Generate Code',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),

                // Join with Code Section
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.group_add,
                              color: AppConstants.accentColor,
                              size: 28,
                            ),
                            SizedBox(width: AppConstants.spacingM),
                            Expanded(
                              child: Text(
                                'Join with Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        const Text(
                          'Enter the course code shared by your class representative to sync events instantly.',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingL),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit code',
                            hintStyle: const TextStyle(
                              color: AppConstants.textSecondary,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
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
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        ElevatedButton.icon(
                          onPressed: _mockJoinWithCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.accentColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text(
                            'Join Course',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),

                // How It Works
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How It Works',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        _buildStep(
                          '1',
                          'Class Rep Uploads',
                          'One person uploads the syllabus and generates a shareable code',
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        _buildStep(
                          '2',
                          'Share the Code',
                          'Share the 6-digit code via WhatsApp, Telegram, or any messaging app',
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        _buildStep(
                          '3',
                          'Everyone Syncs',
                          'Classmates enter the code and get all events instantly - no re-upload needed!',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppConstants.primaryColor, width: 2),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
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

  void _mockGenerateCode() async {
    setState(() {
      _isCreatingCode = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Generate random 6-character code
    final code = _generateRandomCode();

    setState(() {
      _generatedCode = code;
      _isCreatingCode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Course code generated! Share with your classmates'),
        backgroundColor: AppConstants.successColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _mockJoinWithCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a course code'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course code must be 6 characters'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      ),
    );

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading

    // Mock success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Joined course with code: $code\n12 events synced to your account',
        ),
        backgroundColor: AppConstants.successColor,
        duration: const Duration(seconds: 4),
      ),
    );

    _codeController.clear();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid confusing chars
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var seed = random;

    for (var i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      code += chars[seed % chars.length];
    }

    return code;
  }
}
