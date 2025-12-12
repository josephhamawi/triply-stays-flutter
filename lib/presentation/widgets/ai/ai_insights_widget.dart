/// AI Insights Widget
///
/// Displays booking probability predictions and recommendations
/// for hosts based on conversation analytics (Phase 1: GuestIntent AI)

import 'package:flutter/material.dart';
import '../../../core/utils/conversation_analytics.dart';

/// Recommendation model
class AIRecommendation {
  final IconData icon;
  final String text;
  final String priority; // 'high', 'medium', 'low'

  AIRecommendation({
    required this.icon,
    required this.text,
    required this.priority,
  });
}

/// Probability level with color and label
class ProbabilityLevel {
  final String level;
  final Color color;
  final String label;

  ProbabilityLevel({
    required this.level,
    required this.color,
    required this.label,
  });
}

class AIInsightsWidget extends StatefulWidget {
  final String chatId;
  final bool isHost;
  final bool compact;

  const AIInsightsWidget({
    super.key,
    required this.chatId,
    required this.isHost,
    this.compact = false,
  });

  @override
  State<AIInsightsWidget> createState() => _AIInsightsWidgetState();
}

class _AIInsightsWidgetState extends State<AIInsightsWidget> {
  final ConversationAnalyticsService _analyticsService = ConversationAnalyticsService();

  ConversationAnalytics? _analytics;
  double _bookingProbability = 0;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  @override
  void didUpdateWidget(AIInsightsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await _analyticsService.getConversationAnalytics(widget.chatId);
      if (data != null) {
        final probability = await _analyticsService.getBookingProbability(widget.chatId);
        setState(() {
          _analytics = data;
          _bookingProbability = probability;
        });
      }
    } catch (error) {
      debugPrint('Error loading AI insights: $error');
    }
  }

  ProbabilityLevel _getProbabilityLevel() {
    if (_bookingProbability >= 0.7) {
      return ProbabilityLevel(
        level: 'high',
        color: const Color(0xFFFB8500),
        label: 'High',
      );
    }
    if (_bookingProbability >= 0.4) {
      return ProbabilityLevel(
        level: 'medium',
        color: const Color(0xFFF59E0B),
        label: 'Medium',
      );
    }
    return ProbabilityLevel(
      level: 'low',
      color: const Color(0xFF6B7280),
      label: 'Low',
    );
  }

  List<AIRecommendation> _getRecommendations() {
    final recommendations = <AIRecommendation>[];
    final metrics = _analytics?.conversationMetrics;
    if (metrics == null) return recommendations;

    final intentScore = metrics.highestIntentScore;

    // Fast response recommendation
    final avgHostResponse = metrics.avgResponseTime['host'] ?? 0;
    if (avgHostResponse > 600) {
      recommendations.add(AIRecommendation(
        icon: Icons.access_time,
        text: 'Try to respond within 5-10 minutes to increase booking chances',
        priority: 'high',
      ));
    }

    // Intent signal recommendations
    if (intentScore > 0.5) {
      if (!metrics.topicsDiscussed.contains('price')) {
        recommendations.add(AIRecommendation(
          icon: Icons.message,
          text: 'Guest shows high interest! Consider offering pricing details',
          priority: 'high',
        ));
      }

      if (!metrics.topicsDiscussed.contains('availability')) {
        recommendations.add(AIRecommendation(
          icon: Icons.message,
          text: 'Confirm availability for their dates to move toward booking',
          priority: 'high',
        ));
      }
    }

    // Engagement recommendations
    if (metrics.totalMessages < 5) {
      recommendations.add(AIRecommendation(
        icon: Icons.chat_bubble_outline,
        text: 'Ask questions about their trip to better understand their needs',
        priority: 'medium',
      ));
    }

    // High probability recommendations
    if (_bookingProbability >= 0.7) {
      recommendations.add(AIRecommendation(
        icon: Icons.check_circle_outline,
        text: 'Strong booking signals detected! Send the booking link',
        priority: 'high',
      ));
    }

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    // Don't show insights if no data or if already booked
    if (_analytics == null || _analytics!.outcome['resultedInBooking'] == true) {
      return const SizedBox.shrink();
    }

    // Don't show to guests (only hosts get insights in Phase 1)
    if (!widget.isHost) {
      return const SizedBox.shrink();
    }

    final probabilityLevel = _getProbabilityLevel();
    final metrics = _analytics!.conversationMetrics;
    final intentScore = metrics.highestIntentScore;
    final recommendations = _getRecommendations();

    // Compact view for embedded display
    if (widget.compact) {
      return _buildCompactView(probabilityLevel);
    }

    // Full insights panel
    return _buildFullPanel(probabilityLevel, metrics, intentScore, recommendations);
  }

  Widget _buildCompactView(ProbabilityLevel probabilityLevel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                Icons.psychology,
                size: 16,
                color: probabilityLevel.color,
              ),
              const SizedBox(width: 6),
              Text(
                '${(_bookingProbability * 100).round()}% Booking Likelihood',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: probabilityLevel.color,
                ),
              ),
            ],
          ),
          if (_bookingProbability >= 0.5) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFB8500).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '💡 High interest detected - respond quickly!',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullPanel(
    ProbabilityLevel probabilityLevel,
    ConversationMetrics metrics,
    double intentScore,
    List<AIRecommendation> recommendations,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6),
                    const Color(0xFFA855F7),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _expanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Insights (Beta)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_bookingProbability * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Probability
                  _buildProbabilitySection(probabilityLevel),
                  const SizedBox(height: 20),

                  // Key Signals
                  _buildSignalsSection(metrics, intentScore),
                  const SizedBox(height: 20),

                  // Recommendations
                  if (recommendations.isNotEmpty) ...[
                    _buildRecommendationsSection(recommendations),
                    const SizedBox(height: 20),
                  ],

                  // Topics Discussed
                  if (metrics.topicsDiscussed.isNotEmpty)
                    _buildTopicsSection(metrics.topicsDiscussed),

                  // Beta Notice
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Beta feature - predictions based on conversation patterns',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProbabilitySection(ProbabilityLevel probabilityLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 18,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Booking Probability',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _bookingProbability,
            child: Container(
              decoration: BoxDecoration(
                color: probabilityLevel.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${probabilityLevel.label} Likelihood',
              style: TextStyle(
                color: probabilityLevel.color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              '${(_bookingProbability * 100).round()}%',
              style: TextStyle(
                color: probabilityLevel.color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignalsSection(ConversationMetrics metrics, double intentScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Signals',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [
            _buildSignalItem('Intent Score', '${(intentScore * 100).round()}%'),
            _buildSignalItem('Messages', '${metrics.totalMessages}'),
            _buildSignalItem(
              'Sentiment',
              metrics.sentimentTrend,
              color: metrics.sentimentTrend == 'positive'
                  ? const Color(0xFFFB8500)
                  : metrics.sentimentTrend == 'negative'
                      ? Colors.red
                      : Colors.grey,
            ),
            _buildSignalItem(
              'Avg Response',
              metrics.avgResponseTime['host'] != null && metrics.avgResponseTime['host']! > 0
                  ? '${(metrics.avgResponseTime['host']! / 60).round()}m'
                  : 'N/A',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignalItem(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(List<AIRecommendation> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),

        ...recommendations.map((rec) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rec.priority == 'high'
                ? const Color(0xFFFB8500).withOpacity(0.1)
                : rec.priority == 'medium'
                    ? Colors.amber.withOpacity(0.1)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: rec.priority == 'high'
                  ? const Color(0xFFFB8500).withOpacity(0.3)
                  : rec.priority == 'medium'
                      ? Colors.amber.withOpacity(0.3)
                      : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                rec.icon,
                size: 16,
                color: rec.priority == 'high'
                    ? const Color(0xFFFB8500)
                    : rec.priority == 'medium'
                        ? Colors.amber.shade700
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rec.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTopicsSection(List<String> topics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topics Discussed',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((topic) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              topic,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
