import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio Firestore para todas las operaciones de datos de MentalData.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Check-ins de ánimo ───────────────────────────────────────────────────

  /// Guarda un check-in diario del alumno.
  Future<void> guardarCheckin({
    required int nivelAnimo,
    required String comentarios,
    String? horaDormir,
    String? horaDespertar,
    double? horasSueno,
  }) async {
    if (_uid == null) return;
    
    final batch = _db.batch();
    
    // 1. Guardar en el historial del alumno
    final checkinRef = _db.collection('usuarios').doc(_uid).collection('checkins').doc();
    batch.set(checkinRef, {
      'fecha': FieldValue.serverTimestamp(),
      'nivelAnimo': nivelAnimo,
      'comentarios': comentarios,
      if (horaDormir != null) 'horaDormir': horaDormir,
      if (horaDespertar != null) 'horaDespertar': horaDespertar,
      if (horasSueno != null) 'horasSueno': horasSueno,
    });

    // 2. Obtener el nombre del alumno para el panel
    final userDoc = await _db.collection('usuarios').doc(_uid).get();
    final nombre = userDoc.data()?['nombre'] ?? 'Paciente';

    // 3. Lógica temporal de riesgo basada en ánimo
    String riesgo = 'bajo';
    if (nivelAnimo <= 3) {
      riesgo = 'alto';
    } else if (nivelAnimo <= 6) riesgo = 'moderado';

    // 4. Actualizar el tablero del especialista
    final pacienteRef = _db.collection('pacientes').doc(_uid);
    batch.set(pacienteRef, {
      'nombre': nombre,
      'riesgo': riesgo,
      'ultimaActividad': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Stream de los últimos 30 check-ins del alumno.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCheckins() {
    if (_uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('usuarios')
        .doc(_uid)
        .collection('checkins')
        .orderBy('fecha', descending: true)
        .limit(30)
        .snapshots();
  }

  /// Stream de los últimos 30 check-ins de un paciente específico.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCheckinsPaciente(String pacienteId) {
    return _db
        .collection('usuarios')
        .doc(pacienteId)
        .collection('checkins')
        .orderBy('fecha', descending: true)
        .limit(30)
        .snapshots();
  }

  // ── Triaje ───────────────────────────────────────────────────────────────

  /// Guarda un registro de triaje del alumno.
  Future<void> guardarTriaje({
    required int ansiedad,
    required int depresion,
    required String nivelRiesgo, // "bajo" | "moderado" | "alto"
  }) async {
    if (_uid == null) return;

    final batch = _db.batch();

    // Subcolección personal bajo el usuario
    final triajeRef = _db
        .collection('usuarios')
        .doc(_uid)
        .collection('triajes')
        .doc();
    batch.set(triajeRef, {
      'fecha': FieldValue.serverTimestamp(),
      'ansiedad': ansiedad,
      'depresion': depresion,
      'nivelRiesgo': nivelRiesgo,
    });

    // Obtener nombre
    final userDoc = await _db.collection('usuarios').doc(_uid).get();
    final nombre = userDoc.data()?['nombre'] ?? 'Paciente';

    // Actualizar resumen en el documento del paciente (para el especialista)
    final pacienteRef = _db.collection('pacientes').doc(_uid);
    batch.set(pacienteRef, {
      'nombre': nombre,
      'riesgo': nivelRiesgo,
      'ultimaActividad': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Stream del historial de triajes de un paciente específico.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamTriajesPaciente(String pacienteId) {
    return _db
        .collection('usuarios')
        .doc(pacienteId)
        .collection('triajes')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ── Pacientes (vista del especialista) ───────────────────────────────────

  /// Stream de todos los pacientes (solo para especialistas).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPacientes() {
    return _db
        .collection('pacientes')
        .orderBy('ultimaActividad', descending: true)
        .snapshots();
  }

  /// Stream de los datos base de un paciente en específico.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamPacienteBase(String pacienteId) {
    return _db.collection('pacientes').doc(pacienteId).snapshots();
  }

  // ── Citas ─────────────────────────────────────────────────────────────────

  /// Stream de citas del alumno actual.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMisCitas() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('citas')
        .where('pacienteId', isEqualTo: _uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  /// Stream de citas del especialista.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCitasEspecialista() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('citas')
        .where('especialistaId', isEqualTo: _uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  /// Stream de citas de un paciente específico.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCitasPaciente(String pacienteId) {
    return _db
        .collection('citas')
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  /// Crea una nueva cita.
  Future<void> crearCita({
    required String pacienteId,
    required String especialistaId,
    required DateTime fecha,
    required String modalidad,
    String? mensaje,
    String estado = 'confirmada',
  }) async {
    // Obtenemos el nombre del especialista para la tarjeta
    final doc = await _db.collection('usuarios').doc(especialistaId).get();
    final especialistaNombre = doc.data()?['nombre'] ?? 'Dr. Especialista';

    // Obtenemos el nombre del paciente para que el calendario lo muestre
    final pacDoc = await _db.collection('pacientes').doc(pacienteId).get();
    final pacienteNombre = pacDoc.data()?['nombre'] ?? 'Estudiante';

    await _db.collection('citas').add({
      'pacienteId': pacienteId,
      'pacienteNombre': pacienteNombre,
      'especialistaId': especialistaId,
      'especialistaNombre': especialistaNombre,
      'fecha': Timestamp.fromDate(fecha),
      'modalidad': modalidad,
      'mensaje': mensaje,
      'estado': estado,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza el estado de una cita.
  Future<void> actualizarEstadoCita(
    String citaId,
    String nuevoEstado,
  ) async {
    await _db.collection('citas').doc(citaId).update({
      'estado': nuevoEstado,
    });
  }

  // ── Notas Clínicas ────────────────────────────────────────────────────────

  /// Stream de las notas clínicas de un paciente.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotasClinicasPaciente(String pacienteId) {
    return _db
        .collection('pacientes')
        .doc(pacienteId)
        .collection('notasClinicas')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  /// Guarda o actualiza una nota clínica.
  Future<void> guardarNotaClinica({
    required String pacienteId,
    required String contenido,
    String? notaId,
    List<dynamic>? historialPrevio,
  }) async {
    final noteRef = notaId != null
        ? _db.collection('pacientes').doc(pacienteId).collection('notasClinicas').doc(notaId)
        : _db.collection('pacientes').doc(pacienteId).collection('notasClinicas').doc();

    final data = <String, dynamic>{
      'contenido': contenido,
      'fecha': FieldValue.serverTimestamp(),
      'creadoPor': _uid ?? 'especialista',
    };

    if (notaId != null && historialPrevio != null) {
      data['historial'] = historialPrevio;
    }

    await noteRef.set(data, SetOptions(merge: true));
  }

  // ── Plan de Acción ────────────────────────────────────────────────────────

  /// Guarda el plan de acción en el documento del paciente.
  Future<void> guardarPlanDeAccion({
    required String pacienteId,
    required List<String> plan,
  }) async {
    await _db.collection('pacientes').doc(pacienteId).set({
      'planDeAccion': plan,
      'planActualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Análisis Clínico IA ───────────────────────────────────────────────────

  /// Guarda el reporte de análisis clínico de Gemini en el paciente.
  Future<void> guardarAnalisisIA({
    required String pacienteId,
    required String analisisText,
  }) async {
    await _db.collection('pacientes').doc(pacienteId).set({
      'ultimoAnalisisIA': analisisText,
      'analisisIaActualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
