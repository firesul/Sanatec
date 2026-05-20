import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = "AIzaSyDTyieTMBEoNSofn7rNJgi-JkgFvDDZUKU";
  
  final modelsToTest = [
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];

  for (final modelName in modelsToTest) {
    print("Probando modelo: $modelName...");
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final response = await model.generateContent([Content.text("Hola, responde únicamente con 'OK' para verificar conexión.")]);
      print("¡Éxito con $modelName! Respuesta: ${response.text?.trim()}");
      return; // Si uno funciona, terminamos
    } catch (e) {
      print("Error con $modelName: $e");
    }
    print("----------------------------------------");
  }
}
