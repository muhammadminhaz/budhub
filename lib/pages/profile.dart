import 'package:budhub/models/users.dart';
import 'package:budhub/pages/edit_profile.dart';
import 'package:budhub/pages/home.dart';
import 'package:budhub/widgets/header.dart';
import 'package:budhub/widgets/post.dart';
import 'package:budhub/widgets/post_tile.dart';
import 'package:budhub/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  bool isFollowing = false;
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  String postOrientation = "grid";
  int postCount = 0, followerCount = 0, followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }
  getFollowers() async{
    QuerySnapshot snapshot = await followersRef.document(widget.profileId).collection('userFollowers').getDocuments();
    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getFollowing() async{
    QuerySnapshot snapshot = await followingRef.document(widget.profileId).collection('userFollowing').getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  checkIfFollowing() async{
    DocumentSnapshot doc = await followersRef.document(widget.profileId).collection('userFollowers').document(currentUserId).get();
    isFollowing = doc.exists;
  }


  getProfilePosts() async{
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef.document(widget.profileId).collection('userPosts')
    .orderBy('timestamp', descending: true)
    .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildCountColumn(String label, int count){
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400
            ),
          ),
        )
      ],
    );
  }

  editProfile(){
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => EditProfile(
        currentUserId: currentUserId,
      )
    ));
  }

  buildButton({String text, Function function}){
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: FlatButton(onPressed: function, child: Container(
        width: 200,
        height: 27,
        child: Center(
          child: Text(text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white : Colors.blue,
          border: Border.all(
            color: isFollowing ? Colors.blueGrey : Colors.indigoAccent
          ),
          borderRadius: BorderRadius.circular(7)
        ),
      )),
    );
  }

  buildProfileButton(){
    bool isProfileOwner = currentUserId == widget.profileId;
    if(isProfileOwner){
      return buildButton(
        text: 'Edit Profile',
        function: editProfile
      );
    }
    else if(isFollowing){
      return buildButton(
        text: 'Unfollow',
        function: handleUnfollowUser
      );
    }
    else if(!isFollowing){
      return buildButton(
          text: 'Follow',
          function: handleFollowUser
      );
    }

  }

  handleFollowUser(){
    setState(() {
      isFollowing = true;
    });
    followersRef.document(widget.profileId).collection('userFollowers').document(currentUserId).setData({});
    followingRef.document(currentUserId).collection('userFollowing').document(widget.profileId).setData({});
    notificationsRef.document(widget.profileId).collection('notificationItems').document(currentUserId).setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUserId,
      "userProfileImage": currentUser.photoUrl,
      "timestamp": timestamp
    });
  }
  handleUnfollowUser(){
    setState(() {
      isFollowing = false;
    });
    followersRef.document(widget.profileId).collection('userFollowers').document(currentUserId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    followingRef.document(currentUserId).collection('userFollowing').document(widget.profileId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    notificationsRef.document(widget.profileId).collection('notificationItems').document(currentUserId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
  }

  buildProfileHeader(){
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
            padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("following", followingCount),
                            buildCountColumn("followers", followerCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton()
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),

              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2),
                child: Text(user.bio),
              )
            ],
          ),
        );
      },
    );
  }

  buildProfilePost(){
    if(isLoading){
      return circularProgress();
    }

    else if(posts.isEmpty){
      return Center(
        child: Text(
          "No Posts Yet! :("
        ),
      );
    }

    else if(postOrientation == "grid"){
      List<GridTile> gridTiles = [];
      posts.forEach((post){
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    }

    else if(postOrientation == "list"){
      return Column(
        children: posts,
      );
    }

//    return Column(
//      children: posts
//    );
  }

  setPostOrientation(String postOrientation){
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildToggleOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid' ? Colors.indigoAccent : Colors.grey,
          onPressed: (){
            setPostOrientation("grid");
          },
        ),
        IconButton(
          icon: Icon(Icons.list),
          color: postOrientation == 'list' ? Colors.indigoAccent : Colors.grey,
          onPressed: (){
            setPostOrientation("list");
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Profile'),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildToggleOrientation(),
          Divider(height: 0,),
          buildProfilePost()
        ],
      ),
    );
  }


}

