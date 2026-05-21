import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/core/theme/app_theme.dart';

class UpdateService {
  // Reemplaza esta URL con la ruta real donde hospedarás tu version.json en producción.
  // Por ejemplo, en GitHub Gist, GitHub Pages, o tu propio hosting.
  static const String _updateUrl = 'https://raw.githubusercontent.com/firesul/Sanatec/main/version.json';

  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateDialog = false}) async {
    try {
      // 1. Obtener información local de la app
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version; // Ejemplo: "1.0.0"
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      // 2. Realizar petición HTTP al servidor de control de versiones
      final response = await http.get(Uri.parse(_updateUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al conectar con el servidor de actualizaciones');
      }

      final Map<String, dynamic> data = json.decode(response.body);

      final String latestVersion = data['latestVersion'] ?? '1.0.0';
      final int latestBuildNumber = data['latestBuildNumber'] ?? 1;
      final String apkUrl = data['apkUrl'] ?? '';
      final bool forceUpdate = data['forceUpdate'] ?? false;
      final List<dynamic> changelog = data['changelog'] ?? [];

      // 3. Evaluar e iniciar flujo de actualización si corresponde
      bool hasUpdate = false;

      if (_isVersionNewer(currentVersion, latestVersion)) {
        hasUpdate = true;
      } else if (currentVersion == latestVersion && latestBuildNumber > currentBuildNumber) {
        hasUpdate = true;
      }

      if (hasUpdate && context.mounted) {
        _showUpdateDialog(
          context,
          latestVersion: latestVersion,
          apkUrl: apkUrl,
          forceUpdate: forceUpdate,
          changelog: changelog.cast<String>(),
        );
      } else if (showNoUpdateDialog && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡SanaTec está en su versión más reciente! 💚'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error verificando actualizaciones: $e');
      if (showNoUpdateDialog && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al comprobar actualizaciones: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Algoritmo de comparación semántica de versiones (e.g. 1.0.1 > 1.0.0)
  static bool _isVersionNewer(String current, String latest) {
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestParts[i] > currentPart) return true;
      if (latestParts[i] < currentPart) return false;
    }
    return false;
  }

  // Diálogo nativo elegante tematizado con los colores corporativos
  static void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String apkUrl,
    required bool forceUpdate,
    required List<String> changelog,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: const Color(0xFFFFFDFB),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '¡Nueva actualización!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B19),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Una nueva versión de SanaTec (v$latestVersion) está lista para descargar. Mantén tu aplicación al día para disfrutar de las últimas mejoras de salud mental e innovación.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                  if (changelog.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '¿Qué hay de nuevo?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B19),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...changelog.map((change) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  change,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (forceUpdate) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Esta actualización es obligatoria para poder continuar utilizando la plataforma.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            actions: [
              if (!forceUpdate)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Más tarde'),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(apkUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo abrir el enlace de descarga.'),
                        ),
                      );
                    }
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Descargar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
