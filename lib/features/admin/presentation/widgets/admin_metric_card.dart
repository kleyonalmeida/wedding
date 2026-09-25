import 'package:flutter/material.dart';

class AdminMetricCard extends StatefulWidget {
  final String label;
  final String value;
  final String? suffixText;
  final IconData icon;
  final Color iconColor;
  final double? progress;
  final Color? progressColor;
  final String? progressLabel;
  final String? progressValue;

  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.suffixText,
    required this.icon,
    this.iconColor = const Color(0xFF6D5B4C), // primary
    this.progress,
    this.progressColor,
    this.progressLabel,
    this.progressValue,
  });

  @override
  State<AdminMetricCard> createState() => _AdminMetricCardState();
}

class _AdminMetricCardState extends State<AdminMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 12 : 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, size: 26, color: widget.iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              widget.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.value,
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 40),
                ),
                if (widget.suffixText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.suffixText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.progressColor ?? theme.colorScheme.primary,
                  ),
                ),
              ),
              if (widget.progressLabel != null ||
                  widget.progressValue != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.progressLabel ?? '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      widget.progressValue ?? '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            widget.progressColor ?? theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ]
            ]
          ],
        ),
      ),
    );
  }
}
