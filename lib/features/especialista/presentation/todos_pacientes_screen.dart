import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/router/app_router.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/features/especialista/presentation/panel_especialista_screen.dart';

class TodosPacientesScreen extends StatefulWidget {
  const TodosPacientesScreen({super.key});

  @override
  State<TodosPacientesScreen> createState() => _TodosPacientesScreenState();
}

class _TodosPacientesScreenState extends State<TodosPacientesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Directorio de Pacientes',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.outlineVariant.withOpacity(0.4)),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar paciente por nombre...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                ),
              ),
            ),
          ),

          // Lista de pacientes
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.streamPacientes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar pacientes.', style: GoogleFonts.plusJakartaSans(color: AppTheme.error)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var pacientes = docs.map((d) => PacienteResumen.fromFirestore(d.id, d.data())).toList();

                if (_searchQuery.isNotEmpty) {
                  pacientes = pacientes.where((p) => p.nombre.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }

                if (pacientes.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron pacientes.',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: pacientes.length,
                  itemBuilder: (context, index) {
                    final paciente = pacientes[index];
                    return _PacienteDirectorioRow(paciente: paciente);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PacienteDirectorioRow extends StatelessWidget {
  const _PacienteDirectorioRow({required this.paciente});
  final PacienteResumen paciente;

  Color get _barColor {
    switch (paciente.riesgo) {
      case RiesgoPaciente.urgente:
        return AppTheme.error;
      case RiesgoPaciente.observacion:
        return const Color(0xFF7C5400);
      case RiesgoPaciente.estable:
        return AppTheme.secondary;
    }
  }

  Color get _rowBg {
    switch (paciente.riesgo) {
      case RiesgoPaciente.urgente:
        return AppTheme.errorContainer.withOpacity(0.12);
      case RiesgoPaciente.observacion:
        return Colors.white;
      case RiesgoPaciente.estable:
        return const Color(0xFFFBF2EF).withOpacity(0.5);
    }
  }

  Color get _borderColor {
    switch (paciente.riesgo) {
      case RiesgoPaciente.urgente:
        return AppTheme.errorContainer;
      case RiesgoPaciente.observacion:
        return AppTheme.outlineVariant.withOpacity(0.5);
      case RiesgoPaciente.estable:
        return AppTheme.outlineVariant.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push('${AppRoutes.expediente}/${paciente.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _rowBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              // Barra de color
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _barColor.withOpacity(paciente.riesgo == RiesgoPaciente.estable ? 0.7 : 1.0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente.nombre,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            paciente.ultimaActividad,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón Expediente
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
                ),
                child: const Icon(Icons.folder_shared_rounded, size: 18, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
