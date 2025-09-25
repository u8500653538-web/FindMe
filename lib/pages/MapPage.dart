import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findme_programmazione_mobile/Secrets/secrets.dart';
import 'package:flutter/gestures.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;             // Controller della mappa di Google
  LatLng? currentPosition;                        // Posizione corrente dell'utente
  final TextEditingController _searchController = TextEditingController(); // Controller per il campo di ricerca
  List<dynamic> placeSuggestions = [];            // Suggerimenti dei luoghi trovati tramite Google Places
  Set<Marker> markers = {};                       // Marker da mostrare sulla mappa

  @override
  void initState() {
    super.initState();
    _getUserLocation();  // Ottiene la posizione attuale
    _loadPosts();        // Carica i post da Firestore e crea i marker
  }

  // Ottiene la posizione corrente dell'utente
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; // Se il servizio non è abilitato, esce

    // Controllo permessi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return; // Se negato di nuovo, esce
    }
    if (permission == LocationPermission.deniedForever) return; // Se negato per sempre, esce

    try {
      // Ottiene la posizione con alta precisione
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Muove la camera sulla posizione attuale
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition!, 15),
      );
    } catch (e) {
      if (kDebugMode) print("Errore ottenendo la posizione: $e");
    }
  }

  // Carica i post da Firestore e crea i marker
  Future<void> _loadPosts() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection("Posts").get();

    // Raggruppa i post in base alle coordinate Lat/Lng
    Map<String, List<Map<String, dynamic>>> groupedPosts = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data["Lat"] != null && data["Lng"] != null) {
        String key = "${data["Lat"]}_${data["Lng"]}";
        if (!groupedPosts.containsKey(key)) {
          groupedPosts[key] = [];
        }
        groupedPosts[key]!.add({
          "PlaceName": data["PlaceName"] ?? "Senza nome",
          "Caption": data["Caption"] ?? "",
          "Image": data["Image"] ?? "",
          "Type": data["Type"] ?? "",
        });
      }
    }

    Set<Marker> newMarkers = {};

    groupedPosts.forEach((key, posts) {
      List<String> latlng = key.split("_");
      LatLng pos = LatLng(double.parse(latlng[0]), double.parse(latlng[1]));

      newMarkers.add(
        Marker(
          markerId: MarkerId(key),
          position: pos,
          onTap: () {
            // Mostra un popup con la lista dei post in quella posizione
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Post in questa posizione"),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        Color markerColor = post["Type"] == "Smarrito"
                            ? Colors.red
                            : Colors.green;

                        return ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Cerchio colorato per indicare il tipo
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: markerColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              // Immagine del post, se presente
                              post["Image"].isNotEmpty
                                  ? Image.network(
                                post["Image"],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                                  : Icon(Icons.image_not_supported),
                            ],
                          ),
                          title: Text(post["PlaceName"]),
                          subtitle: Text(post["Caption"]),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Chiudi"),
                    ),
                  ],
                );
              },
            );
          },
          // Colore del marker: rosso se "Smarrito", verde altrimenti
          icon: BitmapDescriptor.defaultMarkerWithHue(
            posts.first["Type"] == "Smarrito"
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    });

    setState(() {
      markers = newMarkers; // Aggiorna lo stato con i nuovi marker
    });
  }

  // Ricerca luoghi con Google Places
  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => placeSuggestions = []);
      return;
    }

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=${Uri.encodeComponent(input)}&key=$kGoogleApiKey&types=geocode",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        setState(() => placeSuggestions = data['predictions']);
      } else {
        setState(() => placeSuggestions = []);
      }
    } else {
      if (kDebugMode) print("Errore Google Places API");
    }
  }

  // Ottiene le coordinate da un place_id e muove la camera su quel punto
  Future<void> _moveToPlace(String placeId) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
          "?place_id=$placeId&key=$kGoogleApiKey",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final newPosition = LatLng(location['lat'], location['lng']);

        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 15),
        );

        setState(() {
          currentPosition = newPosition;
          placeSuggestions = [];
          _searchController.text = data['result']['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mappa")),
      body: Column(
        children: [
          // Sezione di ricerca luogo
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Cerca un luogo...",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: _searchPlaces, // Avvia la ricerca ad ogni cambiamento
                ),
                if (placeSuggestions.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ListView.builder(
                      itemCount: placeSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = placeSuggestions[index];
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () {
                            _moveToPlace(suggestion['place_id']);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Mappa Google
          Expanded(
            child: currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentPosition!,
                zoom: 15,
              ),
              onMapCreated: (controller) => mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: markers, // Marker caricati dai post
              gestureRecognizers: <
                  Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
