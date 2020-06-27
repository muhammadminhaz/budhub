import 'dart:async';

import 'package:animator/animator.dart';
import 'package:budhub/models/users.dart';
import 'package:budhub/pages/comments.dart';
import 'package:budhub/pages/home.dart';
import 'package:budhub/pages/notifications.dart';
import 'package:budhub/widgets/custom_image.dart';
import 'package:budhub/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Post extends StatefulWidget {
  final String postId, ownerId, username, location, caption, mediaUrl;
  final dynamic likes;


  Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.caption,
      this.mediaUrl,
      this.likes});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      caption: doc['caption'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
      postId: this.postId,
      ownerId: this.ownerId,
      username: this.username,
      location: this.location,
      caption: this.caption,
      mediaUrl: this.mediaUrl,
      likes: this.likes,
      likeCount: getLikeCount(this.likes));
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id, postId, ownerId, username, location, caption, mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked, showHeart = false;

  _PostState(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.caption,
      this.mediaUrl,
      this.likes,
      this.likeCount});



  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return circularProgress();
        }

        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner ? IconButton(icon: Icon(Icons.more_vert), onPressed: () => handleDeletePost(context)) : Text(''),
        );


      },
    );
  }

  handleDeletePost(BuildContext parentContext){
    return showDialog(context: parentContext,
      builder: (context){
      return SimpleDialog(
        title: Text('Remove this post?'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: (){
              Navigator.pop(context);
              deletePost();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red),),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          )
        ],
      );
      }
    );
  }

  deletePost() async{
    postRef
    .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
    });
    storageRef.child("post_$postId.jpg").delete();
    QuerySnapshot notificationSnapshot = await notificationsRef.document(ownerId).collection('notificationItems').where('postId', isEqualTo: postId).getDocuments();
    notificationSnapshot.documents.forEach((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    QuerySnapshot commentsSnapshot = await commentsRef.document(postId).collection('comments').getDocuments();
    commentsSnapshot.documents.forEach((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
  }

  handleLikePost(){
    bool _isLiked = likes[currentUserId] == true;
    if(_isLiked){
      postRef.document(ownerId).collection('userPosts').document(postId).updateData({'likes.$currentUserId': false});
      removeLikeFromNotifications();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    }
    else if(!_isLiked){
      postRef.document(ownerId).collection('userPosts').document(postId).updateData({'likes.$currentUserId': true});
      addLikeToNotifications();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), (){
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  removeLikeFromNotifications(){
    bool isNotPostOwner = currentUserId != ownerId;
    if(isNotPostOwner){
      notificationsRef.document(ownerId).collection('notificationItems').document(postId).get().then((doc){
        if(doc.exists){
          doc.reference.delete();
        }
      });
    }

  }

  addLikeToNotifications(){
    bool isNotPostOwner = currentUserId != ownerId;
    if(isNotPostOwner){
      notificationsRef.document(ownerId).collection("notificationItems").document(postId).setData({
      "type": "like",
      "username": currentUser.username,
      "userId": currentUser.id,
      "userProfileImage": currentUser.photoUrl,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": timestamp
    });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart ? Animator<double>(
            tween: Tween<double>(begin: 0.8, end: 1.4),
            curve: Curves.elasticOut,
            cycles: 0,
            builder: (context, animatorState, child){
              return Center(
                child: Transform.scale(scale: animatorState.value,child: Icon(Icons.favorite, size: 80, color: Colors.white.withOpacity(0.7),)),
              );
            },
          ) : Text('')
          //showHeart ? Icon(Icons.favorite, size: 80, color: Colors.red,) : Text('')
        ],
      ),
    );
  }
  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40, left: 20)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pinkAccent,
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 40, left: 20)),
            GestureDetector(
              onTap: ()=> showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            )
          ],
        ),
        Row(

          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$likeCount likes",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$username ",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(caption),
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    isLiked = (likes[currentUserId] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );
  }
}

showComments(BuildContext context, {String postId, String ownerId, String mediaUrl}){
  Navigator.push(context, MaterialPageRoute(builder: (context){
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl
    );
  }));
}
