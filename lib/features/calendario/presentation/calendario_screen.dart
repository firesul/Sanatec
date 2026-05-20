import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/router/app_router.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/services/translation_service.dart';
import 'package:myapp/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo de datos de slot
// ---------------------------------------------------------------------------

enum SlotEstado { confirmada, atencionRequerida, pendiente, cancelada, disponible }

class SlotCita {
  const SlotCita({
    required this.estado,
    this.paciente,
    this.hora,
    this.mensaje,
    this.modalidad,
  });

  final SlotEstado estado;
  final String? paciente;
  final String? hora;
  final String? mensaje;
  final String? modalidad;
}


// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final int _navIndex = 1; // Schedule activo
  DateTime _baseDate = DateTime.now();

  void _mostrarDialogoNuevaCita() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error: No se detectó tu sesión de especialista.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    String? selectedPacienteId;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String selectedModalidad = 'presencial';
    bool isSaving = false;
    final mensajeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateStr = selectedDate != null
                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                : 'Seleccionar fecha';
            final timeStr = selectedTime != null
                ? selectedTime!.format(context)
                : 'Seleccionar hora';

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Programar Cita',
                    style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seleccionar Paciente
                      Text(
                        'Seleccionar Alumno',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirestoreService.instance.streamPacientes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Text(
                              'No hay alumnos registrados.',
                              style: GoogleFonts.plusJakartaSans(color: AppTheme.error, fontSize: 13),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedPacienteId,
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: 'Elige un alumno...',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: docs.map((doc) {
                              final name = doc.data()['nombre'] as String? ?? 'Alumno';
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedPacienteId = val);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selección de Fecha
                      Text(
                        'Fecha de la Cita',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppTheme.primary,
                                    onPrimary: Colors.white,
                                    onSurface: AppTheme.onSurface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: selectedDate != null ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                                ),
                              ),
                              const Icon(Icons.date_range_rounded, color: AppTheme.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selección de Hora
                      Text(
                        'Hora de la Cita',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppTheme.primary,
                                    onPrimary: Colors.white,
                                    onSurface: AppTheme.onSurface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                timeStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: selectedTime != null ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                                ),
                              ),
                              const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selección de Modalidad
                      Text(
                        'Modalidad',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Text('Presencial', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                              selected: selectedModalidad == 'presencial',
                              selectedColor: const Color(0xFFFBF2EF),
                              checkmarkColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: selectedModalidad == 'presencial' ? AppTheme.primary : AppTheme.onSurfaceVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: selectedModalidad == 'presencial' ? AppTheme.primary : AppTheme.outlineVariant,
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() => selectedModalidad = 'presencial');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: Text('Virtual', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                              selected: selectedModalidad == 'virtual',
                              selectedColor: const Color(0xFFFBF2EF),
                              checkmarkColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: selectedModalidad == 'virtual' ? AppTheme.primary : AppTheme.onSurfaceVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: selectedModalidad == 'virtual' ? AppTheme.primary : AppTheme.outlineVariant,
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() => selectedModalidad = 'virtual');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedModalidad == 'virtual' ? 'Enlace de la Reunión (Virtual)' : 'Mensaje / Detalles Adicionales',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: mensajeController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: selectedModalidad == 'virtual'
                              ? 'Ej: https://meet.google.com/abc-defg-hij...'
                              : 'Ej: Aula 102, traer libreta o detalles adicionales...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          mensajeController.dispose();
                          Navigator.pop(context);
                        },
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving || selectedPacienteId == null || selectedDate == null || selectedTime == null
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final fechaCompleta = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              selectedTime!.hour,
                              selectedTime!.minute,
                            );

                            await FirestoreService.instance.crearCita(
                              pacienteId: selectedPacienteId!,
                              especialistaId: uid,
                              fecha: fechaCompleta,
                              modalidad: selectedModalidad,
                              mensaje: mensajeController.text.trim().isEmpty ? null : mensajeController.text.trim(),
                            );

                            if (context.mounted) {
                              mensajeController.dispose();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Cita programada exitosamente.'),
                                backgroundColor: AppTheme.secondary,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error al programar cita: $e'),
                                backgroundColor: AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ));
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text('Programar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
    final isWide = MediaQuery.of(context).size.width >= 760;

    return ValueListenableBuilder(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, currentLang, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          bottomNavigationBar: isWide ? null : NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) {
              if (i == 0) context.go(AppRoutes.especialista);
              if (i == 1) return; // Ya estamos
              if (i == 2) context.go('${AppRoutes.especialista}?tab=2'); // Regresa al dashboard para buscar directamente
            },
            backgroundColor: const Color(0xFFFBF2EF),
            indicatorColor: AppTheme.primary.withOpacity(0.15),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: t('dashboard')),
              NavigationDestination(icon: const Icon(Icons.calendar_month_rounded), selectedIcon: const Icon(Icons.calendar_month_rounded, color: AppTheme.primary), label: t('schedule')),
              NavigationDestination(icon: const Icon(Icons.search_rounded), label: t('search')),
            ],
          ),
          appBar: isWide
              ? null
              : AppBar(
                  backgroundColor: AppTheme.background,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 20,
                  title: Row(
                    children: [
                      const Icon(Icons.spa_rounded, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
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
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.perfilEspecialista),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE6E3),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.onSurfaceVariant, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer lateral (desktop)
              if (isWide) _SpecialistDrawer(currentIndex: _navIndex),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 48 : 20,
                    isWide ? 40 : 20,
                    isWide ? 48 : 20,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header "Schedule" + botón
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('schedule'),
                                  style: GoogleFonts.quicksand(
                                    fontSize: isWide ? 40 : 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                                Text(
                                  'Gestiona tus citas semanales.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogoNuevaCita,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'Programar Cita',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Navegador de semana
                  _WeekNavigator(
                    baseDate: _baseDate,
                    onPrev: () => setState(() =>
                        _baseDate = _baseDate.subtract(const Duration(days: 7))),
                    onNext: () => setState(() =>
                        _baseDate = _baseDate.add(const Duration(days: 7))),
                  ),

                  const SizedBox(height: 12),

                  // Grid semanal dinámico
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService.instance.streamCitasEspecialista(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: SelectableText(
                            'Error al cargar citas. Si te falta un índice, entra al enlace en tu consola:\n\n${snapshot.error}',
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      // Calcular el lunes de esta semana
                      int daysSinceMonday = _baseDate.weekday - 1;
                      DateTime monday =
                          _baseDate.subtract(Duration(days: daysSinceMonday));

                      final docs = snapshot.data?.docs ?? [];
                      List<List<SlotCita>> weekSlots =
                          List.generate(6, (_) => []);

                      for (var doc in docs) {
                        final data = doc.data();
                        final ts = data['fecha'] as Timestamp?;
                        if (ts == null) continue;
                        final date = ts.toDate();

                        // Verificar en qué día cae
                        for (int i = 0; i < 6; i++) {
                          DateTime d = monday.add(Duration(days: i));
                          if (date.year == d.year &&
                              date.month == d.month &&
                              date.day == d.day) {
                            final estadoStr =
                                data['estado'] as String? ?? 'pendiente';
                            SlotEstado estado = SlotEstado.pendiente;
                            if (estadoStr == 'confirmada') {
                              estado = SlotEstado.confirmada;
                            } else if (estadoStr == 'cancelada') {
                              estado = SlotEstado.cancelada;
                            }

                            // Si existe nombre del paciente lo usamos, si no el ID parcial
                            String pName = 'Paciente';
                            if (data.containsKey('pacienteNombre')) {
                              pName = data['pacienteNombre'];
                            } else if (data['pacienteId'] != null) {
                              String fullId = data['pacienteId'].toString();
                              pName = fullId.length > 5 ? 'Paciente (${fullId.substring(0, 4)})' : 'Paciente';
                            }

                            String formatTime(DateTime dt) {
                              final h = dt.hour;
                              final m = dt.minute.toString().padLeft(2, '0');
                              final period = h >= 12 ? 'PM' : 'AM';
                              final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
                              return '${h12.toString().padLeft(2, '0')}:$m $period';
                            }

                            final startTime = formatTime(date);
                            final endTime = formatTime(
                                date.add(const Duration(hours: 1)));

                            weekSlots[i].add(SlotCita(
                              estado: estado,
                              paciente: pName,
                              hora: '$startTime - $endTime',
                              mensaje: data['mensaje'] as String?,
                              modalidad: data['modalidad'] as String?,
                            ));
                          }
                        }
                      }

                      // Ordenar citas del día por hora si hay múltiples
                      for (int i = 0; i < 6; i++) {
                        // Por simplicidad, agregamos un "disponible" a las 9 AM si el día está vacío.
                        if (weekSlots[i].isEmpty) {
                          weekSlots[i].add(const SlotCita(
                              estado: SlotEstado.disponible,
                              hora: '09:00 AM'));
                        }
                      }

                      return _WeeklyGrid(baseDate: monday, slots: weekSlots);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  },
);
  }
}

// ---------------------------------------------------------------------------
// Drawer lateral (reutilizado del panel especialista)
// ---------------------------------------------------------------------------

class _SpecialistDrawer extends StatelessWidget {
  const _SpecialistDrawer({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (icon: Icons.dashboard_rounded, label: t('dashboard')),
      (icon: Icons.calendar_month_rounded, label: t('schedule')),
      (icon: Icons.search_rounded, label: t('search')),
    ];

    return Container(
      width: 280,
      constraints: const BoxConstraints(minHeight: double.infinity),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF2EF),
        border: Border(
          right: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
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
          const SizedBox(height: 28),

          // Avatar + info del especialista (clickable to profile)
          GestureDetector(
            onTap: () => context.push(AppRoutes.perfilEspecialista),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.surfaceVariant, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 28, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data() as Map<String, dynamic>?;
                          final nombre = data?['nombre'] ?? 'Dr. Specialist';
                          return Text(
                            nombre,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      ),
                      Text(
                        t('clinical_lead'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Online',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Nav links
          ...navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = i == currentIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () {
                  if (i == 0) context.go(AppRoutes.especialista);
                  if (i == 1) context.go(AppRoutes.calendario);
                  if (i == 2) context.go('${AppRoutes.especialista}?tab=2');
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? Border(
                            right: BorderSide(
                              color: AppTheme.primary,
                              width: 3,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const Spacer(),
          
          // Logout
          InkWell(
            onTap: () {
              AuthService.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Has cerrado sesión correctamente.'),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
              ));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 20, color: AppTheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar Sesión',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navegador de semana
// ---------------------------------------------------------------------------

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.baseDate,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime baseDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    int daysSinceMonday = baseDate.weekday - 1;
    DateTime monday = baseDate.subtract(Duration(days: daysSinceMonday));
    DateTime endOfWeek = monday.add(const Duration(days: 5));

    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    String weekLabel = '${meses[monday.month - 1]} ${monday.day} - ${meses[endOfWeek.month - 1]} ${endOfWeek.day}, ${monday.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppTheme.onSurfaceVariant),
            splashRadius: 20,
          ),
          Expanded(
            child: Text(
              weekLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceVariant),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid semanal
// ---------------------------------------------------------------------------

class _WeeklyGrid extends StatelessWidget {
  const _WeeklyGrid({required this.baseDate, required this.slots});
  final DateTime baseDate;
  final List<List<SlotCita>> slots;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isWide = MediaQuery.of(context).size.width >= 760;

    List<({String abrev, int num, bool esHoy})> buildDias() {
      final abreviaturas = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB'];
      return List.generate(6, (i) {
        DateTime d = baseDate.add(Duration(days: i));
        bool isToday = d.year == now.year && d.month == now.month && d.day == now.day;
        return (abrev: abreviaturas[i], num: d.day, esHoy: isToday);
      });
    }

    final diasSemana = buildDias();

    Widget content = Column(
      children: [
        // Cabecera de días
        IntrinsicHeight(
          child: Row(
            children: diasSemana.asMap().entries.map((e) {
              final i = e.key;
              final dia = e.value;
              final isLast = i == diasSemana.length - 1;
              return Expanded(
                child: _DayHeader(
                  abrev: dia.abrev,
                  num: dia.num,
                  esHoy: dia.esHoy,
                  showRightBorder: !isLast,
                ),
              );
            }).toList(),
          ),
        ),

        // Separador
        Divider(height: 1, color: AppTheme.surfaceVariant),

        // Slots por día
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: diasSemana.asMap().entries.map((e) {
              final i = e.key;
              final dia = e.value;
              final isLast = i == diasSemana.length - 1;
              return Expanded(
                child: _DayColumn(
                  esHoy: dia.esHoy,
                  slots: slots[i],
                  showRightBorder: !isLast,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );

    // En móviles, forzamos un ancho total de 960px y habilitamos el scroll
    if (!isWide) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 960,
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Header de día
// ---------------------------------------------------------------------------

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.abrev,
    required this.num,
    required this.esHoy,
    required this.showRightBorder,
  });

  final String abrev;
  final int num;
  final bool esHoy;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: esHoy
            ? AppTheme.secondaryContainer.withOpacity(0.2)
            : const Color(0xFFFAF7F5),
        border: Border(
          right: showRightBorder
              ? BorderSide(color: AppTheme.surfaceVariant)
              : BorderSide.none,
          top: esHoy
              ? const BorderSide(color: AppTheme.secondary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            abrev,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: esHoy ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 1,
              color: esHoy ? AppTheme.secondary : AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$num',
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: esHoy ? AppTheme.secondary : AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Columna de slots de un día
// ---------------------------------------------------------------------------

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.esHoy,
    required this.slots,
    required this.showRightBorder,
  });

  final bool esHoy;
  final List<SlotCita> slots;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: esHoy
            ? AppTheme.secondaryContainer.withOpacity(0.04)
            : Colors.transparent,
        border: Border(
          right: showRightBorder
              ? BorderSide(color: AppTheme.surfaceVariant)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: slots
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SlotCard(slot: s),
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de slot
// ---------------------------------------------------------------------------

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot});
  final SlotCita slot;

  Color get _barColor {
    switch (slot.estado) {
      case SlotEstado.confirmada:
        return AppTheme.secondary;
      case SlotEstado.atencionRequerida:
        return AppTheme.primary;
      case SlotEstado.pendiente:
        return const Color(0xFFF9BC54);
      case SlotEstado.cancelada:
        return AppTheme.outlineVariant;
      case SlotEstado.disponible:
        return Colors.transparent;
    }
  }

  Color get _badgeColor {
    switch (slot.estado) {
      case SlotEstado.confirmada:
        return AppTheme.secondary;
      case SlotEstado.atencionRequerida:
        return AppTheme.primary;
      case SlotEstado.pendiente:
        return const Color(0xFFF9BC54);
      case SlotEstado.cancelada:
        return AppTheme.outlineVariant;
      case SlotEstado.disponible:
        return Colors.transparent;
    }
  }

  String get _badgeLabel {
    switch (slot.estado) {
      case SlotEstado.confirmada:
        return 'Confirmada';
      case SlotEstado.atencionRequerida:
        return 'Atención Requerida';
      case SlotEstado.pendiente:
        return 'Pendiente';
      case SlotEstado.cancelada:
        return 'Cancelada';
      case SlotEstado.disponible:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Slot disponible
    if (slot.estado == SlotEstado.disponible) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.outlineVariant,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded,
                size: 20, color: AppTheme.outline),
            const SizedBox(height: 4),
            Text(
              'Disponible',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.outline,
              ),
            ),
            Text(
              slot.hora ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.outlineVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Slot con cita
    final isCancelled = slot.estado == SlotEstado.cancelada;
    final isUrgent = slot.estado == SlotEstado.atencionRequerida;

    void mostrarDetallesCita(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) {
          final isVirtual = slot.modalidad == 'virtual' || slot.modalidad == 'enLinea';
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isVirtual ? Icons.videocam_rounded : Icons.location_on_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detalle de la Cita',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alumno',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                ),
                Text(
                  slot.paciente ?? 'Estudiante',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  'Horario',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                ),
                Text(
                  slot.hora ?? '',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  'Modalidad',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                ),
                Text(
                  isVirtual ? 'Virtual (En línea)' : 'Presencial',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.onSurface, fontWeight: FontWeight.w600),
                ),
                if (slot.mensaje != null && slot.mensaje!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    isVirtual ? 'Enlace Virtual / Mensaje' : 'Detalles / Mensaje',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF2EF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: SelectableText(
                      slot.mensaje!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
            ],
          );
        },
      );
    }

    return InkWell(
      onTap: () => mostrarDetallesCita(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUrgent
                ? AppTheme.primary.withOpacity(0.4)
                : AppTheme.surfaceVariant,
          ),
          boxShadow: [
            if (!isCancelled)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Opacity(
          opacity: isCancelled ? 0.6 : 1.0,
          child: Row(
            children: [
              // Barra de color lateral
              Container(
                width: 4,
                color: _barColor,
              ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del paciente con badges visuales
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              slot.paciente ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (slot.modalidad == 'virtual' || slot.modalidad == 'enLinea')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.videocam_rounded, size: 14, color: AppTheme.primary),
                            ),
                          if (slot.mensaje != null && slot.mensaje!.trim().isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.description_rounded, size: 13, color: AppTheme.secondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Hora
                      Text(
                        slot.hora ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Badge de estado
                      Row(
                        children: [
                          if (isCancelled)
                            const Icon(Icons.cancel_outlined,
                                size: 11, color: AppTheme.outlineVariant)
                          else
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _badgeLabel,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isCancelled
                                      ? AppTheme.outlineVariant
                                      : _badgeColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
