import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de autenticación con Firebase Auth.
/// Maneja login, registro y cierre de sesión.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Stream del usuario actual (null = no autenticado)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Login con email/contraseña ───────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Registro de nuevo usuario ────────────────────────────────────────────

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    required String rol, // "alumno" | "especialista"
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Crear documento de usuario en Firestore
    await _firestore
        .collection('usuarios')
        .doc(credential.user!.uid)
        .set({
      'nombre': nombre,
      'email': email.trim(),
      'rol': rol,
      'creadoEn': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // ── Obtener rol del usuario actual ───────────────────────────────────────

  Future<String?> getUserRole(String uid) async {
    final doc =
        await _firestore.collection('usuarios').doc(uid).get();
    return doc.data()?['rol'] as String?;
  }

  // ── Cerrar sesión ────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();
}
