import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/core/router/app_router.dart';
import 'package:myapp/core/services/auth_service.dart';
import 'package:myapp/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final rol = await AuthService.instance.getUserRole(user.uid);
        if (!mounted) return;
        if (rol == 'especialista' || rol == 'medico') {
          context.go(AppRoutes.especialista);
        } else if (rol == 'alumno') {
          context.go(AppRoutes.home);
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: Perfil no encontrado (UID: ${user.uid}). Revisa Firestore.'),
            backgroundColor: AppTheme.error,
          ));
          AuthService.instance.signOut();
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final credential = await AuthService.instance.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        final rol = await AuthService.instance.getUserRole(credential.user!.uid);
        if (!mounted) return;

        if (rol == 'especialista' || rol == 'medico') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Sesión iniciada correctamente!'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ));
          context.go(AppRoutes.especialista);
        } else if (rol == 'alumno') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('¡Sesión iniciada correctamente!'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ));
          context.go(AppRoutes.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: Perfil no encontrado (UID: ${credential.user!.uid}). Revisa Firestore.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ));
          await AuthService.instance.signOut();
        }
      } else {
        // REGISTER
        await AuthService.instance.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          nombre: _nombreController.text,
          rol: 'alumno', // Por defecto todos son alumnos al registrarse
        );
        
        // Desloguear para forzar a iniciar sesión manualmente
        await AuthService.instance.signOut();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Cuenta creada! Por favor, inicia sesión.'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
        ));
        
        setState(() {
          _isLogin = true;
          _passwordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Error: ${e.message}';
      if (e.code == 'user-not-found') msg = 'No existe una cuenta con ese correo.';
      else if (e.code == 'wrong-password') msg = 'Contraseña incorrecta.';
      else if (e.code == 'invalid-email') msg = 'El correo no es válido.';
      else if (e.code == 'email-already-in-use') msg = 'El correo ya está en uso.';
      else if (e.code == 'weak-password') msg = 'La contraseña es muy débil.';
      else if (e.code == 'too-many-requests') msg = 'Demasiados intentos. Intenta más tarde.';
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // --- Círculos de ambiente difuminados (fondo) ---
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryContainer.withOpacity(0.30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB4A4).withOpacity(0.30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // --- Contenido central ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: _GlassPanel(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),

                        // --- Brand Header ---
                        _BrandHeader(),

                        const SizedBox(height: 32),

                        // --- Campo: Nombre (Solo en registro) ---
                        if (!_isLogin) ...[
                          _FormField(
                            label: 'Nombre completo',
                            controller: _nombreController,
                            hint: 'Ej. Juan Pérez',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- Campo: Correo electrónico ---
                        _FormField(
                          label: 'Correo electrónico',
                          controller: _emailController,
                          hint: 'tu@universidad.edu',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu correo';
                            if (!v.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // --- Campo: Contraseña ---
                        _PasswordField(
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          onToggle: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),

                        // --- ¿Olvidaste tu contraseña? ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.secondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // --- Botón principal: Iniciar Sesión / Registrar ---
                        _LoginButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          isLoading: _isLoading,
                          text: _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        ),

                        const SizedBox(height: 20),

                        // --- Divisor ---
                        const Divider(
                          color: Color(0xFFE1BFB8),
                          thickness: 0.5,
                        ),

                        const SizedBox(height: 12),

                        // --- Footer: ¿No tienes una cuenta? ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? '¿No tienes una cuenta? ' : '¿Ya tienes una cuenta? ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: Text(
                                _isLogin ? 'Regístrate' : 'Inicia Sesión',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.secondary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subwidgets
// ---------------------------------------------------------------------------

/// Panel con efecto glassmorphism: fondo traslúcido, blur y borde sutil.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.40),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1B19).withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

/// Encabezado de marca: ícono circular + título + subtítulo.
class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ícono circular coral con ícono de hoja/spa
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppTheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.spa_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mental Data',
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tu bienestar es nuestra prioridad.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Campo de texto reutilizable con icono a la izquierda y validación.
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.14,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: AppTheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.outlineVariant,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppTheme.outline,
              size: 22,
            ),
            filled: true,
            fillColor: const Color(0xFFFFF8F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.secondary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

/// Campo de contraseña con toggle de visibilidad.
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contraseña',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.14,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: AppTheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.outlineVariant,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.outline,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.outline,
                size: 20,
              ),
              onPressed: onToggle,
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFFFF8F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.secondary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

/// Botón principal coral con texto + icono de flecha.
class _LoginButton extends StatelessWidget {
  const _LoginButton({this.onPressed, this.isLoading = false, this.text = 'Iniciar Sesión'});
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: AppTheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }
}
