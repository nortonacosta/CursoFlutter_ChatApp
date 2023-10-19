import 'dart:io';
import 'package:chat_flutter/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chat_message.dart';



class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}



class _ChatScreenState extends State<ChatScreen> {

  //================= Autentitação de Usuario com Google =====================
  final  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }


  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<User?> _getUser() async {

    if (_currentUser != null) return _currentUser;


    try {
      final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
      );

      final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

      final User user = userCredential.user!;
      return user;
    } catch(error){
      return null;
    }
  }


  //esta entre {String text, File imgFile} para informar que são opcionais
   Future<void> _sendMessage({String? text, File? imgFile}) async{

      final User? user = await _getUser();

      if (user == null) {
        _scaffoldKey.currentState?.showBottomSheet((context) =>
          const Text('Não foi possível fazer o Login, Tente novamente!'),
            enableDrag: true,
            elevation: 200,
            backgroundColor: Colors.red);
      }

      Map<String, dynamic> data = {
        'uid': user!.uid,
        'senderName': user.displayName,
        'senderPhotoUrl': user.photoURL,
        'time': DateTime.now(),
      };

      if (imgFile != null){
        UploadTask task = FirebaseStorage.instance
            .ref()
            .child(user.uid + DateTime.now().microsecondsSinceEpoch.toString())
            .putFile(imgFile);

        setState(() {
          _isLoading = true;
        });

        TaskSnapshot taskSnapshot = await task;
        String url = await taskSnapshot.ref.getDownloadURL();
        data['imgUrl'] = url;

        setState(() {
          _isLoading = false;
        });


      }

      if (text != null) data['text'] = text;

      await FirebaseFirestore.instance.collection('messages').add(data);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser != null
            ? 'Olá, ${_currentUser!.displayName}'
            : 'Chat Online App'
        ),
        elevation: 0,
        actions: [
          _currentUser != null
          ? IconButton(
              icon: const Icon(Icons.exit_to_app_sharp),
              onPressed: (){
                FirebaseAuth.instance.signOut();
                googleSignIn.signOut();
                _scaffoldKey.currentState?.showBottomSheet(
                        (context) => const Text('Voce saiu com sucesso!'),
                enableDrag: true,
                  elevation: 200,
                );
              },
          )
              : Container(),
        ],
      ),
      body:
          Column(
            children: <Widget>[
              Expanded(
                child:
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .orderBy('time')
                      .snapshots(),
                  builder: (context, snapshot){
                    switch(snapshot.connectionState){
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                    default:
                      List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();
                    return ListView.builder(
                        itemCount: documents.length,
                        reverse: true,
                        itemBuilder: (context, index){
                          return ChatMessage(
                            data: documents[index].data() as Map<String, dynamic>,
                            mine: documents[index].get('uid') == _currentUser?.uid
                          );
                        }
                    );
                    }
                  },
              ),
              ),
              _isLoading ? const LinearProgressIndicator() : Container(), // mostra barra que esta carregando algo
              TextComposer(sendMessage: _sendMessage),
            ],
          ),
    );
  }
}

