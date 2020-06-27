import 'package:budhub/widgets/header.dart';
import 'package:budhub/widgets/progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final userRef = Firestore.instance.collection('users');


class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {

  @override
  void initState() {
    super.initState();
  }

  createUser() async{
    userRef.add({

    });
  }


//  getUsers() async {
//    final QuerySnapshot snapshot = await userRef.getDocuments();
//
//    setState(() {
//      users = snapshot.documents;
//    });
//
//    snapshot.documents.forEach((DocumentSnapshot doc){
//
//    });
//    userRef.getDocuments().then((QuerySnapshot snapshot){
//      snapshot.documents.forEach((DocumentSnapshot doc){
//        print(doc.data);
//      });
//    });

//  getUsersById() async {
//    final String id = "";
//    final DocumentSnapshot doc = await userRef.document(id).get();
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: userRef.snapshots(),
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          final List<Text> children = snapshot.data.documents.map((doc) => Text(doc['username'])).toList();
          return Container(
            child: ListView(
              children: children,
            ),
          );
        },
      ),
    );
  }
}

