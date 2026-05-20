import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/shared/widgets/app_bottom_nav_bar.dart';
import 'package:myapp/shared/widgets/app_top_bar.dart';

// ---------------------------------------------------------------------------
// Enum de prioridad de riesgo
// ---------------------------------------------------------------------------

enum NivelRiesgo { bajo, moderado, alto }

extension NivelRiesgoX on NivelRiesgo {
  String get label {
    switch (this) {
      case NivelRiesgo.bajo:
        return 'Estable (Bajo)';
      case NivelRiesgo.moderado:
        return 'Seguimiento (Moderado)';
      case NivelRiesgo.alto:
        return 'Atención Requerida (Alta)';
    }
  }

  Color get bgColor {
    switch (this) {
      case NivelRiesgo.bajo:
        return const Color(0xFF9DEDF1); // secondary-container
      case NivelRiesgo.moderado:
        return const Color(0xFFFFDEAD); // tertiary-fixed
      case NivelRiesgo.alto:
        return const Color(0xFFFFDAD6); // error-container
    }
  }

  Color get textColor {
    switch (this) {
      case NivelRiesgo.bajo:
        return const Color(0xFF096E72); // on-secondary-container
      case NivelRiesgo.moderado:
        return const Color(0xFF604100); // on-tertiary-fixed-variant
      case NivelRiesgo.alto:
        return const Color(0xFF93000A); // on-error-container
    }
  }

  IconData get icon {
    switch (this) {
      case NivelRiesgo.bajo:
        return Icons.check_circle_rounded;
      case NivelRiesgo.moderado:
        return Icons.info_rounded;
      case NivelRiesgo.alto:
        return Icons.warning_rounded;
    }
  }

  String get description {
    switch (this) {
      case NivelRiesgo.bajo:
        return 'Tu estado emocional parece estable. ¡Sigue así! Recuerda registrar cómo te sientes diariamente.';
      case NivelRiesgo.moderado:
        return 'Hemos notado algunos indicadores. Un especialista revisará tus datos para brindarte el apoyo adecuado.';
      case NivelRiesgo.alto:
        return 'Hemos notado niveles elevados. Un especialista revisará tus datos pronto para darte atención prioritaria.';
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TriajeScreen extends StatefulWidget {
  const TriajeScreen({super.key});

  @override
  State<TriajeScreen> createState() => _TriajeScreenState();
}

class _TriajeScreenState extends State<TriajeScreen> {
  double _ansiedad = 6;
  double _depresion = 8;
  bool _guardado = false;
  int _currentNavIndex = 1; // Tab "Triage" activo

  NivelRiesgo get _riesgo {
    final total = _ansiedad + _depresion;
    if (total >= 14) return NivelRiesgo.alto;
    if (total >= 10) return NivelRiesgo.moderado;
    return NivelRiesgo.bajo;
  }

  void _guardar() async {
    setState(() => _guardado = true);
    try {
      await FirestoreService.instance.guardarTriaje(
        ansiedad: _ansiedad.round(),
        depresion: _depresion.round(),
        nivelRiesgo: _riesgo.name, // "bajo" | "moderado" | "alto"
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Triaje guardado correctamente'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado ---
            Text(
              'Chequeo Rápido',
              style: GoogleFonts.quicksand(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tómate un momento para evaluar cómo te sientes hoy. Esta información nos ayuda a personalizar tu experiencia.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            // --- Slider: Ansiedad (teal) ---
            _TriajeSliderCard(
              titulo: 'Nivel de Ansiedad',
              valor: _ansiedad,
              etiquetaMin: 'Calmado',
              etiquetaMax: 'Intranquilo',
              activeColor: AppTheme.secondary,
              trackColor: AppTheme.secondaryContainer,
              badgeBg: AppTheme.secondaryContainer.withOpacity(0.4),
              badgeText: AppTheme.secondary,
              onChanged: _guardado
                  ? null
                  : (v) => setState(() => _ansiedad = v),
            ),

            const SizedBox(height: 16),

            // --- Slider: Depresión (coral/primary) ---
            _TriajeSliderCard(
              titulo: 'Nivel de Depresión',
              valor: _depresion,
              etiquetaMin: 'Estable',
              etiquetaMax: 'Abatido',
              activeColor: AppTheme.primary,
              trackColor: const Color(0xFFFFDAD3),
              badgeBg: AppTheme.errorContainer.withOpacity(0.4),
              badgeText: AppTheme.primary,
              onChanged: _guardado
                  ? null
                  : (v) => setState(() => _depresion = v),
            ),

            // --- Badge de resultado (visible siempre, se actualiza en vivo) ---
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _RiesgoBadgeCard(
                key: ValueKey(_riesgo),
                riesgo: _riesgo,
              ),
            ),

            const SizedBox(height: 28),

            // --- Botón Guardar ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _guardado ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _guardado ? AppTheme.surfaceVariant : AppTheme.primary,
                  foregroundColor:
                      _guardado ? AppTheme.onSurfaceVariant : Colors.white,
                  elevation: 1,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  _guardado ? '✓ Triaje guardado' : 'Guardar y Continuar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
// Subwidget: tarjeta de slider con badge de valor
// ---------------------------------------------------------------------------

class _TriajeSliderCard extends StatelessWidget {
  const _TriajeSliderCard({
    required this.titulo,
    required this.valor,
    required this.etiquetaMin,
    required this.etiquetaMax,
    required this.activeColor,
    required this.trackColor,
    required this.badgeBg,
    required this.badgeText,
    required this.onChanged,
  });

  final String titulo;
  final double valor;
  final String etiquetaMin;
  final String etiquetaMax;
  final Color activeColor;
  final Color trackColor;
  final Color badgeBg;
  final Color badgeText;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila: título + badge de valor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(valor.round()),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${valor.round()} / 10',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: badgeText,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Slider personalizado
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: trackColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.12),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 13),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 22),
              trackHeight: 8,
            ),
            child: Slider(
              value: valor,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),

          // Etiquetas de extremos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  etiquetaMin,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  etiquetaMax,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
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

// ---------------------------------------------------------------------------
// Subwidget: Badge de prioridad de riesgo
// ---------------------------------------------------------------------------

class _RiesgoBadgeCard extends StatefulWidget {
  const _RiesgoBadgeCard({required this.riesgo, super.key});
  final NivelRiesgo riesgo;

  @override
  State<_RiesgoBadgeCard> createState() => _RiesgoBadgeCardState();
}

class _RiesgoBadgeCardState extends State<_RiesgoBadgeCard> {
  bool _revelado = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: _revelado ? _buildRevelado() : _buildOculto(),
      ),
    );
  }

  Widget _buildOculto() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF2EF),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Evaluación de Bienestar Protegida',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu nivel de prioridad de triaje ha sido evaluado con éxito. Para evitar sugestión o preocupación innecesaria, mantenemos el resultado protegido. Puedes revelarlo cuando gustes, o dejar que sea revisado directamente por el departamento de psicología en tu expediente.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _revelado = true),
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: Text(
              'Revelar Prioridad Evaluada',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevelado() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 24),
            Text(
              'PRIORIDAD DE RIESGO EVALUADA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_off_rounded, size: 16, color: AppTheme.outline),
              onPressed: () => setState(() => _revelado = false),
              tooltip: 'Ocultar resultado',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.riesgo.bgColor,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.riesgo.icon, size: 20, color: widget.riesgo.textColor),
              const SizedBox(width: 8),
              Text(
                widget.riesgo.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.riesgo.textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.riesgo.description,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
