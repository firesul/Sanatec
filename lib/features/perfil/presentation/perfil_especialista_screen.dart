import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/services/translation_service.dart';
import 'package:go_router/go_router.dart';

class PerfilEspecialistaScreen extends StatelessWidget {
  const PerfilEspecialistaScreen({super.key});

  Future<void> _mostrarDialogoEditar(BuildContext context, Map<String, dynamic>? currentData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nombreCtrl = TextEditingController(text: currentData?['nombre'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(t('editar_perfil'), style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: t('nombre_completo'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t('cancelar'), style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (nombreCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
                  'nombre': nombreCtrl.text.trim(),
                }, SetOptions(merge: true));
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(t('guardar'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoIdioma(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('idioma'),
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final label = TranslationService.instance.getLanguageLabel(lang);
            final flag = TranslationService.instance.getLanguageFlag(lang);
            final isSelected = TranslationService.instance.currentLanguage == lang;

            return ListTile(
              leading: Text(flag, style: const TextStyle(fontSize: 24)),
              title: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
              onTap: () {
                TranslationService.instance.changeLanguage(lang);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _mostrarDialogoPrivacidad(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              t('privacidad'),
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confidencialidad Médica',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Toda tu información emocional, clínica y de triaje se encuentra protegida bajo el secreto profesional médico y de psicología.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                'Seguridad en la Nube (Firebase)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Utilizamos Reglas de Seguridad en Firebase Firestore que impiden el acceso a usuarios no autorizados. Solo tú y el especialista asignado pueden leer tu expediente.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                'Derechos ARCO (Acceso y Borrado)',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Tienes el derecho inalienable de solicitar la rectificación o eliminación total de tus registros clínicos de nuestra base de datos cuando lo decidas.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendido',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoSoporte(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_rounded, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              t('ayuda'),
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Necesitas ayuda con SanaTec?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Envíanos un correo a nuestro canal de soporte técnico oficial:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF2EF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_rounded, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'saulssjfuentes@gmail.com',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.primary, size: 18),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'saulssjfuentes@gmail.com'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Correo copiado al portapapeles.'),
                          backgroundColor: AppTheme.secondary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Te responderemos en menos de 24 horas hábiles. ¡Gracias por usar SanaTec!',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Entendido',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, currentLang, _) {
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
              t('perfil'),
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: AppTheme.outlineVariant.withOpacity(0.4),
              ),
            ),
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final nombre = data?['nombre'] ?? user?.displayName ?? 'Especialista';
              final email = data?['email'] ?? user?.email ?? 'correo@ejemplo.com';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE6E3),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.outlineVariant, width: 2),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 60,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      nombre,
                      style: GoogleFonts.quicksand(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        t('clinical_lead'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Opciones con Estética Premium
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E1B19).withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                            title: Text(t('editar_perfil'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _mostrarDialogoEditar(context, data),
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.translate_rounded, color: AppTheme.primary),
                            title: Text(t('idioma'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  TranslationService.instance.getLanguageFlag(TranslationService.instance.currentLanguage),
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                            onTap: () => _mostrarDialogoIdioma(context),
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.shield_rounded, color: AppTheme.primary),
                            title: Text(t('privacidad'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _mostrarDialogoPrivacidad(context),
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.help_rounded, color: AppTheme.primary),
                            title: Text(t('ayuda'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _mostrarDialogoSoporte(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Botón de cerrar sesión
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AuthService.instance.signOut();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(t('logout')),
                            backgroundColor: AppTheme.secondary,
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          t('logout'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        );
      }
    );
  }
}
