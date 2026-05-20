import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/router/app_router.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/core/services/translation_service.dart';

/// BottomNavigationBar del estudiante.
/// Tabs: Mood | Triage | Citas | Perfil
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    // onTap sigue siendo opcional para compatibilidad local (sin router)
    this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  // Mapa de índice → ruta
  static const _routes = [
    AppRoutes.home,     // 0 - Mood
    AppRoutes.triaje,   // 1 - Triage
    AppRoutes.citas,    // 2 - Citas
    '/perfil',          // 3 - Perfil (futuro)
  ];

  List<_NavItem> _items(BuildContext context) => [
    _NavItem(icon: Icons.sentiment_satisfied_rounded, label: t('mood')),
    _NavItem(icon: Icons.description_outlined, label: t('triage')),
    _NavItem(icon: Icons.calendar_today_rounded, label: t('citas')),
    _NavItem(icon: Icons.person_outline_rounded, label: t('perfil')),
  ];

  void _handleTap(BuildContext context, int index) {
    // Si hay callback local, lo llama (para setState en las pantallas)
    onTap?.call(index);
    // Navega a la ruta correspondiente
    final route = _routes[index];
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, lang, _) {
        final items = _items(context);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final isActive = i == currentIndex;
                  final item = items[i];
                  return _NavButton(
                    icon: item.icon,
                    label: item.label,
                    isActive: isActive,
                    onTap: () => _handleTap(context, i),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive
                    ? AppTheme.onSecondaryContainer
                    : AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppTheme.onSecondaryContainer
                    : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
