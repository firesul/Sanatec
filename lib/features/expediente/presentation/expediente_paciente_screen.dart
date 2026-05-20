import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/router/app_router.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/features/citas/presentation/mis_citas_screen.dart';
import 'package:myapp/core/services/gemini_service.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ExpedientePacienteScreen extends StatefulWidget {
  const ExpedientePacienteScreen({super.key, required this.pacienteId});

  final String pacienteId;

  @override
  State<ExpedientePacienteScreen> createState() =>
      _ExpedientePacienteScreenState();
}

class _ExpedientePacienteScreenState extends State<ExpedientePacienteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppTheme.background,
      // AppBar del especialista con flecha de regreso
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.onSurfaceVariant),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.especialista);
            }
          },
        ),
        title: Text(
          'Mental Data',
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => context.push(AppRoutes.perfilEspecialista),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFE6E3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppTheme.outlineVariant.withOpacity(0.4),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header del paciente ---
            _PatientHeader(pacienteId: widget.pacienteId),
            const SizedBox(height: 24),

            // --- TabBar ---
            _CustomTabBar(controller: _tabController),
            const SizedBox(height: 24),

            // --- Contenido: se actualiza con el tab activo ---
            ListenableBuilder(
              listenable: _tabController,
              builder: (context, _) {
                switch (_tabController.index) {
                  case 0:
                    return isWide
                        ? _ExpedienteTabWide(pacienteId: widget.pacienteId)
                        : _ExpedienteTabNarrow(pacienteId: widget.pacienteId);
                  case 1:
                    return _MonitoreosTab(pacienteId: widget.pacienteId);
                  case 2:
                    return _TriajesTab(pacienteId: widget.pacienteId);
                  case 3:
                    return _CitasTab(pacienteId: widget.pacienteId);
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header del paciente
// ---------------------------------------------------------------------------

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.pacienteId});
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.streamPacienteBase(pacienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('Error: Paciente no encontrado o sin permisos.'),
            ),
          );
        }

        final data = snapshot.data!.data()!;
        final nombre = data['nombre'] as String? ?? 'Sin nombre';
        final riesgoStr = data['riesgo'] as String? ?? 'bajo';

        Color badgeColor;
        Color badgeTextColor;
        String badgeLabel;

        if (riesgoStr == 'alto') {
          badgeColor = AppTheme.errorContainer;
          badgeTextColor = AppTheme.onErrorContainer;
          badgeLabel = 'Atención Urgente';
        } else if (riesgoStr == 'moderado') {
          badgeColor = const Color(0xFFFFDEAD);
          badgeTextColor = const Color(0xFF604100);
          badgeLabel = 'En Observación';
        } else {
          badgeColor = AppTheme.secondaryContainer;
          badgeTextColor = AppTheme.onSecondaryContainer;
          badgeLabel = 'Estable';
        }

        int? edad;
        if (data['edad'] != null) {
           edad = int.tryParse(data['edad'].toString());
        }
        final carrera = data['carrera']?.toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E1DE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 20),

                // Nombre + datos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: GoogleFonts.quicksand(
                          fontSize: isWide ? 32 : 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          _MetaText('ID: ${pacienteId.substring(0, 5).toUpperCase()}'),
                          if (edad != null) ...[
                            _Dot(),
                            _MetaText('$edad años'),
                          ],
                          if (carrera != null && carrera.isNotEmpty) ...[
                            _Dot(),
                            _MetaText(carrera),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Badges de acción
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                // Riesgo badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        riesgoStr == 'estable'
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        size: 18,
                        color: badgeTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        badgeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón Nueva Nota
                ElevatedButton.icon(
                  onPressed: () {
                    final noteCtrl = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.white,
                        title: Text('Nueva Nota Clínica', style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: TextField(
                            controller: noteCtrl,
                            maxLines: 6,
                            decoration: InputDecoration(
                              hintText: 'Escribe las observaciones, plan de acción y evolución del paciente...',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final text = noteCtrl.text.trim();
                              if (text.isEmpty) return;
                              
                              try {
                                await FirestoreService.instance.guardarNotaClinica(
                                  pacienteId: pacienteId,
                                  contenido: text,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Nota clínica guardada exitosamente.'),
                                    backgroundColor: AppTheme.secondary,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Error al guardar nota: $e'),
                                    backgroundColor: AppTheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Guardar Nota', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Nueva Nota',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 1,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: AppTheme.onSurfaceVariant,
        ),
      );
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
        '•',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: AppTheme.outlineVariant,
        ),
      );
}

// ---------------------------------------------------------------------------
// TabBar personalizado con underline activo
// ---------------------------------------------------------------------------

class _CustomTabBar extends StatelessWidget {
  const _CustomTabBar({required this.controller});
  final TabController controller;

  static const _tabs = ['Expediente', 'Monitoreos', 'Triajes', 'Citas'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.14,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.onSurfaceVariant,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.zero,
        labelPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab Expediente — layout wide (2 columnas)
// ---------------------------------------------------------------------------

class _ExpedienteTabWide extends StatelessWidget {
  const _ExpedienteTabWide({required this.pacienteId});
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2, 
          child: Column(
            children: [
              _PlanDeAccionCard(pacienteId: pacienteId),
              const SizedBox(height: 20),
              _ClinicalNotesList(pacienteId: pacienteId),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(flex: 1, child: _SideColumn(pacienteId: pacienteId)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab Expediente — layout narrow (1 columna, stacked)
// ---------------------------------------------------------------------------

class _ExpedienteTabNarrow extends StatelessWidget {
  const _ExpedienteTabNarrow({required this.pacienteId});
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlanDeAccionCard(pacienteId: pacienteId),
        const SizedBox(height: 20),
        _ClinicalNotesList(pacienteId: pacienteId),
        const SizedBox(height: 20),
        _SideColumn(pacienteId: pacienteId),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de Plan de Acción (con IA)
// ---------------------------------------------------------------------------

class _PlanDeAccionCard extends StatefulWidget {
  const _PlanDeAccionCard({required this.pacienteId});
  final String pacienteId;

  @override
  State<_PlanDeAccionCard> createState() => _PlanDeAccionCardState();
}

class _PlanDeAccionCardState extends State<_PlanDeAccionCard> {
  bool _isUpdating = false;

  Future<void> _actualizarPlanIA() async {
    setState(() => _isUpdating = true);
    try {
      // 1. Obtener datos del paciente
      final pacienteDoc = await FirebaseFirestore.instance
          .collection('pacientes')
          .doc(widget.pacienteId)
          .get();
      final data = pacienteDoc.data() ?? {};
      final nombre = data['nombre'] as String? ?? 'Estudiante';

      // 2. Obtener check-ins recientes
      final checkinsSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.pacienteId)
          .collection('checkins')
          .orderBy('fecha', descending: true)
          .limit(10)
          .get();

      final checkins = checkinsSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'nivelAnimo': d['nivelAnimo'] ?? 5,
          'comentarios': d['comentarios'] ?? '',
        };
      }).toList();

      // 3. Obtener triajes recientes
      final triajesSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.pacienteId)
          .collection('triajes')
          .orderBy('fecha', descending: true)
          .limit(5)
          .get();

      final triajes = triajesSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'ansiedad': d['ansiedad'] ?? 0,
          'depresion': d['depresion'] ?? 0,
          'nivelRiesgo': d['nivelRiesgo'] ?? 'bajo',
        };
      }).toList();

      // 4. Obtener notas clínicas recientes
      final notasSnap = await FirebaseFirestore.instance
          .collection('pacientes')
          .doc(widget.pacienteId)
          .collection('notasClinicas')
          .orderBy('fecha', descending: true)
          .limit(5)
          .get();

      final notas = notasSnap.docs.map((doc) => doc.data()['contenido'] as String).toList();

      // 5. Generar plan con Gemini
      final planGenerado = await GeminiService.instance.generarPlanDeAccion(
        nombre: nombre,
        checkins: checkins,
        triajes: triajes,
        notasClinicas: notas,
      );

      // 6. Guardar en Firestore
      await FirestoreService.instance.guardarPlanDeAccion(
        pacienteId: widget.pacienteId,
        plan: planGenerado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Plan de Acción actualizado con Gemini exitosamente!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.secondary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al actualizar: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _mostrarDialogoPlanManual(List<String> planActual) {
    final textCtrl = TextEditingController(text: planActual.join('\n'));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Editar Plan de Acción',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escribe cada meta del plan en una línea diferente:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Ejemplo:\n- Mantener horario fijo para dormir.\n- Practicar respiración diafragmática.',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final lines = textCtrl.text
                  .split('\n')
                  .map((l) => l.trim().replaceFirst(RegExp(r'^[-*•]\s*'), ''))
                  .where((l) => l.isNotEmpty)
                  .toList();
              
              try {
                await FirestoreService.instance.guardarPlanDeAccion(
                  pacienteId: widget.pacienteId,
                  plan: lines,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('¡Plan de Acción actualizado manualmente!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.secondary,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error al actualizar plan: $e'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.error,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Guardar Plan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.streamPacienteBase(widget.pacienteId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final plan = List<String>.from(data['planDeAccion'] ?? []);
        final ts = data['planActualizadoEn'] as Timestamp?;
        
        String fechaAct = 'No definido aún';
        if (ts != null) {
          final d = ts.toDate();
          final amPm = d.hour >= 12 ? 'PM' : 'AM';
          final hour12 = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
          fechaAct = '${d.day}/${d.month}/${d.year} ${hour12}:${d.minute.toString().padLeft(2, '0')} $amPm';
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF2EF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.outlineVariant.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan de Acción Sugerido',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'Última actualización: $fechaAct',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isUpdating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.primary)),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _mostrarDialogoPlanManual(plan),
                          icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 24),
                          tooltip: 'Editar plan manualmente',
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: _actualizarPlanIA,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                          label: Text(
                            'Actualizar con IA',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              
              if (_isUpdating) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Gemini está procesando el expediente para trazar las metas...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (plan.isEmpty) ...[
                Text(
                  'Aún no se ha trazado un plan de acción para este estudiante. Presiona "Actualizar con IA" para iniciar el análisis.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ] else ...[
                ...plan.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: AppTheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de Notas Clínicas Reales de Firestore
// ---------------------------------------------------------------------------

class _ClinicalNotesList extends StatelessWidget {
  const _ClinicalNotesList({required this.pacienteId});
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Notas de Seguimiento',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.streamNotasClinicasPaciente(pacienteId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: _cardDecoration,
                child: Center(
                  child: Text(
                    'No hay notas clínicas registradas para este paciente.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = docs[index];
                return _NoteItem(
                  pacienteId: pacienteId,
                  noteId: doc.id,
                  data: doc.data(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _NoteItem extends StatelessWidget {
  const _NoteItem({
    required this.pacienteId,
    required this.noteId,
    required this.data,
  });

  final String pacienteId;
  final String noteId;
  final Map<String, dynamic> data;

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'Sin fecha';
    final d = ts.toDate();
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final hour12 = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${meses[d.month - 1]} ${d.year} • $hour12:$min $amPm';
  }

  void _editarNota(BuildContext context) {
    final textCtrl = TextEditingController(text: data['contenido'] as String);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Editar Nota Clínica',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: textCtrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Modifica la nota clínica...',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = textCtrl.text.trim();
              if (newContent.isEmpty) return;

              // Obtener historial previo o iniciar uno
              final historial = List<dynamic>.from(data['historial'] ?? []);
              
              // Añadir la revisión actual a la historia
              historial.add({
                'contenido': data['contenido'],
                'fecha': data['fecha'] ?? Timestamp.now(),
              });

              await FirestoreService.instance.guardarNotaClinica(
                pacienteId: pacienteId,
                contenido: newContent,
                notaId: noteId,
                historialPrevio: historial,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Nota clínica actualizada exitosamente.'),
                  backgroundColor: AppTheme.secondary,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Guardar Cambios',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _verHistorial(BuildContext context) {
    final historial = List<dynamic>.from(data['historial'] ?? []);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Historial de Revisiones',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.separated(
            itemCount: historial.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, i) {
              // El historial tiene del más viejo al más nuevo. Lo mostramos del más nuevo al más viejo.
              final idx = historial.length - 1 - i;
              final rev = historial[idx] as Map<String, dynamic>;
              final ts = rev['fecha'] as Timestamp?;
              final contenido = rev['contenido'] as String? ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: AppTheme.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'Versión anterior — ${_formatTimestamp(ts)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contenido,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasHistory = data['historial'] != null && (data['historial'] as List).isNotEmpty;
    final fechaStr = _formatTimestamp(data['fecha'] as Timestamp?);
    final contenidoText = data['contenido'] as String? ?? '';
    final esAnalisisIA = contenidoText.contains('[ANÁLISIS CLÍNICO GENERADO POR INTELIGENCIA ARTIFICIAL');

    final borderCol = esAnalisisIA ? const Color(0xFFD8B4FE) : const Color(0xFFE9E1DE);
    final bgCol = esAnalisisIA ? const Color(0xFFFAF5FF) : Colors.white;

    final cardDec = BoxDecoration(
      color: bgCol,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderCol,
        width: esAnalisisIA ? 1.5 : 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.01),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Container(
      decoration: cardDec,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          esAnalisisIA ? 'Diagnóstico Clínico IA' : 'Nota de Seguimiento',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: esAnalisisIA ? const Color(0xFF6B21A8) : AppTheme.onSurface,
                          ),
                        ),
                        if (esAnalisisIA) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE9D5FF)),
                            ),
                            child: Text(
                              'Gemini IA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7E22CE),
                              ),
                            ),
                          ),
                        ],
                        if (hasHistory) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Editada',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fechaStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    _editarNota(context);
                  } else if (value == 'historial') {
                    _verHistorial(context);
                  }
                },
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.onSurfaceVariant),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('Editar Nota'),
                      ],
                    ),
                  ),
                  if (hasHistory)
                    const PopupMenuItem(
                      value: 'historial',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18, color: AppTheme.secondary),
                          SizedBox(width: 8),
                          Text('Cambios anteriores'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['contenido'] as String? ?? 'Sin contenido',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              height: 1.5,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Columna lateral: Métricas en tiempo real + Tarjeta de IA
// ---------------------------------------------------------------------------

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.pacienteId});
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tarjeta de Análisis de IA (Gemini)
        _GeminiAnalysisCard(pacienteId: pacienteId),
        const SizedBox(height: 16),

        // Métricas calculadas
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(pacienteId)
              .collection('checkins')
              .orderBy('fecha', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            double animoPromedio = 0.0;
            double horasSuenoPromedio = 0.0;
            int checkinsConSuenoCount = 0;

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;
              if (docs.isNotEmpty) {
                double totalAnimo = 0.0;
                double totalSueno = 0.0;
                for (final doc in docs) {
                  final data = doc.data();
                  totalAnimo += (data['nivelAnimo'] ?? 0.0).toDouble();
                  if (data['horasSueno'] != null) {
                    totalSueno += (data['horasSueno'] as num).toDouble();
                    checkinsConSuenoCount++;
                  }
                }
                animoPromedio = totalAnimo / docs.length;
                if (checkinsConSuenoCount > 0) {
                  horasSuenoPromedio = totalSueno / checkinsConSuenoCount;
                }
              }
            }

            // Determinar etiqueta de calidad de sueño
            String sleepLabel = 'N/A';
            Color sleepColor = AppTheme.onSurfaceVariant;
            if (checkinsConSuenoCount > 0) {
              if (horasSuenoPromedio >= 7.5) {
                sleepLabel = 'Excelente';
                sleepColor = Colors.green;
              } else if (horasSuenoPromedio >= 6.5) {
                sleepLabel = 'Bueno';
                sleepColor = AppTheme.secondary;
              } else if (horasSuenoPromedio >= 5.0) {
                sleepLabel = 'Regular';
                sleepColor = const Color(0xFFE2A100);
              } else {
                sleepLabel = 'Crítico';
                sleepColor = AppTheme.error;
              }
            }

            return Container(
              width: double.infinity,
              decoration: _cardDecoration,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Métricas Calculadas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ánimo promedio
                  Row(
                    children: [
                      const Icon(Icons.sentiment_satisfied_rounded,
                          size: 20, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ánimo Promedio',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '${animoPromedio.toStringAsFixed(1)}/10',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: animoPromedio / 10.0,
                      backgroundColor: const Color(0xFFE9E1DE),
                      valueColor: const AlwaysStoppedAnimation(AppTheme.secondary),
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Calidad de sueño
                  Row(
                    children: [
                      const Icon(Icons.bedtime_outlined,
                          size: 20, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promedio de Sueño',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            if (checkinsConSuenoCount > 0)
                              Text(
                                '${horasSuenoPromedio.toStringAsFixed(1)} hrs/noche',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        sleepLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sleepColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder para tabs vacíos
// ---------------------------------------------------------------------------

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty_rounded,
                size: 40, color: AppTheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decoración común de tarjeta
// ---------------------------------------------------------------------------

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF1E1B19).withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Pestaña: Monitoreos (Check-ins diarios)
// ---------------------------------------------------------------------------

class _MonitoreosTab extends StatelessWidget {
  const _MonitoreosTab({required this.pacienteId});
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.streamCheckinsPaciente(pacienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const SizedBox(
              height: 200, child: Center(child: Text('Error al cargar historial.')));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(
              height: 200,
              child: Center(
                  child: Text('El paciente no tiene registros de monitoreo diario.')));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final animo = data['nivelAnimo'] as int? ?? 5;
            final comentario = data['comentarios'] as String? ?? '';
            final ts = data['fecha'] as Timestamp?;

            String fecha = 'Sin fecha';
            if (ts != null) {
              final d = ts.toDate();
              fecha =
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.outlineVariant.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$animo',
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fecha,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comentario.isEmpty
                              ? 'Sin comentarios adicionales.'
                              : comentario,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña: Triajes (Evaluaciones completas)
// ---------------------------------------------------------------------------

class _TriajesTab extends StatelessWidget {
  const _TriajesTab({required this.pacienteId});
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.streamTriajesPaciente(pacienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const SizedBox(
              height: 200, child: Center(child: Text('Error al cargar triajes.')));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(
              height: 200,
              child: Center(child: Text('No hay evaluaciones de triaje registradas.')));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final ansiedad = data['ansiedad'] as int? ?? 0;
            final depresion = data['depresion'] as int? ?? 0;
            final riesgo = data['nivelRiesgo'] as String? ?? 'bajo';
            final ts = data['fecha'] as Timestamp?;

            String fecha = 'Sin fecha';
            if (ts != null) {
              final d = ts.toDate();
              fecha =
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
            }

            Color colorRiesgo = AppTheme.secondary;
            if (riesgo == 'alto') {
              colorRiesgo = AppTheme.error;
            } else if (riesgo == 'moderado') colorRiesgo = const Color(0xFFFF8C00);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.outlineVariant.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Evaluación de Triaje',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        fecha,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _MiniMetric(label: 'Ansiedad', value: ansiedad, max: 21),
                      const SizedBox(width: 24),
                      _MiniMetric(label: 'Depresión', value: depresion, max: 21),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorRiesgo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Riesgo: ${riesgo.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorRiesgo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(
      {required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value / $max',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña: Citas
// ---------------------------------------------------------------------------

class _CitasTab extends StatelessWidget {
  const _CitasTab({required this.pacienteId});
  final String pacienteId;

  Future<void> _mostrarDialogoAgendar(BuildContext context) async {
    DateTime fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
    TimeOfDay horaSeleccionada = const TimeOfDay(hour: 10, minute: 0);
    String modalidad = 'enLinea';
    final mensajeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Agendar Cita',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha'),
                    subtitle: Text(
                        '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}'),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setStateDialog(() => fechaSeleccionada = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hora'),
                    subtitle: Text(horaSeleccionada.format(context)),
                    trailing: const Icon(Icons.access_time_rounded),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: horaSeleccionada,
                      );
                      if (picked != null) {
                        setStateDialog(() => horaSeleccionada = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: modalidad,
                    decoration: InputDecoration(
                      labelText: 'Modalidad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'enLinea', child: Text('En línea')),
                      DropdownMenuItem(
                          value: 'presencial', child: Text('Presencial')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => modalidad = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mensajeController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: modalidad == 'enLinea' ? 'Enlace de la Reunión' : 'Mensaje / Detalles Adicionales',
                      hintText: modalidad == 'enLinea'
                          ? 'Ej: https://meet.google.com/abc-defg-hij'
                          : 'Ej: Aula 102, traer libreta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    mensajeController.dispose();
                    Navigator.of(ctx).pop();
                  },
                  child: Text('Cancelar',
                      style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.onSurfaceVariant)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final finalDate = DateTime(
                      fechaSeleccionada.year,
                      fechaSeleccionada.month,
                      fechaSeleccionada.day,
                      horaSeleccionada.hour,
                      horaSeleccionada.minute,
                    );
                    final especialistaId =
                        FirebaseAuth.instance.currentUser?.uid;
                    if (especialistaId == null) return;

                    await FirestoreService.instance.crearCita(
                      pacienteId: pacienteId,
                      especialistaId: especialistaId,
                      fecha: finalDate,
                      modalidad: modalidad,
                      mensaje: mensajeController.text.trim().isEmpty ? null : mensajeController.text.trim(),
                    );
                    if (ctx.mounted) {
                      mensajeController.dispose();
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cita agendada correctamente.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text('Confirmar',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sesiones y Citas',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoAgendar(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Agendar Cita',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 1,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.streamCitasPaciente(pacienteId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SelectableText(
                    'Error al cargar citas. Clic aquí si necesitas crear el índice:\n${snapshot.error}',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const SizedBox(
                  height: 200,
                  child: Center(
                      child: Text('El paciente no tiene citas registradas.')));
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final data = docs[i].data();
                final cita = CitaModel.fromFirestore(docs[i].id, data);
                return CitaCard(cita: cita);
              },
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de Análisis Clínico con Inteligencia Artificial (Gemini 1.5 Flash)
// ---------------------------------------------------------------------------

class _GeminiAnalysisCard extends StatefulWidget {
  const _GeminiAnalysisCard({required this.pacienteId});
  final String pacienteId;

  @override
  State<_GeminiAnalysisCard> createState() => _GeminiAnalysisCardState();
}

class _GeminiAnalysisCardState extends State<_GeminiAnalysisCard> {
  bool _isLoading = false;
  String? _analisis;
  String? _error;
  DateTime? _fechaActualizacion;

  @override
  void initState() {
    super.initState();
    _cargarAnalisisExistente();
  }

  Future<void> _cargarAnalisisExistente() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pacientes')
          .doc(widget.pacienteId)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        if (data['ultimoAnalisisIA'] != null) {
          setState(() {
            _analisis = data['ultimoAnalisisIA'] as String;
            final ts = data['analisisIaActualizadoEn'] as Timestamp?;
            _fechaActualizacion = ts?.toDate();
          });
        }
      }
    } catch (e) {
      // Ignorar error al cargar
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generarAnalisis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Obtener datos base del paciente
      final pacienteDoc = await FirebaseFirestore.instance
          .collection('pacientes')
          .doc(widget.pacienteId)
          .get();
      
      final pacienteData = pacienteDoc.data() ?? {};
      final nombre = pacienteData['nombre'] as String? ?? 'Estudiante';
      final carrera = pacienteData['carrera'] as String? ?? 'N/A';
      final edad = pacienteData['edad']?.toString() ?? 'N/A';

      // 2. Obtener check-ins recientes
      final checkinsSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.pacienteId)
          .collection('checkins')
          .orderBy('fecha', descending: true)
          .limit(10)
          .get();

      final List<Map<String, dynamic>> checkins = [];
      for (final doc in checkinsSnap.docs) {
        final data = doc.data();
        final ts = data['fecha'] as Timestamp?;
        String fecha = 'Sin fecha';
        if (ts != null) {
          final d = ts.toDate();
          fecha = '${d.day}/${d.month}/${d.year}';
        }
        checkins.add({
          'fecha': fecha,
          'nivelAnimo': data['nivelAnimo'] ?? 5,
          'comentarios': data['comentarios'] ?? '',
        });
      }

      // 3. Obtener triajes recientes
      final triajesSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.pacienteId)
          .collection('triajes')
          .orderBy('fecha', descending: true)
          .limit(5)
          .get();

      final List<Map<String, dynamic>> triajes = [];
      for (final doc in triajesSnap.docs) {
        final data = doc.data();
        final ts = data['fecha'] as Timestamp?;
        String fecha = 'Sin fecha';
        if (ts != null) {
          final d = ts.toDate();
          fecha = '${d.day}/${d.month}/${d.year}';
        }
        triajes.add({
          'fecha': fecha,
          'ansiedad': data['ansiedad'] ?? 0,
          'depresion': data['depresion'] ?? 0,
          'nivelRiesgo': data['nivelRiesgo'] ?? 'bajo',
        });
      }

      // 4. Invocar servicio de IA de Gemini
      final resultado = await GeminiService.instance.generarAnalisisClinico(
        nombre: nombre,
        carrera: carrera,
        edad: edad,
        checkins: checkins,
        triajes: triajes,
      );

      // Guardar el análisis generado en Firestore
      await FirestoreService.instance.guardarAnalisisIA(
        pacienteId: widget.pacienteId,
        analisisText: resultado,
      );

      setState(() {
        _analisis = resultado;
        _fechaActualizacion = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error al recopilar el expediente: $e";
        _isLoading = false;
      });
    }
  }

  bool _isSavingNote = false;

  Future<void> _guardarAnalisisComoNota() async {
    if (_analisis == null || _analisis!.trim().isEmpty) return;

    setState(() => _isSavingNote = true);

    try {
      final contenidoConEspecificacion = 
          '🤖 [ANÁLISIS CLÍNICO GENERADO POR INTELIGENCIA ARTIFICIAL (GEMINI)]\n'
          'Este diagnóstico ha sido elaborado de forma automatizada analizando el expediente del alumno.\n\n'
          '${_analisis!.trim()}';

      await FirestoreService.instance.guardarNotaClinica(
        pacienteId: widget.pacienteId,
        contenido: contenidoConEspecificacion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Análisis de IA guardado exitosamente como Nota de Seguimiento.'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNote = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD0E1FD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B19).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF1A73E8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análisis Clínico IA',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      _fechaActualizacion != null
                          ? 'Último análisis: ${_fechaActualizacion!.day}/${_fechaActualizacion!.month}/${_fechaActualizacion!.year} ${_fechaActualizacion!.hour}:${_fechaActualizacion!.minute.toString().padLeft(2, '0')}'
                          : 'Potenciado por Gemini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenido según estado
          if (_isLoading) ...[
            const SizedBox(height: 12),
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Gemini está examinando el expediente y elaborando el reporte...',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildGenerateButton(),
          ] else if (_analisis == null) ...[
            Text(
              'Genera de forma instantánea una evaluación clínica sintética, patrones emocionales y sugerencias de tratamiento basadas en los datos de monitoreo y triajes de este alumno.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildGenerateButton(),
          ] else ...[
            // Contenido del Análisis de IA Renderizado de forma elegante
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: RawScrollbar(
                thumbColor: const Color(0xFFCBD5E1),
                radius: const Radius.circular(8),
                thickness: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _renderTextToRichWidgets(_analisis!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    setState(() {
                      _analisis = null;
                      _fechaActualizacion = null;
                    });
                    await FirebaseFirestore.instance
                        .collection('pacientes')
                        .doc(widget.pacienteId)
                        .update({
                      'ultimoAnalisisIA': FieldValue.delete(),
                      'analisisIaActualizadoEn': FieldValue.delete(),
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.onSurfaceVariant),
                  label: Text(
                    'Limpiar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (_isSavingNote)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.secondary)),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _guardarAnalisisComoNota,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6F4EA),
                      foregroundColor: const Color(0xFF137333),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.bookmark_added_rounded, size: 13),
                    label: Text(
                      'Guardar Nota',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: _generarAnalisis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F0FE),
                    foregroundColor: const Color(0xFF1A73E8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 13),
                  label: Text(
                    'Reanalizar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generarAnalisis,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
        label: Text(
          'Generar Diagnóstico IA',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Renderiza el formato retornado de manera personalizada para evitar dependencias
  List<Widget> _renderTextToRichWidgets(String rawText) {
    final List<Widget> widgets = [];
    final lines = rawText.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Detectar headers personalizados de GeminiService
      if (trimmedLine.startsWith('📊') ||
          trimmedLine.startsWith('📉') ||
          trimmedLine.startsWith('🧠') ||
          trimmedLine.startsWith('🎯')) {
        widgets.add(const SizedBox(height: 12));
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trimmedLine,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A73E8),
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      } else if (trimmedLine.startsWith('-') || trimmedLine.startsWith('*')) {
        // Renderizar viñetas
        final cleanContent = trimmedLine.replaceFirst(RegExp(r'^[-*]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.fiber_manual_record, size: 6, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cleanContent,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Texto general
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              trimmedLine,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

