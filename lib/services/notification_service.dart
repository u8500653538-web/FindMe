import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servizio per la gestione delle notifiche locali.
/// Fornisce metodi per inizializzare e mostrare notifiche
/// sia su Android che su iOS.
class NotificationService {
  // Istanza unica del plugin per le notifiche
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // -------------------- Inizializzazione --------------------

  /// Configura il plugin per Android e iOS.
  /// Deve essere chiamato una sola volta.
  static Future<void> init() async {
    // Impostazioni specifiche per Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Impostazioni specifiche per iOS
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,  // Richiede il permesso di suonare
      requestBadgePermission: true,  // Permesso per mostrare badge icona app
      requestAlertPermission: true,  // Permesso per notifiche a schermo
    );

    // Impostazioni generali comuni
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Inizializza il plugin con le impostazioni definite
    await _notificationsPlugin.initialize(initializationSettings);
  }

  // -------------------- Mostrare Notifiche --------------------

  /// Mostra una notifica locale con [title] e [body].
  /// Crea un ID univoco basato sul tempo corrente.
  static Future<void> showNotification(String title, String body) async {
    // Dettagli per Android: canale, priorità, suono, ecc.
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',                           // ID univoco del canale
      'Nuovi Post',                            // Nome canale visibile all'utente
      channelDescription:
      'Notifiche per nuovi post nella tua città', // Descrizione canale
      importance: Importance.max,              // Importanza massima
      priority: Priority.high,                 // Alta priorità
      playSound: true,                         // Riproduce suono
    );

    // Dettagli per iOS: avvisi, badge, suoni
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Dettagli complessivi per entrambe le piattaforme
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ID notifica basato sul timestamp (secondi)
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Mostra la notifica
    await _notificationsPlugin.show(
      notificationId,  // ID univoco
      title,           // Titolo
      body,            // Testo del messaggio
      notificationDetails,
    );
  }
}
