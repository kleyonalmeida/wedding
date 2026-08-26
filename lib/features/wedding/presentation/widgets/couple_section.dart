import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CoupleSection extends StatelessWidget {
  const CoupleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 96.0, horizontal: 24.0),
      child: Column(
        children: [
          Text(
            'O Casal',
            style: AppTextStyles.cursive.copyWith(
              fontSize: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 64),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Profile(
                      name: 'Kleyon',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCZqdu8IjxxpBS8oT3U79TV38rRvPPMbJxHV2D-sIPNjtsBxeTohd1e9LLKxmQH1Pd9KnI737yGAKsgZUW7jjkEy8_iJ-X25vK4dQmG3LJlzZKWl8vv27VhWV5QsRQOMd6WnIyD_khD6A6Y5znRRhfeReQ-QlchPCdz0mX6O3YcOTaEkMSZ6j0-YPTU1PC7Rnm5oUEpI1WqqIc4zD2TCiwjDCmZR1B6Mpzvp7msv3v0wWDqJmssr2knudPQrnDD2jgM0Q',
                    ),
                    SizedBox(width: 48),
                    Text(
                      '♥',
                      style: TextStyle(
                        fontSize: 48,
                        color: Color(0x33B8A291), // AppColors.primary with 20% opacity
                        fontFamily: 'Playfair Display',
                      ),
                    ),
                    SizedBox(width: 48),
                    _Profile(
                      name: 'Liandra',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCo8fpihHw2l8ykih5pZxOh2GCXVx2JjoEltr8MWz6NR3tyGERIS7C7OSl8OIKilkjhtZqV7wZy7pDAVUbIXyG9YZtl_PwefdEGNbmTmX84HKXr8-qXiiwT2_-sLZH0kA49oN6YZKySEcrrxiU1BFF6L7yY-90Xw9yvPxwfZUuaNpEGG2H9or_OHdjkTKb5Baz3SAUuz_LPyK0ETQBaTyngudNj6abpAuNxk9RMr8PbpKOk_Jb4IyV7wN3sIvilGT8mDg',
                    ),
                  ],
                );
              } else {
                return const Column(
                  children: [
                    _Profile(
                      name: 'Kleyon',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCZqdu8IjxxpBS8oT3U79TV38rRvPPMbJxHV2D-sIPNjtsBxeTohd1e9LLKxmQH1Pd9KnI737yGAKsgZUW7jjkEy8_iJ-X25vK4dQmG3LJlzZKWl8vv27VhWV5QsRQOMd6WnIyD_khD6A6Y5znRRhfeReQ-QlchPCdz0mX6O3YcOTaEkMSZ6j0-YPTU1PC7Rnm5oUEpI1WqqIc4zD2TCiwjDCmZR1B6Mpzvp7msv3v0wWDqJmssr2knudPQrnDD2jgM0Q',
                    ),
                    SizedBox(height: 32),
                    Text(
                      '♥',
                      style: TextStyle(
                        fontSize: 48,
                        color: Color(0x33B8A291),
                        fontFamily: 'Playfair Display',
                      ),
                    ),
                    SizedBox(height: 32),
                    _Profile(
                      name: 'Liandra',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCo8fpihHw2l8ykih5pZxOh2GCXVx2JjoEltr8MWz6NR3tyGERIS7C7OSl8OIKilkjhtZqV7wZy7pDAVUbIXyG9YZtl_PwefdEGNbmTmX84HKXr8-qXiiwT2_-sLZH0kA49oN6YZKySEcrrxiU1BFF6L7yY-90Xw9yvPxwfZUuaNpEGG2H9or_OHdjkTKb5Baz3SAUuz_LPyK0ETQBaTyngudNj6abpAuNxk9RMr8PbpKOk_Jb4IyV7wN3sIvilGT8mDg',
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 64),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Column(
              children: [
                Text(
                  '"Vamos nos casar!"',
                  style: AppTextStyles.serif.copyWith(
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nossa história começou com um simples encontro que floresceu em uma jornada inesquecível de cumplicidade e amor. Cada passo que demos juntos nos trouxe a este momento sublime onde decidimos unir nossas vidas para sempre.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sans.copyWith(
                    fontSize: 16,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                    fontStyle: FontStyle.italic,
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

class _Profile extends StatelessWidget {
  final String name;
  final String imageUrl;

  const _Profile({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          name,
          style: AppTextStyles.serif.copyWith(
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
