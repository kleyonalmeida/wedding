import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/wedding_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CountdownSection extends StatefulWidget {
  const CountdownSection({super.key});

  @override
  State<CountdownSection> createState() => _CountdownSectionState();
}

class _CountdownSectionState extends State<CountdownSection> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateDuration();
    });
  }

  void _calculateDuration() {
    final now = DateTime.now();
    final difference = WeddingConstants.weddingDate.difference(now);
    
    if (difference.isNegative) {
      _timer?.cancel();
      if (mounted) setState(() => _duration = Duration.zero);
    } else {
      if (mounted) setState(() => _duration = difference);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _duration.inDays.toString().padLeft(2, '0');
    final hours = (_duration.inHours % 24).toString().padLeft(2, '0');
    final minutes = (_duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_duration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 16.0),
      child: Column(
        children: [
          Text(
            'Contagem Regressiva',
            style: AppTextStyles.cursive.copyWith(
              fontSize: MediaQuery.of(context).size.width >= 768 ? 96 : 64,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
            children: [
              _buildCard(days, 'DIAS'),
              _buildCard(hours, 'HORAS'),
              _buildCard(minutes, 'MINUTOS'),
              _buildCard(seconds, 'SEGUNDOS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: AppTextStyles.serif.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: AppTextStyles.sans.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
