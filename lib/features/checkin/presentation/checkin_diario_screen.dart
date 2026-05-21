import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/shared/widgets/app_bottom_nav_bar.dart';
import 'package:myapp/shared/widgets/app_top_bar.dart';
import 'package:myapp/shared/widgets/cerebro_nativo.dart';

// ---------------------------------------------------------------------------
// Screen: Check-in Diario (Home del estudiante / Mood)
// ---------------------------------------------------------------------------

class CheckinDiarioScreen extends StatefulWidget {
  const CheckinDiarioScreen({super.key});

  @override
  State<CheckinDiarioScreen> createState() => _CheckinDiarioScreenState();
}

class _CheckinDiarioScreenState extends State<CheckinDiarioScreen>
    with SingleTickerProviderStateMixin {
  double _mood = 7;
  final _comentariosCtrl = TextEditingController();
  bool _guardado = false;
  int _navIndex = 0; // Tab "Mood" activo
  late final AnimationController _emojiAnim;

  // Variables para control de sueño
  TimeOfDay _horaAcostarse = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _horaDespertarse = const TimeOfDay(hour: 7, minute: 0);

  double _calcularHorasSueno() {
    final double dormirMinutes = _horaAcostarse.hour * 60.0 + _horaAcostarse.minute;
    final double despertarMinutes = _horaDespertarse.hour * 60.0 + _horaDespertarse.minute;
    double diffMinutes;
    if (despertarMinutes >= dormirMinutes) {
      diffMinutes = despertarMinutes - dormirMinutes;
    } else {
      diffMinutes = (1440.0 - dormirMinutes) + despertarMinutes;
    }
    return diffMinutes / 60.0;
  }

  @override
  void initState() {
    super.initState();
    _emojiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _comentariosCtrl.dispose();
    _emojiAnim.dispose();
    super.dispose();
  }

  /// Datos del emoji según el valor del slider
  ({String icon, Color bg, Color iconColor, String label}) get _moodData {
    if (_mood <= 2) {
      return (
        icon: '🧠😢',
        bg: AppTheme.errorContainer,
        iconColor: AppTheme.error,
        label: 'Agotado / Muy Triste',
      );
    } else if (_mood <= 4) {
      return (
        icon: '🧠😟',
        bg: const Color(0xFFFFDAD3),
        iconColor: AppTheme.primary,
        label: 'Ansioso / Triste',
      );
    } else if (_mood <= 6) {
      return (
        icon: '🧠😐',
        bg: const Color(0xFFFFDEAD),
        iconColor: const Color(0xFF7C5400),
        label: 'Calmado / Neutral',
      );
    } else if (_mood <= 8) {
      return (
        icon: '🧠😊',
        bg: const Color(0xFFFFDAD3),
        iconColor: AppTheme.primary,
        label: 'Feliz / Motivado',
      );
    } else {
      return (
        icon: '🧠🤩✨',
        bg: AppTheme.secondaryContainer,
        iconColor: AppTheme.secondary,
        label: '¡Feliz al Máximo! 🌟',
      );
    }
  }

  void _onSliderChanged(double v) {
    setState(() => _mood = v);
    // Micro-animación de rebote al cambiar
    _emojiAnim.reverse().then((_) => _emojiAnim.forward());
  }

  void _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _guardado = true);
    try {
      final hours = _calcularHorasSueno();
      final amPmAcostarse = _horaAcostarse.format(context);
      final amPmDespertarse = _horaDespertarse.format(context);

      await FirestoreService.instance.guardarCheckin(
        nivelAnimo: _mood.round(),
        comentarios: _comentariosCtrl.text.trim(),
        horaDormir: amPmAcostarse,
        horaDespertar: amPmDespertarse,
        horasSueno: hours,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Check-in guardado correctamente!'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardado = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildSleepFeedback() {
    if (!_guardado) {
      return const SizedBox.shrink();
    }
    final hours = _calcularHorasSueno();
    if (hours >= 7.0) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EA), // Emerald/Green suave
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF34A853).withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFF137333), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Excelente descanso! 🧠✨ Dormir bien ayuda a consolidar tu memoria, regula tus emociones y fortalece tu cerebro. ¡Sigue así, tu cuerpo te lo agradece!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF137333),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF7E0), // Orange/Yellow suave
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFBBC05).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFB06000), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sugerencia de descanso 🛌: Has dormido menos de 7 horas. Un descanso adecuado estabiliza tu estado de ánimo, reduce la ansiedad y te recarga de energía. ¡Hoy podría ser una buena noche para acostarte un poco más temprano!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFFB06000),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _moodData;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
        child: Center(
          // Limitar ancho en pantallas grandes (diseño mobile-first)
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Encabezado ---
                Text(
                  'Check-in Diario',
                  style: GoogleFonts.quicksand(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tómate un momento para registrar cómo te sientes hoy.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // --- Tarjeta de estado de ánimo ---
                _MoodCard(
                  mood: _mood,
                  moodData: data,
                  emojiAnim: _emojiAnim,
                  onChanged: _guardado ? null : _onSliderChanged,
                ),

                const SizedBox(height: 24),

                // --- Sección de Registro de Sueño ---
                Text(
                  'Registro de Sueño',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _guardado
                                  ? null
                                  : () async {
                                      final selected = await showTimePicker(
                                        context: context,
                                        initialTime: _horaAcostarse,
                                        helpText: '¿A qué hora te acostaste?',
                                      );
                                      if (selected != null) {
                                        setState(() => _horaAcostarse = selected);
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.bedtime_rounded, color: Color(0xFF1E293B), size: 20),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Me acosté',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppTheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _horaAcostarse.format(context),
                                      style: GoogleFonts.quicksand(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _guardado
                                  ? null
                                  : () async {
                                      final selected = await showTimePicker(
                                        context: context,
                                        initialTime: _horaDespertarse,
                                        helpText: '¿A qué hora te despertaste?',
                                      );
                                      if (selected != null) {
                                        setState(() => _horaDespertarse = selected);
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 20),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Me desperté',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppTheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _horaDespertarse.format(context),
                                      style: GoogleFonts.quicksand(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.hotel_rounded, color: Color(0xFF1A73E8), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Tiempo total de sueño: ${_calcularHorasSueno().toStringAsFixed(1)} horas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A73E8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSleepFeedback(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Comentarios ---
                Text(
                  '¡Exprésate! ¿Cómo te sientes hoy?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _comentariosCtrl,
                  enabled: !_guardado,
                  maxLines: 4,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: AppTheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Cuéntanos un poco más sobre lo que tienes en mente hoy...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppTheme.outlineVariant,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppTheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppTheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.secondary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // --- Botón Guardar ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _guardado ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _guardado
                          ? AppTheme.surfaceVariant
                          : AppTheme.primary,
                      foregroundColor: _guardado
                          ? AppTheme.onSurfaceVariant
                          : Colors.white,
                      elevation: _guardado ? 0 : 2,
                      shadowColor: AppTheme.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _guardado
                          ? '✓ Check-in guardado'
                          : 'Guardar Check-in',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta del emoji + slider
// ---------------------------------------------------------------------------

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.mood,
    required this.moodData,
    required this.emojiAnim,
    required this.onChanged,
  });

  final double mood;
  final ({
    String icon,
    Color bg,
    Color iconColor,
    String label
  }) moodData;
  final AnimationController emojiAnim;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Gradiente decorativo superior
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFDAD3).withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                // Pregunta
                Text(
                  '¿Cómo te sientes hoy?',
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),

                const SizedBox(height: 24),

                // Cerebro animado e interactivo
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: emojiAnim,
                    curve: Curves.easeOutBack,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: moodData.bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: moodData.iconColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: CerebroNativo(
                          moodValue: mood,
                          size: 110,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Label del nivel
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '${mood.round()} — ${moodData.label}',
                    key: ValueKey(mood.round()),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: moodData.iconColor,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: const Color(0xFFFFDAD3),
                    thumbColor: AppTheme.primary,
                    overlayColor: AppTheme.primary.withOpacity(0.1),
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 16),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 26),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: mood,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: onChanged,
                  ),
                ),

                // Etiquetas extremos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 – Agotado / Triste',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '10 – ¡Feliz al Máximo!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
