import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:findme_programmazione_mobile/services/shared_pref.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'home.dart';

/// Pagina per completare o modificare il profilo utente.
/// Permette di inserire nome, città, data di nascita e immagine profilo.
class ProfileSetupPage extends StatefulWidget {
  final String? defaultName;   // Nome predefinito (se modifica)
  final String? userId;        // ID utente
  final String? defaultCity;   // Città predefinita
  final DateTime? defaultDOB;  // Data di nascita predefinita
  final String? defaultImage;  // URL immagine predefinita
  final bool isEdit;           // true se si sta modificando il profilo

  const ProfileSetupPage({
    this.defaultName,
    this.userId,
    this.defaultCity,
    this.defaultDOB,
    this.defaultImage,
    this.isEdit = false,
    super.key,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  // Controller per i campi di testo
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  DateTime? selectedDate; // Data di nascita selezionata
  File? _imageFile;       // File immagine scelto
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false; // Mostra un indicatore di caricamento

  @override
  void initState() {
    super.initState();
    // Precompila i campi se si sta modificando un profilo esistente
    nameController.text = widget.defaultName ?? "";
    cityController.text = widget.defaultCity ?? "";
    selectedDate = widget.defaultDOB;
  }

  /// Seleziona un'immagine dalla galleria
  Future<void> pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// Seleziona la data di nascita
  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// Carica i dati del profilo su Firebase (Firestore + Storage)
  Future<void> uploadProfile() async {
    // Controlla che tutti i campi siano compilati
    if (nameController.text.isEmpty ||
        cityController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa tutti i campi")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    String? imageUrl = widget.defaultImage;

    // Se l'utente ha scelto una nuova immagine, caricala su Firebase Storage
    if (_imageFile != null) {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${widget.userId}.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    // Mappa dei dati da salvare/aggiornare su Firestore
    Map<String, dynamic> userData = {
      "Name": nameController.text,
      "City": cityController.text,
      "DOB": selectedDate!.toIso8601String(),
      "Image": imageUrl ?? "",
      "Id": widget.userId ?? "",
    };

    // Se si tratta di una modifica, aggiorna il documento,
    // altrimenti creane uno nuovo
    if (widget.isEdit) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .update(userData);
    } else {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .set(userData);
    }

    // Aggiorna i dati salvati localmente (SharedPreferences)
    await SharedpreferenceHelper().saveUserDisplayName(nameController.text);
    await SharedpreferenceHelper().saveUserImage(imageUrl ?? "");
    await SharedpreferenceHelper().saveUserId(widget.userId ?? "");

    setState(() {
      isLoading = false;
    });

    // Navigazione finale:
    // - se è una modifica, torna alla schermata precedente
    // - altrimenti vai alla Home
    if (widget.isEdit) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Modifica Profilo" : "Completa il Profilo"),
      ),
      body: isLoading
      // Mostra un loader durante il salvataggio
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar con immagine selezionata o predefinita
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (widget.defaultImage != null &&
                    widget.defaultImage!.isNotEmpty
                    ? NetworkImage(widget.defaultImage!)
                as ImageProvider
                    : null),
                child: _imageFile == null &&
                    (widget.defaultImage == null ||
                        widget.defaultImage!.isEmpty)
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Campo nome profilo
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Nome Profilo",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo città
            TextField(
              controller: cityController,
              decoration: InputDecoration(
                labelText: "Città",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Selezione data di nascita
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? "Seleziona Data di Nascita"
                        : "Data di Nascita: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  ),
                ),
                ElevatedButton(
                  onPressed: pickDate,
                  child: const Text("Scegli Data"),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Pulsante di salvataggio
            ElevatedButton(
              onPressed: uploadProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                widget.isEdit ? "Salva Modifiche" : "Salva & Continua",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
