import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Smart search bar for natural language queries
class AISearchBar extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final bool isLoading;

  const AISearchBar({
    super.key,
    this.initialValue,
    required this.onSearch,
    this.onClear,
    this.isLoading = false,
  });

  @override
  State<AISearchBar> createState() => _AISearchBarState();
}

class _AISearchBarState extends State<AISearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query);
      _focusNode.unfocus();
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.auto_awesome,
            color: AppColors.primaryOrange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Try "Beach villa with pool under \$150"',
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          if (_controller.text.isNotEmpty && !widget.isLoading)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: AppColors.textLight,
                size: 20,
              ),
              onPressed: _handleClear,
            ),
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _handleSubmit,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
