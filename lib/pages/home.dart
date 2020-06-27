import 'dart:io';

import 'package:budhub/models/users.dart';
import 'package:budhub/pages/create_account.dart';
import 'package:budhub/pages/rough_timeline.dart' as prefix0;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:budhub/pages/timeline.dart';
import 'package:budhub/pages/notifications.dart';
import 'package:budhub/pages/upload.dart';
import 'package:budhub/pages/search.dart';
import 'package:budhub/pages/profile.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final notificationsRef = Firestore.instance.collection('notifications');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
 // GlobalKey _bottomNavigationKey = GlobalKey();



  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {});

    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {});
  }

  handleSignIn(GoogleSignInAccount account) async{
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications(){
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if(Platform.isIOS) getIOSPermission();
    
    _firebaseMessaging.getToken().then((token){
      print("$token");
      usersRef.document(user.id).updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
     // onLaunch: (Map<String, dynamic> message) async{},
      //onResume: (Map<String, dynamic> message) async{},
      onMessage: (Map<String, dynamic> message) async{
        print("$message");
        final String recipientId = message['data']['recepient'];
        final String body = message['notification']['body'];
        if(recipientId != user.id){
          SnackBar snackBar = SnackBar(content: Text(body, overflow: TextOverflow.ellipsis,));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
      }
    );
  }

  getIOSPermission(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(
      alert: true,
      badge: true,
      sound: true
    ));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings){
      print("$settings");
    });
  }

  createUserInFirestore() async{
    final GoogleSignInAccount user = googleSignIn.currentUser;
    final DocumentSnapshot doc = await usersRef.document(user.id).get();
    
    if(!doc.exists){
      final username = await Navigator.push(context, MaterialPageRoute(builder: (context)=> CreateAccount()));
      
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      await followersRef.document(user.id).collection('userFollowers').document(user.id).setData({});
    }

    currentUser = User.fromDocument(doc);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 500), curve: Curves.bounceInOut);
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          Notifications(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        index: 0,
        items: <Widget>[
          Icon(
            Icons.whatshot,
            size: 25,
            color: Colors.white,
          ),
          Icon(Icons.notifications_active, size: 25, color: Colors.white),
          Icon(Icons.photo_camera, size: 25, color: Colors.white),
          Icon(Icons.search, size: 25, color: Colors.white),
          Icon(Icons.account_circle, size: 25, color: Colors.white),
        ],
        buttonBackgroundColor: Colors.indigo,
        color: Colors.indigoAccent,
        height: 60,
        onTap: onTap,
      ),
    );
  }

  Scaffold buildHomeScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            GradientText(
              'BudHub',
              gradient: LinearGradient(colors: [
                Colors.indigoAccent,
                Colors.deepPurple,
                Colors.indigo,
                Colors.lightBlue
              ]),
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 90,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 100,
                height: 100,
                child: Icon(
                  FontAwesomeIcons.google,
                  size: 60,
                  color: Colors.grey[800],
                ),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey[600],
                          offset: Offset(4, 4),
                          blurRadius: 15,
                          spreadRadius: 1),
                      BoxShadow(
                          color: Colors.white,
                          offset: Offset(-4, -4),
                          blurRadius: 15,
                          spreadRadius: 1)
                    ],
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[200],
                          Colors.grey[300],
                          Colors.grey[400],
                          Colors.grey[500],
                        ],
                        stops: [
                          0.1,
                          0.3,
                          0.8,
                          0.9
                        ])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildHomeScreen();
  }
}
