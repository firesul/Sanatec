import 'package:flutter/material.dart';

enum AppLanguage { espanol, ingles, filipino }

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final ValueNotifier<AppLanguage> languageNotifier = ValueNotifier<AppLanguage>(AppLanguage.espanol);

  AppLanguage get currentLanguage => languageNotifier.value;

  void changeLanguage(AppLanguage lang) {
    languageNotifier.value = lang;
  }

  String getLanguageLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.espanol:
        return 'Español';
      case AppLanguage.ingles:
        return 'English';
      case AppLanguage.filipino:
        return 'Filipino';
    }
  }

  String getLanguageFlag(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.espanol:
        return '🇪🇸';
      case AppLanguage.ingles:
        return '🇺🇸';
      case AppLanguage.filipino:
        return '🇵🇭';
    }
  }

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.espanol: {
      'dashboard': 'Dashboard',
      'checkin': 'Registro Diario',
      'schedule': 'Agenda',
      'clinical_lead': 'Líder Clínico',
      'search': 'Buscador',
      'mood': 'Estado de Ánimo',
      'triage': 'Triaje',
      'citas': 'Citas',
      'perfil': 'Perfil',
      'monitoreo': 'Monitoreo',
      'expediente': 'Expediente',
      'logout': 'Cerrar Sesión',
      'notificaciones': 'Notificaciones',
      'preferencias': 'Preferencias',
      'idioma': 'Idioma',
      'privacidad': 'Privacidad y Seguridad',
      'ayuda': 'Ayuda y Soporte',
      'daily_checkin_desc': 'Recordatorio de estado de ánimo',
      'citas_desc': 'Alertas de citas programadas',
      'editar_perfil': 'Editar Perfil',
      'nombre_completo': 'Nombre completo',
      'carrera': 'Carrera (Ej. Ing. Sistemas)',
      'edad': 'Edad',
      'telefono': 'Teléfono',
      'cancelar': 'Cancelar',
      'guardar': 'Guardar',
      'anos': 'años',
    },
    AppLanguage.ingles: {
      'dashboard': 'Dashboard',
      'checkin': 'Daily Check-in',
      'schedule': 'Schedule',
      'clinical_lead': 'Clinical Lead',
      'search': 'Search',
      'mood': 'Mood',
      'triage': 'Triage',
      'citas': 'Appointments',
      'perfil': 'Profile',
      'monitoreo': 'Monitoring',
      'expediente': 'Clinical File',
      'logout': 'Log Out',
      'notificaciones': 'Notifications',
      'preferencias': 'Preferences',
      'idioma': 'Language',
      'privacidad': 'Privacy & Security',
      'ayuda': 'Help & Support',
      'daily_checkin_desc': 'Mood tracking reminder',
      'citas_desc': 'Alertas of scheduled appointments',
      'editar_perfil': 'Edit Profile',
      'nombre_completo': 'Full name',
      'carrera': 'Career / Major',
      'edad': 'Age',
      'telefono': 'Phone number',
      'cancelar': 'Cancel',
      'guardar': 'Save',
      'anos': 'years old',
    },
    AppLanguage.filipino: {
      'dashboard': 'Dashboard',
      'checkin': 'Araw-araw na Check-in',
      'schedule': 'Iskedyul',
      'clinical_lead': 'Lider ng Klinika',
      'search': 'Paghahanap',
      'mood': 'Pakiramdam',
      'triage': 'Pagsusuri',
      'citas': 'Mga Tipanan',
      'perfil': 'Profile',
      'monitoreo': 'Pagmamasid',
      'expediente': 'Klinikal na Rekord',
      'logout': 'Mag-log Out',
      'notificaciones': 'Mga Abiso',
      'preferencias': 'Mga Kagustuhan',
      'idioma': 'Wika',
      'privacidad': 'Pagkapribado at Seguridad',
      'ayuda': 'Tulong at Suporta',
      'daily_checkin_desc': 'Paalala sa pagsubaybay ng pakiramdam',
      'citas_desc': 'Mga alerto para sa mga nakaiskedyul na tipanan',
      'editar_perfil': 'I-edit ang Profile',
      'nombre_completo': 'Buong pangalan',
      'carrera': 'Kurso / Karera',
      'edad': 'Edad',
      'telefono': 'Numero ng telepono',
      'cancelar': 'Kanselahin',
      'guardar': 'I-save',
      'anos': 'taong gulang',
    },
  };

  String translate(String key) {
    final lang = languageNotifier.value;
    return _translations[lang]?[key] ?? key;
  }
}

String t(String key) {
  return TranslationService.instance.translate(key);
}
