import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:findme_programmazione_mobile/pages/comment.dart';
import 'package:findme_programmazione_mobile/pages/ProfileSetupPage.dart';
import 'package:findme_programmazione_mobile/pages/SelectTypePage.dart';
import 'package:findme_programmazione_mobile/services/database.dart';
import 'package:findme_programmazione_mobile/services/shared_pref.dart';
import 'package:findme_programmazione_mobile/services/notification_service.dart';
import 'MapPage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Variabili utente
  String? name, image, id, city;
  DateTime? dob;
  TextEditingController searchController = TextEditingController();

  // Stream dei post
  Stream<QuerySnapshot>? postStream;
  bool search = false;
  List<DocumentSnapshot> queryResultSet = [];
  List<DocumentSnapshot> tempSearchStore = [];

  // Notifiche e nuovi post
  int newPostCount = 0;
  List<DocumentSnapshot> newPosts = [];
  DateTime? lastLogin;

  StreamSubscription? cityPostsSubscription;
  bool clearedOnce = false;

  // Carica flag "notificationsCleared"
  Future<void> _loadClearedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    clearedOnce = prefs.getBool('notificationsCleared') ?? false;
  }

  // Salva flag "notificationsCleared"
  Future<void> _saveClearedFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsCleared', value);
  }

// Handler globale per messaggi in background
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    if (message.notification != null) {
      NotificationService.showNotification(
        message.notification!.title ?? '',
        message.notification!.body ?? '',
      );
    }
  }

  // Reset flag ad ogni apertura
  Future<void> _resetClearedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('clearedOnce', false);
    clearedOnce = false;
  }

  @override
  void initState() {
    super.initState();
    initServices();
    getOnLoad();
  }

  @override
  void dispose() {
    cityPostsSubscription?.cancel();
    super.dispose();
  }

  // Inizializzazione servizi di notifica e token FCM
  Future<void> initServices() async {
    await NotificationService.init();

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationService.showNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
      }
    });

    final token = await messaging.getToken();
    if (token != null && id != null && id!.isNotEmpty) {
      await DatabaseMethods().updateUserToken(id!, token);
    }
  }

  // Carica dati utente da SharedPreferences
  getSharedPref() async {
    name = await SharedpreferenceHelper().getUserDisplayName();
    image = await SharedpreferenceHelper().getUserImage();
    id = await SharedpreferenceHelper().getUserId();
    city = await SharedpreferenceHelper().getUserCity();
    String? dobString = await SharedpreferenceHelper().getUserDOB();
    if (dobString != null && dobString.isNotEmpty) {
      dob = DateTime.tryParse(dobString);
    }

    lastLogin = DateTime.now();
    await _loadClearedFlag();

    setState(() {});
  }

  // Caricamento iniziale
  getOnLoad() async {
    await getSharedPref();

    final prefs = await SharedPreferences.getInstance();
    List<String> readPostIds = prefs.getStringList('readPostIds') ?? [];

    postStream = DatabaseMethods().getPosts();
    listenForNewPosts(readPostIds: readPostIds);

    setState(() {});
  }

  // Funzione per ricerca
  initiateSearch(String value) async {
    if (value.isEmpty) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        search = false;
      });
      return;
    }

    setState(() {
      search = true;
    });

    String queryLower = value.toLowerCase();

    if (queryResultSet.isEmpty) {
      QuerySnapshot docs =
      await FirebaseFirestore.instance.collection("Posts").get();
      queryResultSet = docs.docs;
    }

    tempSearchStore = queryResultSet.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      final nameField = (data["Name"] ?? "").toString().toLowerCase();
      final caption = (data["Caption"] ?? "").toString().toLowerCase();
      final location = (data["Location"] ?? "").toString().toLowerCase();
      final type = (data["Type"] ?? "").toString().toLowerCase();

      return nameField.contains(queryLower) ||
          caption.contains(queryLower) ||
          location.contains(queryLower) ||
          type.contains(queryLower);
    }).toList();

    setState(() {});
  }

  // Ascolta nuovi post nella città dell'utente
  listenForNewPosts({required List<String> readPostIds}) async {
    if (city == null || city!.trim().isEmpty) return;

    await cityPostsSubscription?.cancel();

    cityPostsSubscription =
        DatabaseMethods().getPostsPlace(city!).listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var data = change.doc.data() as Map<String, dynamic>?;
              if (data == null) continue;

              if (readPostIds.contains(change.doc.id)) continue;

              if (!newPosts.any((doc) => doc.id == change.doc.id)) {
                setState(() {
                  newPostCount++;
                  newPosts.add(change.doc);
                });

                NotificationService.showNotification(
                  "Nuovo post in ${city!.trim()}!",
                  data["Caption"] ?? "Clicca per vedere",
                );
              }
            }
          }
        });
  }

  // Mostra dialog con nuovi post
  void showNewPostsDialog() {
    if (newPosts.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Nuovi post nella tua città"),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: newPosts.length,
              itemBuilder: (context, index) {
                var data = newPosts[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: (data["Image"] ?? "").isNotEmpty
                      ? Image.network(data["Image"],
                      width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image_not_supported, size: 50),
                  title: Text(data["PlaceName"] ?? "Nuovo post"),
                  subtitle: Text(
                    data["Caption"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newPosts.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  List<String> readPostIds =
                      prefs.getStringList('readPostIds') ?? [];
                  readPostIds.addAll(newPosts.map((p) => p.id));
                  await prefs.setStringList('readPostIds', readPostIds);
                }

                setState(() {
                  newPostCount = 0;
                  newPosts.clear();
                });

                Navigator.pop(context);
              },
              child: const Text("Chiudi"),
            ),
          ],
        );
      },
    );
  }

  // Mostra dialog dei like
  void _showLikesDialog(List<String> likeList) async {
    if (likeList.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Like"),
          content: Text("Nessuno ha messo like a questo post."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Chiudi"),
            )
          ],
        ),
      );
      return;
    }

    List<Map<String, String>> usersData = [];
    for (String userId in likeList) {
      DocumentSnapshot userDoc = await DatabaseMethods().getUserById(userId);
      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        usersData.add({
          "name": data["Name"] ?? "Utente",
          "image": data["Image"] ?? "",
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Persone che hanno messo like"),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: usersData.length,
              itemBuilder: (context, index) {
                var user = usersData[index];
                return ListTile(
                  leading: user["image"]!.isNotEmpty
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(user["image"]!),
                  )
                      : CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(user["name"]!),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Chiudi"),
            )
          ],
        );
      },
    );
  }

  // Widget per mostrare un singolo post
  Widget postCard(DocumentSnapshot ds) {
    var data = ds.data() as Map<String, dynamic>;
    final likeList = List<String>.from(data["Like"] ?? []);
    final likeCount = likeList.length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header utente
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: (data["UserImage"] ?? "").isNotEmpty
                          ? Image.network(
                        data["UserImage"],
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        height: 50,
                        width: 50,
                        color: Colors.grey[300],
                        child: Icon(Icons.person,
                            color: Colors.grey, size: 30),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        data["UserName"] ?? "",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),
              (data["Image"] ?? "").isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.network(
                  data["Image"],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              )
                  : SizedBox(),
              SizedBox(height: 10),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "${data["Location"] ?? ""}",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.green),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "${data["Type"] ?? ""} - ${data["PlaceName"] ?? ""}",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  data["Caption"] ?? "",
                  style: TextStyle(
                      color: Color.fromARGB(179, 0, 0, 0),
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Row(
                  children: [
                    // Like
                    GestureDetector(
                      onTap: () async {
                        if (id != null) {
                          await DatabaseMethods().toggleLike(ds.id, id!);

                          if (search) {
                            int index = tempSearchStore
                                .indexWhere((doc) => doc.id == ds.id);
                            if (index != -1) {
                              DocumentSnapshot updatedDoc = await FirebaseFirestore
                                  .instance
                                  .collection("Posts")
                                  .doc(ds.id)
                                  .get();

                              setState(() {
                                var oldData = tempSearchStore[index].data()
                                as Map<String, dynamic>;
                                oldData["Like"] =
                                List<String>.from(updatedDoc.get("Like") ?? []);
                              });
                            }
                          } else {
                            setState(() {});
                          }
                        }
                      },
                      child: Icon(
                        data["Like"]?.contains(id) == true
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        color: data["Like"]?.contains(id) == true
                            ? Colors.red
                            : Colors.black54,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _showLikesDialog(likeList),
                      child: Text(
                        "$likeCount Likes",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentPage(
                                userimage: image ?? "",
                                username: name ?? "",
                                postid: ds.id),
                          ),
                        );
                      },
                      child: Icon(Icons.comment_outlined,
                          color: Colors.black54, size: 28),
                    ),
                    SizedBox(width: 5),
                    Text("Commenti",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget per tutti i post
  Widget allPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: postStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return Center(child: Text("Nessun oggetto trovato"));

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return postCard(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  // Widget per risultati ricerca
  Widget searchResultsPosts() {
    if (tempSearchStore.isEmpty) return Center(child: Text("Nessun risultato trovato"));

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: tempSearchStore.length,
      itemBuilder: (context, index) {
        return postCard(tempSearchStore[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  "images/sfondo.jpg",
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height / 3.3,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileSetupPage(
                                userId: id,
                                defaultName: name,
                                defaultCity: city,
                                defaultDOB: dob,
                                defaultImage: image,
                                isEdit: true,
                              ),
                            ),
                          ).then((_) => getSharedPref());
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundImage:
                          image != null && image!.isNotEmpty ? NetworkImage(image!) : null,
                          child: image == null || image!.isEmpty ? Icon(Icons.person) : null,
                        ),
                      ),
                      Spacer(),
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications, size: 30, color: Colors.white),
                            onPressed: () {
                              showNewPostsDialog();
                            },
                          ),
                          if (newPostCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "$newPostCount",
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 120, left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FindMe",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Lato',
                            fontSize: 60,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "Perdere è umano, ritrovare è FindMe!",
                        style: TextStyle(
                            color: Color.fromARGB(205, 255, 255, 255),
                            fontSize: 20,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                      left: 30,
                      right: 30,
                      top: MediaQuery.of(context).size.height / 3.6),
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(width: 1.5),
                          borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          initiateSearch(value);
                        },
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Cerca il tuo oggetto",
                            suffixIcon: Icon(Icons.search)),
                      ),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: search ? searchResultsPosts() : allPosts(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "Aggiungi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Mappa",
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SelectTypePage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapPage(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
