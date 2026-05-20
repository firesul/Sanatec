import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/auth/presentation/login_screen.dart';
import 'package:myapp/features/calendario/presentation/calendario_screen.dart';
import 'package:myapp/features/checkin/presentation/checkin_diario_screen.dart';
import 'package:myapp/features/citas/presentation/mis_citas_screen.dart';
import 'package:myapp/features/especialista/presentation/panel_especialista_screen.dart';
import 'package:myapp/features/expediente/presentation/expediente_paciente_screen.dart';
import 'package:myapp/features/perfil/presentation/perfil_screen.dart';
import 'package:myapp/features/perfil/presentation/perfil_especialista_screen.dart';
import 'package:myapp/features/especialista/presentation/todos_pacientes_screen.dart';
import 'package:myapp/features/triaje/presentation/triaje_screen.dart';

// ---------------------------------------------------------------------------
// Rutas
// ---------------------------------------------------------------------------

class AppRoutes {
  AppRoutes._();
  static const login        = '/';
  static const home         = '/home';
  static const triaje       = '/triaje';
  static const citas        = '/citas';
  static const expediente   = '/expediente';
  static const especialista = '/especialista';
  static const calendario   = '/calendario';
  static const perfil       = '/perfil';
  static const perfilEspecialista = '/perfil-especialista';
  static const todosPacientes = '/todos-pacientes';
}

// ---------------------------------------------------------------------------
// Listenable que reacciona al stream de auth (síncrono)
// ---------------------------------------------------------------------------

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthChangeNotifier();

// ---------------------------------------------------------------------------
// Router — redirect SÍNCRONO (sin await)
// ---------------------------------------------------------------------------

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  refreshListenable: _authNotifier,

  // Redirect síncrono: solo protege rutas. La lógica de rol queda
  // en el login handler (ya implementada en login_screen.dart).
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final onLogin = state.matchedLocation == AppRoutes.login;

    // No autenticado y quiere ir a ruta protegida → al login
    if (user == null && !onLogin) return AppRoutes.login;

    return null;
  },

  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const CheckinDiarioScreen(),
    ),
    GoRoute(
      path: AppRoutes.triaje,
      builder: (context, state) => const TriajeScreen(),
    ),
    GoRoute(
      path: AppRoutes.citas,
      builder: (context, state) => const MisCitasScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.expediente}/:id',
      builder: (context, state) => ExpedientePacienteScreen(
        pacienteId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.especialista,
      builder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'];
        final initialTab = tabStr != null ? int.tryParse(tabStr) : null;
        return PanelEspecialistaScreen(initialTab: initialTab);
      },
    ),
    GoRoute(
      path: AppRoutes.calendario,
      builder: (context, state) => const CalendarioScreen(),
    ),
    GoRoute(
      path: AppRoutes.perfil,
      builder: (context, state) => const PerfilScreen(),
    ),
    GoRoute(
      path: AppRoutes.perfilEspecialista,
      builder: (context, state) => const PerfilEspecialistaScreen(),
    ),
    GoRoute(
      path: AppRoutes.todosPacientes,
      builder: (context, state) => const TodosPacientesScreen(),
    ),
  ],
);
