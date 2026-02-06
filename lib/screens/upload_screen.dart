import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/info_banner.dart';
import 'package:due/widgets/glass_container.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  String? _fileName;
  String? _fileType;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationDurationMedium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _pickFile() async {
    // TODO: Implement file picker
    setState(() {
      _fileName = 'COMP101_Course_Outline_2026.pdf';
      _fileType = 'pdf';
    });
  }

  void _pickFromCamera() async {
    // TODO: Implement camera picker
    setState(() {
      _fileName = 'syllabus_photo.jpg';
      _fileType = 'image';
    });
  }

  void _removeFile() {
    setState(() {
      _fileName = null;
      _fileType = null;
    });
  }

  void _processFile() async {
    if (_fileName == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulate processing with Gemini API
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      Navigator.pushNamed(context, '/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Upload Syllabus'),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  _buildHeaderSection(),
                  const SizedBox(height: AppConstants.spacingXL),
                  // Info banner
                  const InfoBanner(
                    message:
                        'We support PDF documents and image files (JPG, PNG). Maximum file size: 10MB',
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  // Upload options
                  if (_fileName == null) ...[
                    _buildUploadOptions(),
                  ] else ...[
                    _buildFilePreview(),
                    const SizedBox(height: AppConstants.spacingL),
                    _buildProcessButton(),
                  ],
                  const SizedBox(height: AppConstants.spacingXL),
                  // Features info
                  _buildFeaturesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: 60,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          'Upload Your Course Outline',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          'Select a file from your device or take a photo',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUploadOptions() {
    return Column(
      children: [
        // Upload from files
        _buildUploadOptionCard(
          icon: Icons.folder_open,
          title: 'Choose from Files',
          description: 'Browse PDF or image files',
          color: AppConstants.primaryColor,
          onTap: _pickFile,
        ),
        const SizedBox(height: AppConstants.spacingM),
        // Upload from camera
        _buildUploadOptionCard(
          icon: Icons.camera_alt,
          title: 'Take a Photo',
          description: 'Capture syllabus with camera',
          color: AppConstants.secondaryColor,
          onTap: _pickFromCamera,
        ),
      ],
    );
  }

  Widget _buildUploadOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      borderColor: color.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppConstants.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      borderColor: AppConstants.primaryColor.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected File',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppConstants.textSecondary,
                ),
                onPressed: _removeFile,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: _fileType == 'pdf'
                      ? AppConstants.errorColor.withOpacity(0.2)
                      : AppConstants.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusS,
                  ),
                ),
                child: Icon(
                  _fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                  color: _fileType == 'pdf'
                      ? AppConstants.errorColor
                      : AppConstants.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      _fileType == 'pdf' ? 'PDF Document' : 'Image File',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton() {
    return PrimaryButton(
      text: 'Analyze with AI',
      icon: Icons.auto_awesome,
      onPressed: _isProcessing ? null : _processFile,
      isLoading: _isProcessing,
      backgroundColor: AppConstants.successColor,
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What happens next?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildFeatureItem(
          icon: Icons.psychology,
          title: 'AI Analysis',
          description: 'Google Gemini extracts all dates and events',
        ),
        _buildFeatureItem(
          icon: Icons.check_circle_outline,
          title: 'Review & Edit',
          description: 'Verify extracted information before syncing',
        ),
        _buildFeatureItem(
          icon: Icons.sync,
          title: 'Auto Sync',
          description: 'Events are added to your Google Calendar',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 20),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
