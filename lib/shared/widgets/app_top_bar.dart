import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/core/router/app_router.dart';

/// AppBar superior reutilizable con el logo y avatar del usuario.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.onAvatarTap});

  final VoidCallback? onAvatarTap;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          const Icon(
            Icons.spa_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            'Mental Data',
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: onAvatarTap ?? () => context.push(AppRoutes.perfil),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryContainer,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.onSecondaryContainer,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
