import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/host_pro_status.dart';
import '../../providers/host_pro/host_pro_provider.dart';

/// Screen showing user's progress toward HostPro Elite status
class HostProScreen extends ConsumerWidget {
  const HostProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostProAsync = ref.watch(hostProNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('HostPro Elite'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: hostProAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load status', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(hostProNotifierProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (status) => RefreshIndicator(
          onRefresh: () => ref.read(hostProNotifierProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status card
                _buildStatusCard(status),
                const SizedBox(height: 24),
                // Overall progress
                _buildOverallProgress(status),
                const SizedBox(height: 24),
                // Requirements list
                _buildRequirementsList(status),
                const SizedBox(height: 24),
                // Benefits section
                _buildBenefitsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(HostProStatus status) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: status.isHostProElite
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [AppColors.primaryOrange.withOpacity(0.8), AppColors.primaryOrange],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (status.isHostProElite ? const Color(0xFFFFD700) : AppColors.primaryOrange)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status.isHostProElite ? Icons.workspace_premium : Icons.star_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            status.isHostProElite ? 'HostPro Elite' : 'Working Towards Elite',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status.isHostProElite
                ? 'Congratulations! You\'ve achieved HostPro Elite status.'
                : 'Complete the requirements below to become a HostPro Elite.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(HostProStatus status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${status.requirementsMet}/${status.totalRequirements}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: status.isHostProElite ? const Color(0xFFFFD700) : AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress ring
          SizedBox(
            height: 120,
            width: 120,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: status.overallProgress,
                color: status.isHostProElite ? const Color(0xFFFFD700) : AppColors.primaryOrange,
              ),
              child: Center(
                child: Text(
                  '${(status.overallProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: status.isHostProElite ? const Color(0xFFFFD700) : AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsList(HostProStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildRequirementCard(
          icon: Icons.star,
          title: 'Average Rating',
          subtitle: 'Minimum 4.5 stars',
          current: status.averageRating.toStringAsFixed(1),
          required: '4.5',
          unit: 'stars',
          progress: status.ratingRequirement.progress,
          isMet: status.ratingRequirement.met,
        ),
        const SizedBox(height: 12),
        _buildRequirementCard(
          icon: Icons.rate_review,
          title: 'Number of Reviews',
          subtitle: 'Minimum 3 reviews',
          current: status.reviewCount.toString(),
          required: '3',
          unit: 'reviews',
          progress: status.reviewCountRequirement.progress,
          isMet: status.reviewCountRequirement.met,
        ),
        const SizedBox(height: 12),
        _buildRequirementCard(
          icon: Icons.chat,
          title: 'Response Rate',
          subtitle: 'Minimum 90%',
          current: '${status.responseRate}',
          required: '90',
          unit: '%',
          progress: status.responseRateRequirement.progress,
          isMet: status.responseRateRequirement.met,
        ),
        const SizedBox(height: 12),
        _buildRequirementCard(
          icon: Icons.calendar_today,
          title: 'Account Age',
          subtitle: 'Minimum 90 days',
          current: status.accountAgeDays is String
              ? status.accountAgeDays
              : '${status.accountAgeDays}',
          required: '90',
          unit: status.accountAgeDays is String ? '' : 'days',
          progress: status.accountAgeRequirement.progress,
          isMet: status.accountAgeRequirement.met,
          isGrandfathered: status.accountAgeDays is String,
        ),
      ],
    );
  }

  Widget _buildRequirementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String current,
    required String required,
    required String unit,
    required double progress,
    required bool isMet,
    bool isGrandfathered = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMet
            ? Border.all(color: AppColors.success.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isMet
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isMet ? AppColors.success : AppColors.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isMet) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                if (!isGrandfathered) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation(
                        isMet ? AppColors.success : AppColors.primaryOrange,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isGrandfathered ? current : '$current$unit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isMet ? AppColors.success : AppColors.primaryOrange,
                ),
              ),
              if (!isGrandfathered)
                Text(
                  'of $required$unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: const Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Elite Benefits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.badge,
            'Elite Badge',
            'Stand out with a special badge on your listings',
          ),
          _buildBenefitItem(
            Icons.trending_up,
            'Priority Placement',
            'Your listings appear higher in search results',
          ),
          _buildBenefitItem(
            Icons.verified,
            'Trusted Status',
            'Build trust with guests through verified status',
          ),
          _buildBenefitItem(
            Icons.support_agent,
            'Priority Support',
            'Get faster responses from our support team',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

/// Custom painter for progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 12.0;

    // Background ring
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
