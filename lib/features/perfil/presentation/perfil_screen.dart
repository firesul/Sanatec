import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/theme/app_theme.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/services/translation_service.dart';
import 'package:myapp/shared/widgets/app_top_bar.dart';
import 'package:myapp/shared/widgets/app_bottom_nav_bar.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _mostrarDialogoEditar(BuildContext context, Map<String, dynamic>? currentData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nombreCtrl = TextEditingController(text: currentData?['nombre'] ?? '');
    final carreraCtrl = TextEditingController(text: currentData?['carrera'] ?? '');
    final edadCtrl = TextEditingController(text: currentData?['edad']?.toString() ?? '');
    final telefonoCtrl = TextEditingController(text: currentData?['telefono'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Editar Perfil', style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: carreraCtrl,
                decoration: InputDecoration(
                  labelText: 'Carrera (Ej. Ing. Sistemas)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: edadCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Edad',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              int? edadVal = int.tryParse(edadCtrl.text);
              await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
                if (nombreCtrl.text.isNotEmpty) 'nombre': nombreCtrl.text.trim(),
                if (carreraCtrl.text.isNotEmpty) 'carrera': carreraCtrl.text.trim(),
                'edad': ?edadVal,
                if (telefonoCtrl.text.isNotEmpty) 'telefono': telefonoCtrl.text.trim(),
              }, SetOptions(merge: true));
              
              // Actualizar también el perfil base en pacientes si existe
              await FirebaseFirestore.instance.collection('pacientes').doc(user.uid).set({
                if (nombreCtrl.text.isNotEmpty) 'nombre': nombreCtrl.text.trim(),
                if (carreraCtrl.text.isNotEmpty) 'carrera': carreraCtrl.text.trim(),
                'edad': ?edadVal,
              }, SetOptions(merge: true));

              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text('Guardar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
              'Cerrar',
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
        final flag = TranslationService.instance.getLanguageFlag(currentLang);
        final label = TranslationService.instance.getLanguageLabel(currentLang);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: const AppTopBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
            child: Column(
              children: [
                // Profile Header
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final nombre = data?['nombre'] ?? user?.displayName ?? 'Usuario';
                    final email = data?['email'] ?? user?.email ?? 'correo@ejemplo.com';
                    final carrera = data?['carrera'] as String?;
                    final edad = data?['edad'] as int?;
                    final telefono = data?['telefono'] as String?;

                    return Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary, width: 3),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: AppTheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          nombre,
                          style: GoogleFonts.quicksand(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Chips informativos
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (carrera != null && carrera.isNotEmpty)
                              _InfoChip(icon: Icons.school_rounded, label: carrera),
                            if (edad != null)
                              _InfoChip(icon: Icons.cake_rounded, label: '$edad ${t('anos')}'),
                            if (telefono != null && telefono.isNotEmpty)
                              _InfoChip(icon: Icons.phone_rounded, label: telefono),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => _mostrarDialogoEditar(context, data),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          child: Text(
                            t('editar_perfil'),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),

                const SizedBox(height: 40),

                // Notificaciones
                _SectionCard(
                  title: t('notificaciones'),
                  icon: Icons.notifications_active_rounded,
                  children: [
                    _ToggleRow(title: t('checkin'), subtitle: t('daily_checkin_desc'), initialValue: true),
                    const Divider(height: 1),
                    _ToggleRow(title: t('citas'), subtitle: t('citas_desc'), initialValue: true),
                  ],
                ),

                const SizedBox(height: 24),

                // Preferencias
                _SectionCard(
                  title: t('preferencias'),
                  icon: Icons.settings_rounded,
                  children: [
                    _ActionRow(
                      title: t('idioma'),
                      trailing: '$flag $label',
                      onTap: () => _mostrarDialogoIdioma(context),
                    ),
                    const Divider(height: 1),
                    _ActionRow(
                      title: t('privacidad'),
                      onTap: () => _mostrarDialogoPrivacidad(context),
                    ),
                    const Divider(height: 1),
                    _ActionRow(
                      title: t('ayuda'),
                      onTap: () => _mostrarDialogoSoporte(context),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AuthService.instance.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(currentLang == AppLanguage.espanol 
                          ? 'Has cerrado sesión correctamente.' 
                          : currentLang == AppLanguage.ingles 
                            ? 'Successfully logged out.' 
                            : 'Matagumpay na naka-log out.'),
                        backgroundColor: AppTheme.primary,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatefulWidget {
  const _ToggleRow({required this.title, required this.subtitle, required this.initialValue});
  final String title;
  final String subtitle;
  final bool initialValue;

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: (v) => setState(() => value = v),
      activeThumbColor: AppTheme.primary,
      title: Text(
        widget.title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        ),
      ),
      subtitle: Text(
        widget.subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.title, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            Text(
              trailing!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
