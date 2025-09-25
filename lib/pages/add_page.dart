import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:findme_programmazione_mobile/services/database.dart';
import 'package:findme_programmazione_mobile/services/shared_pref.dart';
import 'package:http/http.dart' as http;
import 'package:findme_programmazione_mobile/Secrets/secrets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pagina per aggiungere un nuovo post (oggetto smarrito o trovato)
class AddPage extends StatefulWidget {
  final String type; // "Smarrito" o "Trovato"

  const AddPage({super.key, required this.type});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String? name, image; // Nome e immagine utente

  @override
  void initState() {
    super.initState();
    getSharedPref(); // Recupera nome e immagine dall'utente
  }

  /// Recupera i dati utente da SharedPreferences
  getSharedPref() async {
    name = await SharedpreferenceHelper().getUserDisplayName();
    image = await SharedpreferenceHelper().getUserImage();
    setState(() {});
  }

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  /// Mostra un menu per scegliere tra fotocamera o galleria
  Future pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 120,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Fotocamera"),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile =
                await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  selectedImage = File(pickedFile.path);
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Galleria"),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile =
                await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  selectedImage = File(pickedFile.path);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Controller per i campi di input
  final TextEditingController placenameController = TextEditingController();
  final TextEditingController citynameController = TextEditingController();
  final TextEditingController captionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  List<dynamic> placeSuggestions = [];
  double? selectedLat;
  double? selectedLng;

  /// Ricerca luoghi tramite Google Places API
  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => placeSuggestions = []);
      return;
    }

    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$kGoogleApiKey&types=geocode");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        setState(() => placeSuggestions = data['predictions']);
      } else {
        setState(() => placeSuggestions = []);
      }
    }
  }

  /// Seleziona un luogo dalla lista dei suggerimenti e aggiorna lat/lng
  Future<void> _selectPlace(String placeId, String description) async {
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final formattedAddress = data['result']['formatted_address'];

        setState(() {
          selectedLat = location['lat'];
          selectedLng = location['lng'];
          locationController.text = formattedAddress;
          placeSuggestions = [];
        });
      }
    }
  }

  /// Carica il post su Firestore e Firebase Storage
  Future uploadPost() async {
    if (selectedImage == null ||
        placenameController.text.isEmpty ||
        citynameController.text.isEmpty ||
        captionController.text.isEmpty ||
        locationController.text.isEmpty ||
        selectedLat == null ||
        selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
              "Perfavore completa tutti i campi, seleziona un luogo e un'immagine"),
        ),
      );
      return;
    }

    try {
      String addId = randomAlphaNumeric(10);

      Reference firebaseStorageRef =
      FirebaseStorage.instance.ref().child("blogImage").child(addId);

      UploadTask task = firebaseStorageRef.putFile(selectedImage!);
      TaskSnapshot snapshot = await task;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      Map<String, dynamic> addPost = {
        "Image": downloadUrl,
        "PlaceName": placenameController.text,
        "CityName": citynameController.text,
        "Caption": captionController.text,
        "UserName": name,
        "UserImage": image,
        "Like": [],
        "Type": widget.type,
        "Location": locationController.text,
        "Lat": selectedLat,
        "Lng": selectedLng,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await DatabaseMethods().addPost(addPost, addId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Il Post è stato caricato con successo!",
            style: TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Errore nel caricamento del post: $e"),
        ),
      );
    }
  }

  /// Costruisce un campo di input personalizzato
  Widget buildInput(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.black, fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 15.0),
        Container(
          padding: EdgeInsets.only(left: 20.0),
          decoration: BoxDecoration(
              color: Color(0xFFececf8),
              borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
                border: InputBorder.none, hintText: "Inserisci $label"),
          ),
        ),
        SizedBox(height: 20.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con pulsante indietro e titolo
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 40.0, right: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_outlined,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    widget.type == "Smarrito"
                        ? "Aggiungi Oggetto Smarrito"
                        : "Aggiungi Oggetto Trovato",
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold),
                  ),
                  Spacer(flex: 2),
                ],
              ),
            ),
            SizedBox(height: 30.0),

            // Container principale per inserimento dati
            Material(
              elevation: 3.0,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: Container(
                padding: EdgeInsets.all(20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Color.fromARGB(186, 250, 247, 247),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Immagine selezionata o placeholder
                    Center(
                      child: selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          selectedImage!,
                          height: 180,
                          width: 180,
                          fit: BoxFit.cover,
                        ),
                      )
                          : GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.black45, width: 2.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.camera_alt_outlined, size: 40),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),

                    // Campi di input
                    buildInput("Nome dell'oggetto", placenameController),
                    buildInput("Nome della città", citynameController),
                    buildInput("Descrizione", captionController, maxLines: 6),

                    // Campo Luogo
                    Text(
                      "Luogo",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 15.0),
                    Container(
                      padding: EdgeInsets.only(left: 20.0),
                      decoration: BoxDecoration(
                          color: Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: locationController,
                        onChanged: _searchPlaces,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Inserisci indirizzo"),
                      ),
                    ),

                    // Lista suggerimenti luoghi
                    if (placeSuggestions.isNotEmpty)
                      Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: placeSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = placeSuggestions[index];
                            return ListTile(
                              title: Text(suggestion['description']),
                              onTap: () {
                                _selectPlace(
                                  suggestion['place_id'],
                                  suggestion['description'],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 30.0),

                    // Pulsante Pubblica
                    GestureDetector(
                      onTap: uploadPost,
                      child: Center(
                        child: Container(
                          height: 50,
                          width: MediaQuery.of(context).size.width / 2,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Pubblica",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
