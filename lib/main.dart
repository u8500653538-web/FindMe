import 'package:findme_programmazione_mobile/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Plugin per gestire le notifiche locali
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  // Necessario per poter utilizzare le funzioni asincrone
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializzazione di Firebase
  await Firebase.initializeApp();

  // Configurazione iniziale delle notifiche locali (Android)
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  // Avvio del plugin di notifiche con le impostazioni definite
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Avvio dell’applicazione Flutter
  runApp(const MyApp());
}

/// Widget principale dell’app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindMe',                         // Titolo dell’app
      debugShowCheckedModeBanner: false,        // Nasconde il banner di debug
      theme: ThemeData(
        // Crea un tema basato su un colore seme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,                     // Abilita il Material Design 3
      ),
      // Pagina iniziale dell’app:
      home: const Login(),
    );
  }
}
