import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:findme_programmazione_mobile/pages/ProfileSetupPage.dart';
import 'package:findme_programmazione_mobile/services/database.dart';
import 'package:findme_programmazione_mobile/services/shared_pref.dart';

/// Pagina di registrazione utente.
/// Consente di creare un nuovo account, salvare i dati in Firestore
/// e memorizzarli anche su SharedPreferences.
class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  // Controller per i campi di input
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// Metodo che gestisce la logica di registrazione
  Future<void> registration() async {
    // Controllo che i campi non siano vuoti
    if (nameController.text.isNotEmpty &&
        mailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      try {
        // 1. Creazione account su Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: mailController.text,
          password: passwordController.text,
        );

        // 2. Generazione ID univoco per l’utente
        String id = randomAlphaNumeric(10);

        // 3. URL immagine di default per il profilo
        const String defaultImage =
            "https://firebasestorage.googleapis.com/v0/b/barberapp-ebcc1.appspot.com/o/icon1.png?alt=media&token=0fad24a5-a01b-4d67-b4a0-676fbc75b34a";

        // 4. Creazione mappa con i dati dell’utente
        Map<String, dynamic> userInfoMap = {
          "Name": nameController.text,
          "Email": mailController.text,
          "Image": defaultImage,
          "Id": id,
          "profileComplete": false,
        };

        // 5. Salvataggio dati su SharedPreferences per accesso rapido
        await SharedpreferenceHelper().saveUserDisplayName(nameController.text);
        await SharedpreferenceHelper().saveUserEmail(mailController.text);
        await SharedpreferenceHelper().saveUserId(id);
        await SharedpreferenceHelper().saveUserImage(defaultImage);

        // 6. Salvataggio dati utente su Firestore
        await DatabaseMethods().addUserDetails(userInfoMap, id);

        // 7. Notifica di successo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Registrazione avvenuta con successo",
              style: TextStyle(fontSize: 20.0, color: Colors.white),
            ),
          ),
        );

        // 8. Navigazione alla pagina di configurazione profilo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupPage(
              userId: id,
              defaultName: nameController.text,
              defaultImage: defaultImage,
              isEdit: true,
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        // Gestione errori di Firebase
        String message;
        if (e.code == 'weak-password') {
          message = "La password fornita è troppo debole";
        } else if (e.code == "email-already-in-use") {
          message = "L'account esiste già";
        } else {
          message = e.message ?? "Errore durante la registrazione";
        }

        // Mostra messaggio di errore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(message, style: const TextStyle(fontSize: 18.0)),
          ),
        );
      }
    } else {
      // Se i campi sono vuoti, avvisa l’utente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "Compila tutti i campi",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine di intestazione con angolo arrotondato in basso a destra
            ClipRRect(
              borderRadius:
              const BorderRadius.only(bottomRight: Radius.circular(180)),
              child: Image.asset(
                "images/signup.jpeg",
                height: 300,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20.0),

            // Titolo della pagina
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Registrazione",
                style: TextStyle(color: Colors.white, fontSize: 40.0),
              ),
            ),
            const SizedBox(height: 20.0),

            // Campi di input
            buildTextField("Nome", nameController),
            const SizedBox(height: 20.0),
            buildTextField("Email", mailController),
            const SizedBox(height: 20.0),
            buildTextField("Password", passwordController, obscure: true),
            const SizedBox(height: 50.0),

            // Pulsante di registrazione
            GestureDetector(
              onTap: registration,
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "Registrati",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Link per chi ha già un account
            const Center(
              child: Text(
                "Hai gia' un account?",
                style: TextStyle(
                  color: Color.fromARGB(173, 255, 255, 255),
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Torna alla pagina di login
              },
              child: const Center(
                child: Text(
                  "Accedi",
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce un campo di input personalizzato con label.
  Widget buildTextField(
      String label,
      TextEditingController controller, {
        bool obscure = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(186, 255, 255, 255),
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.only(left: 30.0),
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Color.fromARGB(174, 255, 255, 255)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscure,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
