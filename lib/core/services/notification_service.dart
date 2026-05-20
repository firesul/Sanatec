import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Tijuana'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar tap en notificación si es necesario
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  // 1. Daily Check-in a las 10:00 AM (todos los días)
  Future<void> scheduleDailyCheckIn() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_checkin',
      'Daily Check-in',
      channelDescription: 'Recordatorio diario',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id: 100, // ID estático para que no se dupliquen
      title: 'Es hora de tu Check-in Diario ☀️',
      body: 'Tómate un momento para registrar cómo te sientes hoy.',
      scheduledDate: _nextInstanceOfTime(10, 0),
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diario
    );
  }

  // 2. Citas y Eventos: 3 notificaciones programadas
  Future<void> scheduleCitaNotifications({
    required int citaId,
    required DateTime citaTime,
    required String title,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'citas_channel',
      'Recordatorios de Citas',
      channelDescription: 'Recordatorios para tus próximas citas clínicas',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // a) 24 horas antes (un día exacto antes)
    final tz.TZDateTime t24 = tz.TZDateTime.from(
        citaTime.subtract(const Duration(hours: 24)), tz.local);
    if (t24.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notificationsPlugin.zonedSchedule(
        id: citaId * 10 + 1,
        title: 'Recordatorio de Cita Mañana',
        body: 'Tienes programado: $title mañana a las ${citaTime.hour}:${citaTime.minute.toString().padLeft(2, '0')}.',
        scheduledDate: t24,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // b) A las 12:00 de la noche (00:00) del día de la cita
    final midnight = DateTime(citaTime.year, citaTime.month, citaTime.day, 0, 0);
    final tz.TZDateTime t00 = tz.TZDateTime.from(midnight, tz.local);
    if (t00.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notificationsPlugin.zonedSchedule(
        id: citaId * 10 + 2,
        title: 'Cita Hoy',
        body: 'Recuerda que hoy tienes tu cita: $title.',
        scheduledDate: t00,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // c) 1 hora antes de la cita
    final tz.TZDateTime t1h = tz.TZDateTime.from(
        citaTime.subtract(const Duration(hours: 1)), tz.local);
    if (t1h.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notificationsPlugin.zonedSchedule(
        id: citaId * 10 + 3,
        title: 'Cita en 1 hora',
        body: 'Prepárate para tu cita: $title que comenzará en 1 hora.',
        scheduledDate: t1h,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  // Utilidad para calcular el próximo horario de las 10:00 AM
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
