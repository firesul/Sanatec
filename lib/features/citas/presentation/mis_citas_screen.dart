import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/services/notification_service.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/shared/widgets/app_bottom_nav_bar.dart';
import 'package:myapp/shared/widgets/app_top_bar.dart';

// ---------------------------------------------------------------------------
// Modelo de datos local (se reemplazará con Firestore)
// ---------------------------------------------------------------------------

enum CitaEstado { confirmada, pendiente, completada }

enum CitaModalidad { enLinea, presencial }

class CitaModel {
  const CitaModel({
    required this.id,
    required this.fecha,
    required this.dia,
    required this.mes,
    required this.horaInicio,
    required this.horaFin,
    required this.modalidad,
    required this.lugar,
    required this.especialista,
    required this.estado,
  });

  final String id;
  final DateTime fecha;
  final int dia;
  final String mes;
  final String horaInicio;
  final String horaFin;
  final CitaModalidad modalidad;
  final String lugar;
  final String especialista;
  final CitaEstado estado;

  factory CitaModel.fromFirestore(String id, Map<String, dynamic> data) {
    final fechaTs = data['fecha'] as Timestamp?;
    final date = fechaTs?.toDate() ?? DateTime.now();

    final meses = ['ENE','FEB','MAR','ABR','MAY','JUN','JUL','AGO','SEP','OCT','NOV','DIC'];
    final mesStr = meses[date.month - 1];

    final estadoStr = data['estado'] as String? ?? 'pendiente';
    CitaEstado estado;
    if (estadoStr == 'confirmada') {
      estado = CitaEstado.confirmada;
    } else if (estadoStr == 'completada') {
      estado = CitaEstado.completada;
    } else {
      estado = CitaEstado.pendiente;
    }

    final modalidadStr = data['modalidad'] as String? ?? 'enLinea';
    final modalidad = modalidadStr == 'presencial' ? CitaModalidad.presencial : CitaModalidad.enLinea;
    final lugar = data['lugar'] as String? ?? (modalidad == CitaModalidad.enLinea ? 'En línea' : 'Consultorio asignado');
    
    // Si no tenemos el nombre en el documento, ponemos un placeholder
    final especialista = data['especialistaNombre'] as String? ?? 'Especialista Asignado';

    final horaFin = date.add(const Duration(hours: 1));

    String formatTime(DateTime d) {
      final h = d.hour;
      final m = d.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '${h12.toString().padLeft(2, '0')}:$m $period';
    }

    return CitaModel(
      id: id,
      fecha: date,
      dia: date.day,
      mes: mesStr,
      horaInicio: formatTime(date),
      horaFin: formatTime(horaFin),
      modalidad: modalidad,
      lugar: lugar,
      especialista: especialista,
      estado: estado,
    );
  }
}


// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  int _currentNavIndex = 2; // Tab "Citas" activo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Encabezado de página ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Citas',
                  style: GoogleFonts.quicksand(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gestiona tus sesiones programadas y su modalidad.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // --- Lista de citas ---
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.streamMisCitas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  // Muestra el link para crear el índice en Firebase si falta
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SelectableText(
                        'Error al cargar citas. Si te falta un índice, entra al enlace en tu consola:\n\n${snapshot.error}',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes citas programadas aún.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final cita = CitaModel.fromFirestore(docs[index].id, data);
                    
                    // Programar notificaciones de cita de forma reactiva
                    if (cita.estado != CitaEstado.completada && cita.fecha.isAfter(DateTime.now())) {
                      NotificationService.instance.scheduleCitaNotifications(
                        citaId: cita.id.hashCode.abs(),
                        citaTime: cita.fecha,
                        title: cita.especialista,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CitaCard(cita: cita),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidget: CitaCard
// ---------------------------------------------------------------------------

class CitaCard extends StatelessWidget {
  const CitaCard({super.key, required this.cita});
  final CitaModel cita;

  /// Colores del chip según el estado
  ({Color bg, Color text, Color dot}) get _statusColors {
    switch (cita.estado) {
      case CitaEstado.confirmada:
        return (
          bg: AppTheme.secondaryContainer,
          text: AppTheme.onSecondaryContainer,
          dot: AppTheme.secondary,
        );
      case CitaEstado.pendiente:
        return (
          bg: const Color(0xFFFFDEAD).withOpacity(0.5),
          text: const Color(0xFF7C5400),
          dot: const Color(0xFF7C5400),
        );
      case CitaEstado.completada:
        return (
          bg: AppTheme.surfaceVariant,
          text: AppTheme.onSurfaceVariant,
          dot: AppTheme.onSurfaceVariant,
        );
    }
  }

  String get _statusLabel {
    switch (cita.estado) {
      case CitaEstado.confirmada:
        return 'Confirmada';
      case CitaEstado.pendiente:
        return 'Pendiente';
      case CitaEstado.completada:
        return 'Completada';
    }
  }

  bool get _isCompleted => cita.estado == CitaEstado.completada;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors;

    return Opacity(
      opacity: _isCompleted ? 0.75 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1B19).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Caja de fecha ---
              _DateBox(
                dia: cita.dia,
                mes: cita.mes,
                isCompleted: _isCompleted,
              ),

              const SizedBox(width: 20),

              // --- Detalles ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horario
                    Text(
                      '${cita.horaInicio} – ${cita.horaFin}',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Modalidad con ícono
                    Row(
                      children: [
                        Icon(
                          cita.modalidad == CitaModalidad.enLinea
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cita.lugar,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Especialista con avatar
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cita.especialista,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Chip de estado
                    _StatusChip(
                      label: _statusLabel,
                      isCompleted: _isCompleted,
                      bgColor: colors.bg,
                      textColor: colors.text,
                      dotColor: colors.dot,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidget: DateBox
// ---------------------------------------------------------------------------

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.dia,
    required this.mes,
    required this.isCompleted,
  });

  final int dia;
  final String mes;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.surfaceVariant
            : const Color(0xFFF5ECE9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dia.toString().padLeft(2, '0'),
            style: GoogleFonts.quicksand(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isCompleted
                  ? AppTheme.onSurfaceVariant
                  : AppTheme.primary,
            ),
          ),
          Text(
            mes.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidget: StatusChip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isCompleted,
    required this.bgColor,
    required this.textColor,
    required this.dotColor,
  });

  final String label;
  final bool isCompleted;
  final Color bgColor;
  final Color textColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            Icon(Icons.check_rounded, size: 13, color: textColor)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
