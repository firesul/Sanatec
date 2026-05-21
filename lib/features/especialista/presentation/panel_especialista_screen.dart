import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/router/app_router.dart';
import 'package:myapp/core/services/firestore_service.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/services/translation_service.dart';
import 'package:myapp/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo de datos local
// ---------------------------------------------------------------------------

enum RiesgoPaciente { urgente, observacion, estable }

class PacienteResumen {
  const PacienteResumen({
    required this.id,
    required this.nombre,
    required this.ultimaActividad,
    required this.riesgo,
  });

  final String id;
  final String nombre;
  final String ultimaActividad;
  final RiesgoPaciente riesgo;

  factory PacienteResumen.fromFirestore(String id, Map<String, dynamic> data) {
    final riesgoStr = data['riesgo'] as String? ?? 'bajo';
    RiesgoPaciente riesgo = RiesgoPaciente.estable;
    if (riesgoStr == 'alto') {
      riesgo = RiesgoPaciente.urgente;
    } else if (riesgoStr == 'moderado') {
      riesgo = RiesgoPaciente.observacion;
    }

    final timestamp = data['ultimaActividad'] as Timestamp?;
    String lastAct = 'Desconocido';
    if (timestamp != null) {
      final diff = DateTime.now().difference(timestamp.toDate());
      if (diff.inMinutes < 60) {
        lastAct = diff.inMinutes <= 1 ? 'Ahora mismo' : 'Hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        lastAct = 'Hace ${diff.inHours} horas';
      } else if (diff.inDays == 1) {
        lastAct = 'Ayer';
      } else {
        lastAct = 'Hace ${diff.inDays} días';
      }
    }

    return PacienteResumen(
      id: id,
      nombre: data['nombre'] as String? ?? 'Paciente sin nombre',
      ultimaActividad: lastAct,
      riesgo: riesgo,
    );
  }
}

// ---------------------------------------------------------------------------
// Screen principal
// ---------------------------------------------------------------------------

class PanelEspecialistaScreen extends StatefulWidget {
  const PanelEspecialistaScreen({super.key, this.initialTab});
  final int? initialTab;

  @override
  State<PanelEspecialistaScreen> createState() =>
      _PanelEspecialistaScreenState();
}

class _PanelEspecialistaScreenState
    extends State<PanelEspecialistaScreen> {
  late int _navIndex;
  String _searchQuery = '';
  RiesgoPaciente? _filtroRiesgo;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _pacientesStream;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialTab ?? 0;
    _pacientesStream = FirestoreService.instance.streamPacientes();
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              setState(() => _navIndex = i);
              if (i == 1) context.go(AppRoutes.calendario);
            },
            backgroundColor: const Color(0xFFFBF2EF),
            indicatorColor: AppTheme.primary.withOpacity(0.15),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.dashboard_rounded), selectedIcon: const Icon(Icons.dashboard_rounded, color: AppTheme.primary), label: t('dashboard')),
              NavigationDestination(icon: const Icon(Icons.calendar_month_rounded), selectedIcon: const Icon(Icons.calendar_month_rounded, color: AppTheme.primary), label: t('schedule')),
              NavigationDestination(icon: const Icon(Icons.search_rounded), selectedIcon: const Icon(Icons.search_rounded, color: AppTheme.primary), label: t('search')),
              const NavigationDestination(icon: Icon(Icons.group_add_rounded), selectedIcon: Icon(Icons.group_add_rounded, color: AppTheme.primary), label: 'Equipo'),
            ],
          ),
          // AppBar solo en móvil
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
                      Image.asset(
                        'assets/logo_sin_fondo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SanaTec',
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
                            border: Border.all(
                                color: AppTheme.outlineVariant, width: 0.5),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppTheme.onSurfaceVariant, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
          body: Row(
            children: [
              // ---- Drawer lateral (solo en web/escritorio) ----
              if (isWide)
                _SpecialistDrawer(
                  currentIndex: _navIndex,
                  onNavTap: (i) => setState(() => _navIndex = i),
                ),

              // ---- Contenido principal ----
              Expanded(
                child: _navIndex == 3
                    ? const _GestionarEquipoView()
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _pacientesStream,
                        builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SelectableText(
                        'Error al cargar pacientes. Si falta índice, usa este link:\n${snapshot.error}',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var pacientes = docs.map((d) => PacienteResumen.fromFirestore(d.id, d.data())).toList();

                if (_searchQuery.isNotEmpty) {
                  pacientes = pacientes.where((p) => p.nombre.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }
                if (_filtroRiesgo != null) {
                  pacientes = pacientes.where((p) => p.riesgo == _filtroRiesgo).toList();
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 48 : 20,
                    isWide ? 48 : 24,
                    isWide ? 48 : 20,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Text(
                        'Resumen de Pacientes',
                        style: GoogleFonts.quicksand(
                          fontSize: isWide ? 40 : 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Lista de seguimiento clasificada por nivel de riesgo clínico.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_navIndex == 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: TextField(
                            controller: _searchController,
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

                      // Grid responsivo
                      isWide
                          ? _DashboardGridWide(pacientes: pacientes, onFilterSelected: (r) => setState(() => _filtroRiesgo = r))
                          : _DashboardGridNarrow(pacientes: pacientes, onFilterSelected: (r) => setState(() => _filtroRiesgo = r)),
                    ],
                  ),
                );
              }
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
// Drawer lateral del especialista
// ---------------------------------------------------------------------------

class _SpecialistDrawer extends StatelessWidget {
  const _SpecialistDrawer({
    required this.currentIndex,
    required this.onNavTap,
  });

  final int currentIndex;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (icon: Icons.dashboard_rounded, label: t('dashboard')),
      (icon: Icons.calendar_month_rounded, label: t('schedule')),
      (icon: Icons.search_rounded, label: t('search')),
      (icon: Icons.group_add_rounded, label: 'Gestionar Equipo'),
    ];

    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF2EF),
        border: Border(
          right: BorderSide(
            color: AppTheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Image.asset(
                'assets/logo_sin_fondo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'SanaTec',
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Perfil del especialista (clickable to profile)
          GestureDetector(
            onTap: () => context.push(AppRoutes.perfilEspecialista),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final nombre = data?['nombre'] ?? 'Dr. Specialist';
                    return Text(
                      nombre,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    );
                  }
                ),
                Text(
                  t('clinical_lead'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                // Indicador Online
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Nav links
          ...navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = i == currentIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () {
                  onNavTap(i);
                  // Navegar según el índice
                  if (i == 0) context.go(AppRoutes.especialista);
                  if (i == 1) context.go(AppRoutes.calendario);
                },
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(99),
                  bottomRight: Radius.circular(99),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    border: isActive
                        ? const Border(
                            right: BorderSide(
                              color: AppTheme.primary,
                              width: 3,
                            ),
                          )
                        : null,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(99),
                      bottomRight: Radius.circular(99),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
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
// Grid en pantallas anchas (lado a lado)
// ---------------------------------------------------------------------------

class _DashboardGridWide extends StatelessWidget {
  const _DashboardGridWide({required this.pacientes, required this.onFilterSelected});
  final List<PacienteResumen> pacientes;
  final ValueChanged<RiesgoPaciente?> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: métricas (1/3)
        SizedBox(width: 280, child: _TriajeMetricsCard(pacientes: pacientes)),
        const SizedBox(width: 24),
        // Columna derecha: lista de pacientes (2/3)
        Expanded(child: _RiesgoActivoCard(pacientes: pacientes, onFilterSelected: onFilterSelected)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grid en pantallas estrechas (apilado)
// ---------------------------------------------------------------------------

class _DashboardGridNarrow extends StatelessWidget {
  const _DashboardGridNarrow({required this.pacientes, required this.onFilterSelected});
  final List<PacienteResumen> pacientes;
  final ValueChanged<RiesgoPaciente?> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TriajeMetricsCard(pacientes: pacientes),
        const SizedBox(height: 20),
        _RiesgoActivoCard(pacientes: pacientes, onFilterSelected: onFilterSelected),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta: Métricas de Triage
// ---------------------------------------------------------------------------

class _TriajeMetricsCard extends StatelessWidget {
  const _TriajeMetricsCard({required this.pacientes});
  final List<PacienteResumen> pacientes;

  @override
  Widget build(BuildContext context) {
    final urgentes = pacientes.where((p) => p.riesgo == RiesgoPaciente.urgente).length;
    final obs = pacientes.where((p) => p.riesgo == RiesgoPaciente.observacion).length;
    final estables = pacientes.where((p) => p.riesgo == RiesgoPaciente.estable).length;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MÉTRICAS DE TRIAGE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _MetricRow(
            iconBg: AppTheme.errorContainer,
            iconColor: AppTheme.onErrorContainer,
            icon: Icons.emergency_rounded,
            count: urgentes,
            label: 'Atención Urgente',
          ),
          const SizedBox(height: 20),
          _MetricRow(
            iconBg: const Color(0xFFFFDEAD),
            iconColor: const Color(0xFF604100),
            icon: Icons.visibility_rounded,
            count: obs,
            label: 'En Observación',
          ),
          const SizedBox(height: 20),
          _MetricRow(
            iconBg: AppTheme.secondaryContainer,
            iconColor: AppTheme.onSecondaryContainer,
            icon: Icons.check_circle_rounded,
            count: estables,
            label: 'Estables',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.count,
    required this.label,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: GoogleFonts.quicksand(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta: Lista de Riesgo Activa
// ---------------------------------------------------------------------------

class _RiesgoActivoCard extends StatelessWidget {
  const _RiesgoActivoCard({required this.pacientes, required this.onFilterSelected});
  final List<PacienteResumen> pacientes;
  final ValueChanged<RiesgoPaciente?> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          // Header con "Filtrar"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Lista de Riesgo Activa',
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<RiesgoPaciente?>(
                onSelected: onFilterSelected,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('Todos los pacientes')),
                  const PopupMenuItem(value: RiesgoPaciente.urgente, child: Text('Atención Urgente')),
                  const PopupMenuItem(value: RiesgoPaciente.observacion, child: Text('En Observación')),
                  const PopupMenuItem(value: RiesgoPaciente.estable, child: Text('Estables')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 20, color: AppTheme.secondary),
                      const SizedBox(width: 8),
                      Text('Filtrar', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.secondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (pacientes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No hay pacientes en seguimiento.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            )
          else
            // Filas de pacientes
            ...pacientes.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PacienteRow(paciente: p),
              ),
            ),

          const SizedBox(height: 8),

          // "Ver todos los pacientes →"
          Center(
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.todosPacientes),
              icon: Text(
                'Ver todos los pacientes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              label: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppTheme.primary),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila de paciente con barra de color lateral
// ---------------------------------------------------------------------------

class _PacienteRow extends StatelessWidget {
  const _PacienteRow({required this.paciente});
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
    final isUrgent = paciente.riesgo == RiesgoPaciente.urgente;

    return GestureDetector(
      onTap: () => context.go('${AppRoutes.expediente}/${paciente.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _rowBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
        children: [
          // Barra de color lateral
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: _barColor.withOpacity(
                  paciente.riesgo == RiesgoPaciente.estable ? 0.7 : 1.0),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 16),

          // Nombre + tiempo
          Flexible(
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
                    const Icon(Icons.schedule_rounded,
                        size: 13, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
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

          const SizedBox(width: 8),

          // Botón "Ver Expediente"
          if (isUrgent)
            ElevatedButton(
              onPressed: () => context.go('${AppRoutes.expediente}/${paciente.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver Expediente',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            OutlinedButton(
              onPressed: () => context.go('${AppRoutes.expediente}/${paciente.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: paciente.riesgo == RiesgoPaciente.estable
                    ? AppTheme.onSurfaceVariant
                    : AppTheme.secondary,
                side: BorderSide(
                  color: paciente.riesgo == RiesgoPaciente.estable
                      ? AppTheme.outlineVariant
                      : AppTheme.secondary,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver Expediente',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// Contenedor de tarjeta reutilizable
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B19).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Vista de gestión de psicólogos y médicos especialistas
// ---------------------------------------------------------------------------

class _GestionarEquipoView extends StatefulWidget {
  const _GestionarEquipoView();

  @override
  State<_GestionarEquipoView> createState() => _GestionarEquipoViewState();
}

class _GestionarEquipoViewState extends State<_GestionarEquipoView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _rolSeleccionado = 'especialista';
  bool _isRegistering = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrarEspecialista() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final rol = _rolSeleccionado;

    try {
      // Registrar un usuario secundario sin cerrar sesión usando un FirebaseApp temporal
      final tempApp = await Firebase.initializeApp(
        name: 'TemporaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final userCred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: correo, password: password);

      // Guardar el perfil en la colección usuarios
      await FirebaseFirestore.instance.collection('usuarios').doc(userCred.user!.uid).set({
        'nombre': nombre,
        'correo': correo,
        'rol': rol,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      // Limpiar app temporal de memoria
      await tempApp.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Especialista "$nombre" registrado con éxito!'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
        ));
        _nombreCtrl.clear();
        _correoCtrl.clear();
        _passwordCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isWide ? 48 : 20,
        isWide ? 48 : 24,
        isWide ? 48 : 20,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Gestión de Especialistas',
            style: GoogleFonts.quicksand(
              fontSize: isWide ? 40 : 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Administra el equipo clínico de psicólogos y médicos autorizados en SanaTec.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel izquierdo: Formulario de registro (3/5 de ancho si es wide, de lo contrario expandido)
              Expanded(
                flex: isWide ? 3 : 1,
                child: _Card(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REGISTRAR NUEVO ESPECIALISTA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Nombre
                        Text(
                          'Nombre Completo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: InputDecoration(
                            hintText: 'Ej. Dra. María López',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
                        ),
                        const SizedBox(height: 20),

                        // Correo
                        Text(
                          'Correo Electrónico',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _correoCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'ejemplo@sanatec.com',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el correo' : null,
                        ),
                        const SizedBox(height: 20),

                        // Contraseña
                        Text(
                          'Contraseña Temporal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Min. 6 caracteres',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                        ),
                        const SizedBox(height: 20),

                        // Rol
                        Text(
                          'Rol en el Portal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _rolSeleccionado,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'especialista',
                              child: Text(
                                'Psicólogo Clínico / Terapeuta',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'medico',
                              child: Text(
                                'Médico Psiquiatra',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _rolSeleccionado = v);
                            }
                          },
                        ),
                        const SizedBox(height: 32),

                        // Botón de Envío
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isRegistering ? null : _registrarEspecialista,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: _isRegistering 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))
                                  )
                                : const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(
                              _isRegistering ? 'Registrando...' : 'Registrar Especialista',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Panel derecho: Lista del equipo (solo visible en pantallas anchas para no apretar el diseño móvil)
              if (isWide) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EQUIPO CLÍNICO AUTORIZADO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('usuarios')
                              .where('rol', whereIn: ['especialista', 'medico'])
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No hay otros especialistas registrados.',
                                    style: GoogleFonts.plusJakartaSans(
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
                              separatorBuilder: (_, __) => const Divider(height: 16),
                              itemBuilder: (context, index) {
                                final data = docs[index].data() as Map<String, dynamic>;
                                final nombre = data['nombre'] ?? 'Sin nombre';
                                final correo = data['correo'] ?? 'Sin correo';
                                final rol = data['rol'] == 'medico' ? 'Médico' : 'Psicólogo';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.secondary.withOpacity(0.1),
                                    child: Icon(
                                      data['rol'] == 'medico' 
                                          ? Icons.medical_services_rounded 
                                          : Icons.psychology_rounded,
                                      color: AppTheme.secondary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    nombre,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$correo • $rol',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
