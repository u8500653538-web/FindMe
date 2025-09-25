import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findme_programmazione_mobile/services/database.dart';

/// Pagina dei commenti per un post.
/// Permette di visualizzare i commenti esistenti e di aggiungerne di nuovi.
class CommentPage extends StatefulWidget {
  final String username, userimage, postid;
  final DatabaseMethods? db;

  CommentPage({
    required this.userimage,
    required this.username,
    required this.postid,
    this.db,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  late TextEditingController commentController;
  Stream<QuerySnapshot>? commentStream;
  late DatabaseMethods database;

  @override
  void initState() {
    super.initState();
    // Inizializza il controller per il campo di testo
    commentController = TextEditingController();
    // Usa il database passato o crea una nuova istanza
    database = widget.db ?? DatabaseMethods();
    loadComments();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  /// Carica i commenti del post dal database
  Future<void> loadComments() async {
    commentStream = await database.getComments(widget.postid);
    if (mounted) setState(() {});
  }

  /// Costruisce la lista dei commenti
  Widget allComments() {
    if (commentStream == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: commentStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ds = docs[index];
            return Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 20),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome utente che ha scritto il commento
                            Text(
                              ds["UserName"] ?? '',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            // Testo del commento
                            Text(
                              ds["Comment"] ?? '',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Invia un nuovo commento al database
  Future<void> sendComment() async {
    if (commentController.text.trim().isEmpty) return;

    final addComment = {
      "UserImage": widget.userimage,
      "UserName": widget.username,
      "Comment": commentController.text.trim(),
    };

    await database.addComment(addComment, widget.postid);
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con pulsante indietro e titolo
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10, right: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Aggiungi commento",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Lista dei commenti con campo per scrivere un nuovo commento
            Expanded(
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Container(
                  padding: EdgeInsets.only(left: 20, right: 10, top: 20),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(186, 250, 247, 247),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  width: double.infinity,
                  child: Column(
                    children: [
                      // Lista dei commenti
                      Expanded(child: allComments()),
                      SizedBox(height: 10),

                      // Campo di inserimento nuovo commento e pulsante invio
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black45,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: commentController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Scrivi un commento...",
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () async {
                              await sendComment();
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
