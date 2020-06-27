import 'package:budhub/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main(){
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_){
    print("Timestamps enables in snapshots\n");
  },
    onError: (_){
    print("Error enabling\n");
    }
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BudHub',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        accentColor: Colors.blueGrey
      ),
      home: Home(),
    );
  }
}
