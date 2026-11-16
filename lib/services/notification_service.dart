
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Inicializa o serviço
  Future<void> inicializar() async {
    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );
  }

  // Solicita permissão para notificações
  Future<bool> solicitarPermissao() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final permissao = await android?.requestNotificationsPermission();

    return permissao ?? false;
  }

  // Agenda uma notificação
  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String descricao,
    required DateTime data,
  }) async {
    if (!data.isAfter(DateTime.now())) {
      throw ArgumentError('A data do lembrete precisa ser futura.');
    }

    final horario = tz.TZDateTime.from(data, tz.local);

    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        'imeta_tarefas',
        'Lembretes de tarefas',
        channelDescription: 'Notificações para lembrar suas tarefas',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _notifications.zonedSchedule(
      id: id,
      title: titulo,
      body: descricao,
      scheduledDate: horario,
      notificationDetails: detalhes,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Cancela uma notificação específica
  Future<void> cancelarNotificacao(int id) async {
    await _notifications.cancel(id: id);
  }

  // Cancela todas as notificações
  Future<void> cancelarTodas() async {
    await _notifications.cancelAll();
  }
}
