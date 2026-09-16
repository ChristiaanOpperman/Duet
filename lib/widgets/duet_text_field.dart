import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Text input styled for the dark backdrop. Used for names, answers and
/// guesses, so it keeps a generous tap target and a visible focus ring.
class DuetTextField extends StatelessWidget {
  const DuetTextField({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.maxLength,
    this.large = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final String? hint;
  final String? label;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final int? maxLength;
  final bool large;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.textTheme.labelMedium),
          const SizedBox(height: Insets.s),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLength: maxLength,
          textAlign: large ? TextAlign.center : TextAlign.start,
          style: large
              ? theme.textTheme.headlineSmall
              : theme.textTheme.titleMedium,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: (large
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.titleMedium)
                ?.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceSunken,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Insets.l,
              vertical: large ? Insets.l : 18,
            ),
            border: _border(AppColors.hairline),
            enabledBorder: _border(AppColors.hairline),
            focusedBorder: _border(AppColors.magenta, width: 2),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color colour, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.field),
      borderSide: BorderSide(color: colour, width: width),
    );
  }
}
