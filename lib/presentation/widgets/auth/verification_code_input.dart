import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// 6-digit verification code input widget
class VerificationCodeInput extends StatefulWidget {
  final int codeLength;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;
  final bool enabled;
  final bool hasError;

  const VerificationCodeInput({
    super.key,
    this.codeLength = 6,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.codeLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.codeLength,
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code {
    return _controllers.map((c) => c.text).join();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final pastedCode = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (pastedCode.length >= widget.codeLength) {
        for (int i = 0; i < widget.codeLength; i++) {
          _controllers[i].text = pastedCode[i];
        }
        _focusNodes.last.requestFocus();
        widget.onChanged?.call(_code);
        if (_code.length == widget.codeLength) {
          widget.onCompleted(_code);
        }
        return;
      }
    }

    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    widget.onChanged?.call(_code);

    if (_code.length == widget.codeLength) {
      widget.onCompleted(_code);
    }
  }

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.codeLength, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: Focus(
            skipTraversal: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_controllers[index].text.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                  _controllers[index - 1].clear();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              enabled: widget.enabled,
              autofocus: index == 0,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: widget.hasError
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.hasError
                        ? AppColors.error
                        : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.hasError
                        ? AppColors.error
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.hasError
                        ? AppColors.error
                        : AppColors.primaryOrange,
                    width: 2,
                  ),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) => _onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
