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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon, size: 20, color: widget.iconColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.value,
                      maxLines: 1,
                      style:
                          theme.textTheme.displaySmall?.copyWith(fontSize: 30),
                    ),
                  ),
                ),
                if (widget.suffixText != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.suffixText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.progressColor ?? theme.colorScheme.primary,
                  ),
                ),
              ),
              if (widget.progressLabel != null ||
                  widget.progressValue != null) ...[
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        widget.progressLabel ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
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
