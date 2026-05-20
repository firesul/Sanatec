import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/shared/widgets/app_bottom_nav_bar.dart';
import 'package:myapp/shared/widgets/app_top_bar.dart';

class DailyMoodScreen extends StatefulWidget {
  const DailyMoodScreen({super.key});

  @override
  State<DailyMoodScreen> createState() => _DailyMoodScreenState();
}

class _DailyMoodScreenState extends State<DailyMoodScreen> {
  double _moodValue = 7;
  final _commentController = TextEditingController();
  int _currentNavIndex = 0;
  bool _guardando = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Emoji y etiqueta según el nivel de ánimo 1-10
  ({IconData icon, String label, Color color}) get _moodData {
    if (_moodValue <= 2) {
      return (
        icon: Icons.sentiment_very_dissatisfied_rounded,
        label: 'Muy difícil',
        color: const Color(0xFFBA1A1A),
      );
    } else if (_moodValue <= 4) {
      return (
        icon: Icons.sentiment_dissatisfied_rounded,
        label: 'Difícil',
        color: const Color(0xFFE8593C),
      );
    } else if (_moodValue <= 6) {
      return (
        icon: Icons.sentiment_neutral_rounded,
        label: 'Neutral',
        color: const Color(0xFF7C5400),
      );
    } else if (_moodValue <= 8) {
      return (
        icon: Icons.sentiment_satisfied_rounded,
        label: 'Bien',
        color: AppTheme.primary,
      );
    } else {
      return (
        icon: Icons.sentiment_very_satisfied_rounded,
        label: 'Excelente',
        color: AppTheme.secondary,
      );
    }
  }

  void _handleSave() async {
    if (_guardando) return;
    setState(() => _guardando = true);

    try {
      await FirestoreService.instance.guardarCheckin(
        nivelAnimo: _moodValue.round(),
        comentarios: _commentController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Check-in guardado! Nivel: ${_moodValue.round()}/10',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: const Color(0xFFBA1A1A), // error color
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodData;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Encabezado de página ---
              Text(
                'Check-in Diario',
                style: GoogleFonts.quicksand(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tómate un momento para registrar cómo te sientes hoy.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // --- Tarjeta: Escala de ánimo ---
              _MoodScaleCard(
                moodValue: _moodValue,
                moodIcon: mood.icon,
                moodLabel: mood.label,
                moodColor: mood.color,
                onChanged: (v) => setState(() => _moodValue = v),
              ),

              const SizedBox(height: 24),

              // --- Área de comentarios ---
              Text(
                'Comentarios',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.14,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: AppTheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText:
                      '¿Hay algo en particular que esté influyendo en tu estado de ánimo?',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: AppTheme.outline,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.secondary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 32),

              // --- Botón: Guardar Check-in ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _guardando ? AppTheme.surfaceVariant : AppTheme.primary,
                    foregroundColor: _guardando ? AppTheme.onSurfaceVariant : Colors.white,
                    elevation: 0,
                    shadowColor: AppTheme.primary.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ).copyWith(
                    elevation: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.pressed) ? 0 : 2,
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onSurfaceVariant),
                          ),
                        )
                      : Text(
                          'Guardar Check-in',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidgets
// ---------------------------------------------------------------------------

/// Tarjeta blanca con el emoji de ánimo animado + slider 1-10.
class _MoodScaleCard extends StatelessWidget {
  const _MoodScaleCard({
    required this.moodValue,
    required this.moodIcon,
    required this.moodLabel,
    required this.moodColor,
    required this.onChanged,
  });

  final double moodValue;
  final IconData moodIcon;
  final String moodLabel;
  final Color moodColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradiente decorativo de fondo
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFDAD3).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '¿Cómo te sientes?',
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                // Círculo del emoji — animado con AnimatedSwitcher
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Container(
                    key: ValueKey(moodIcon),
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFDAD3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      moodIcon,
                      size: 72,
                      color: AppTheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                // Etiqueta del estado
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    moodLabel,
                    key: ValueKey(moodLabel),
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: moodColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: const Color(0xFFFFDAD3),
                    thumbColor: AppTheme.primary,
                    overlayColor: AppTheme.primary.withOpacity(0.12),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 14),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: moodValue,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: onChanged,
                  ),
                ),

                // Etiquetas del slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 – Difícil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '10 – Excelente',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
