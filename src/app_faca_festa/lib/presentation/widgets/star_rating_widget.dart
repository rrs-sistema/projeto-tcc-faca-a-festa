import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../controllers/tema/event_theme_controller.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final void Function(double)? onChanged;
  final Gradient? gradient;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 34,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final primaryGradient = gradient ?? theme.gradient.value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;

        if (rating >= starValue) {
          icon = Icons.star_rounded; // cheia
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded; // meia
        } else {
          icon = Icons.star_border_rounded; // vazia
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onChanged == null
              ? null
              : (details) {
                  final localX = details.localPosition.dx;
                  final fraction = localX / size;

                  double newValue;

                  if (fraction <= 0.5) {
                    newValue = index + 0.5;
                  } else {
                    newValue = index + 1.0;
                  }

                  onChanged!(newValue);
                },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: (rating >= starValue - 0.2 && rating < starValue + 0.8) ? 1.12 : 1,
            curve: Curves.easeOutBack,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return (rating >= starValue - 0.5)
                    ? primaryGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      )
                    : const LinearGradient(
                        colors: [Colors.grey, Colors.grey],
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      );
              },
              blendMode: BlendMode.srcIn,
              child: Icon(
                icon,
                size: size,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        );
      }),
    );
  }
}
