import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:findme_programmazione_mobile/pages/home.dart';
import 'package:findme_programmazione_mobile/pages/signup.dart';
import 'package:findme_programmazione_mobile/services/database.dart';
import 'package:findme_programmazione_mobile/services/shared_pref.dart';

// Pagina di Login
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Variabili per salvare email e password inserite dall'utente
  String email = "";
  String password = "";

  // Controller per i campi di input
  TextEditingController passwordController = TextEditingController();
  TextEditingController mailController = TextEditingController();

  // =========================================
  // Metodo per salvare il token FCM dell'utente
  // =========================================

  Future<void> saveFcmToken(String userId) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await DatabaseMethods().updateUserToken(userId, token);
    }
  }

  // =========================================
  // Metodo per effettuare il login
  // =========================================

  userLogin() async {
    // Se email o password sono vuote, interrompi
    if (email.isEmpty || password.isEmpty) return;

    try {
      // Login con Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Recupero dati utente da Firestore tramite email
      QuerySnapshot querySnapshot =
      await DatabaseMethods().getUserbyEmail(email);

      // Controllo se l'utente esiste
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Nessun utente trovato",
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
        );
        return;
      }

      // Prendi il primo documento (dovrebbe essere unico)
      var userDoc = querySnapshot.docs[0];

      // Estrazione dati utente
      String myName = userDoc["Name"] ?? "";
      String myId = userDoc["Id"] ?? "";
      String myImage = userDoc["Image"] ?? "";
      String myCity = userDoc["City"] ?? "";

      // Gestione della data di nascita che può essere Timestamp o String
      var dobValue = userDoc["DOB"];
      DateTime? myDob;
      if (dobValue != null) {
        if (dobValue is Timestamp) {
          myDob = dobValue.toDate();
        } else if (dobValue is String) {
          myDob = DateTime.tryParse(dobValue);
        }
      }

      // Salvataggio token FCM per notifiche push
      await saveFcmToken(myId);

      // Salvataggio dei dati utente su SharedPreferences
      await SharedpreferenceHelper().saveUserDisplayName(myName);
      await SharedpreferenceHelper().saveUserId(myId);
      await SharedpreferenceHelper().saveUserImage(myImage);
      await SharedpreferenceHelper().saveUserCity(myCity);
      if (myDob != null) {
        await SharedpreferenceHelper().saveUserDOB(myDob.toIso8601String());
      }

      // Navigazione alla Home Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      // Gestione errori login
      String msg = "";
      if (e.code == 'user-not-found') {
        msg = "Nessun utente trovato con questa email";
      } else if (e.code == 'wrong-password') {
        msg = "Password errata";
      } else {
        msg = "Errore: ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 18.0, color: Colors.black),
          ),
        ),
      );
    }
  }

  // =========================================
  // Build del widget principale
  // =========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine di copertina
            ClipRRect(
              borderRadius:
              const BorderRadius.only(bottomRight: Radius.circular(180)),
              child: Image.asset(
                "images/login.jpeg",
                height: 350,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20.0),

            // Titolo Benvenuto
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Benvenuto!",
                style: TextStyle(color: Colors.white, fontSize: 40.0),
              ),
            ),
            const SizedBox(height: 20.0),

            // Etichetta Email
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Email",
                style: TextStyle(
                  color: Color.fromARGB(186, 255, 255, 255),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // Campo input Email
            Container(
              padding: const EdgeInsets.only(left: 30.0),
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color.fromARGB(174, 255, 255, 255)),
                  borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: mailController,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (value) => email = value.trim(),
              ),
            ),
            const SizedBox(height: 20.0),

            // Etichetta Password
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Password",
                style: TextStyle(
                  color: Color.fromARGB(186, 255, 255, 255),
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // Campo input Password
            Container(
              padding: const EdgeInsets.only(left: 30.0),
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color.fromARGB(174, 255, 255, 255)),
                  borderRadius: BorderRadius.circular(30)),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (value) => password = value.trim(),
              ),
            ),
            const SizedBox(height: 10.0),

            // Link Password dimenticata
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: Text(
                    "Password dimenticata?",
                    style: TextStyle(
                        color: Color.fromARGB(186, 255, 255, 255),
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Bottone Accedi
            GestureDetector(
              onTap: userLogin,
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: BorderRadius.circular(30)),
                child: const Center(
                  child: Text(
                    "Accedi",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50.0),

            // Testo registrazione
            const Center(
              child: Text(
                "Non hai un account?",
                style: TextStyle(
                    color: Color.fromARGB(173, 255, 255, 255),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500),
              ),
            ),

            // Bottone Registrati
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUp()),
                );
              },
              child: const Center(
                child: Text(
                  "Registrati",
                  style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
