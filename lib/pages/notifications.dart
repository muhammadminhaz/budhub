import 'package:budhub/pages/home.dart';
import 'package:budhub/pages/post_screen.dart';
import 'package:budhub/pages/profile.dart';
import 'package:budhub/widgets/header.dart';
import 'package:budhub/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class Notifications extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  getNotifications() async{
    QuerySnapshot snapshot = await notificationsRef.document(currentUser.id).collection('notificationItems').orderBy('timestamp', descending: true).limit(50).getDocuments();
    List<NotificationItem> notiItems = [];
    snapshot.documents.forEach((doc){
      notiItems.add(NotificationItem.fromDocument(doc));
    });
    return notiItems;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Notifications"),
      body: Container(
        child: FutureBuilder(
          future: getNotifications(),
          builder: (context, snapshot){
            if(!snapshot.hasData){
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}

Widget mediaPreview;
String notificationItemText;

class NotificationItem extends StatelessWidget {

  final String username, userId, type, mediaUrl, postId, userProfileImage, commentData;
  final Timestamp timestamp;

  NotificationItem({
    this.username,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileImage,
    this.commentData,
    this.timestamp

});

  factory NotificationItem.fromDocument(DocumentSnapshot doc){
    return NotificationItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      postId: doc['postId'],
      userProfileImage: doc['userProfileImage'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
    );
  }

  showPost(context){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: userId,
        )
      )
    );
  }

  configureMediaPreview(context){
    if(type == "like" || type == "comment") {
      mediaPreview = GestureDetector(
        onTap: ()=> showPost(context),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: CachedNetworkImageProvider(mediaUrl)
          )
          ),
          ),
          ),
        ),
      );
    }

    else {
      mediaPreview = Text('');
    }

    if(type == 'like'){
      notificationItemText = "liked your post";
    }
    else if(type == 'follow'){
      notificationItemText = "is following you";
    }
    else if(type == 'comment'){
      notificationItemText = "replied: $commentData";
    }
    else{
      notificationItemText = 'Error: unknown type $type';
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Container(
        color: Colors.black12,
        child: ListTile(
          title: GestureDetector(
            onTap: ()=> showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                  TextSpan(
                      text: ' $notificationItemText'
                  ),
                ]
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImage),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black
            ),
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(context, {String profileId}){
  Navigator.push(context, MaterialPageRoute(builder: (context) => Profile(profileId: profileId,)));
}


