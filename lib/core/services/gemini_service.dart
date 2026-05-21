import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:myapp/core/config/env.dart';

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  
  GeminiService._internal() {
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: _apiKey,
    );
  }

  // API Key consumida desde el archivo de configuración ignorado
  final String _apiKey = Env.geminiApiKey;
  late final GenerativeModel _model;

  /// Genera un análisis clínico para el especialista basado en el historial del estudiante
  Future<String> generarAnalisisClinico({
    required String nombre,
    required String carrera,
    required String edad,
    required List<Map<String, dynamic>> checkins,
    required List<Map<String, dynamic>> triajes,
    double animoPromedioSemanal = 0,
    double suenoPromedioSemanal = 0,
  }) async {
    // Construir un resumen legible de los datos para la IA
    final buffer = StringBuffer();
    buffer.writeln("Paciente: $nombre");
    buffer.writeln("Carrera: $carrera");
    buffer.writeln("Edad: $edad años");
    
    buffer.writeln("\n--- RESUMEN SEMANAL DE TENDENCIA ---");
    buffer.writeln("Ánimo promedio semanal: ${animoPromedioSemanal.toStringAsFixed(1)}/10");
    buffer.writeln("Horas de sueño promedio semanal: ${suenoPromedioSemanal.toStringAsFixed(1)} horas");
    
    buffer.writeln("\n--- HISTORIAL DE MONITOREO DIARIO (Check-ins) ---");
    if (checkins.isEmpty) {
      buffer.writeln("No hay check-ins registrados.");
    } else {
      for (final c in checkins) {
        buffer.writeln("- Fecha: ${c['fecha']}, Nivel de Ánimo: ${c['nivelAnimo']}/10, Comentario: ${c['comentarios']}");
      }
    }

    buffer.writeln("\n--- HISTORIAL DE TRIAJES (Evaluaciones estructuradas) ---");
    if (triajes.isEmpty) {
      buffer.writeln("No hay evaluaciones de triaje registradas.");
    } else {
      for (final t in triajes) {
        buffer.writeln("- Fecha: ${t['fecha']}, Ansiedad: ${t['ansiedad']}/21, Depresión: ${t['depresion']}/21, Nivel de Riesgo: ${t['nivelRiesgo']}");
      }
    }

    final prompt = """
    Actúa como un psicólogo clínico experto y consultor de salud mental universitaria.
    Analiza los siguientes datos recolectados del estudiante a través de la aplicación SanaTec:
    
    ${buffer.toString()}
    
    Genera un reporte de análisis clínico profundo y estructurado que ayude al psicólogo de la universidad a comprender mejor al estudiante. El reporte debe presentarse con viñetas claras y estar dividido en los siguientes 4 apartados (utiliza exactamente estos títulos):

    📊 EVALUACIÓN GENERAL DE RIESGO
    (Describe el nivel de riesgo global detectado y justifica brevemente con los datos de triajes y check-ins).

    📉 PATRONES EMOCIONALES Y DISPARADORES
    (Identifica si hay patrones recurrentes, fluctuaciones en el ánimo o triggers mencionados en los comentarios diarios, tales como estrés académico, problemas familiares, falta de sueño, etc.).

    🧠 ALERTAS DE DISTORSIONES COGNITIVAS
    (Señala si en los comentarios diarios del estudiante se leen distorsiones cognitivas comunes como catastrofismo, autoexigencia extrema, polarización, o indefensión).

    🎯 PROPUESTA DE INTERVENCIÓN EN TERAPIA
    (Recomienda al menos 2 estrategias terapéuticas o temas prácticos para abordar con este alumno en la próxima cita de consejería psicológica).
    
    Nota: Mantén un tono profesional, empático y directo. No añadas introducciones ni saludos genéricos. Ve directamente a las secciones indicadas.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "No se recibió respuesta de la IA de Gemini.";
    } catch (e) {
      return "Error al conectar con Gemini: $e";
    }
  }

  /// Genera un Plan de Acción clínico sugerido por Gemini 3.5 Flash
  Future<List<String>> generarPlanDeAccion({
    required String nombre,
    required List<Map<String, dynamic>> checkins,
    required List<Map<String, dynamic>> triajes,
    required List<String> notasClinicas,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln("Paciente: $nombre");
    buffer.writeln("\nCheck-ins recientes:");
    for (final c in checkins.take(5)) {
      buffer.writeln("- Nivel de Ánimo: ${c['nivelAnimo']}/10, Comentario: ${c['comentarios']}");
    }
    buffer.writeln("\nTriajes recientes:");
    for (final t in triajes.take(3)) {
      buffer.writeln("- Ansiedad: ${t['ansiedad']}/21, Depresión: ${t['depresion']}/21, Riesgo: ${t['nivelRiesgo']}");
    }
    buffer.writeln("\nNotas Clínicas recientes:");
    for (final n in notasClinicas.take(5)) {
      buffer.writeln("- $n");
    }

    final prompt = """
    Eres un psicólogo clínico experto. Analiza el historial de este estudiante:
    ${buffer.toString()}
    
    Genera una lista de 3 a 4 acciones concretas, prácticas e inmediatas (Plan de Acción) que el estudiante debe realizar para mejorar su salud mental y desempeño académico.
    
    Reglas importantes:
    - Retorna ÚNICAMENTE los puntos del plan de acción, uno por línea.
    - Cada punto debe comenzar directamente con un guion (-) seguido de la acción.
    - No agregues introducciones, conclusiones, títulos ni formato adicional. Sé extremadamente directo y breve.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? "";
      final lines = text.split('\n')
          .map((e) => e.trim())
          .where((e) => e.startsWith('-'))
          .map((e) => e.replaceFirst(RegExp(r'^-\s*'), ''))
          .toList();
      return lines.isNotEmpty ? lines : [
        "Mantener rutina fija de sueño.",
        "Practicar respiración profunda al sentir estrés.",
        "Programar seguimiento en 2 semanas."
      ];
    } catch (e) {
      return ["Error al conectar con la IA: $e"];
    }
  }
}
