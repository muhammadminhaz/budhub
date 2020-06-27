import 'package:budhub/models/users.dart';
import 'package:budhub/pages/home.dart';
import 'package:budhub/pages/notifications.dart';
import 'package:budhub/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search> {

  Future<QuerySnapshot> searchResultFuture;
  TextEditingController searchController = TextEditingController();

  handleSearch(String query){
    Future<QuerySnapshot> users = usersRef.where("displayName", isGreaterThanOrEqualTo: query).getDocuments();

    setState(() {
      searchResultFuture = users;
    });


  }

  clearSearch(){
    searchController.clear();
  }

  AppBar buildSearchField() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
            hintText: 'Search for a user...',
            filled: true,
            prefixIcon: Icon(
              Icons.account_box,
              size: 28,
            ),
            suffixIcon: IconButton(icon: Icon(Icons.clear), onPressed: () {
              clearSearch();
            })),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent() {

    final orientation = MediaQuery.of(context).orientation;

    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text('Find Users', textAlign: TextAlign.center, style:
              TextStyle(
                color: Colors.blueGrey,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: orientation == Orientation.portrait ? 60 : 40
              ),)
          ],
        ),
      ),
    );
  }

  buildSearchResults(){
    return FutureBuilder(
      future: searchResultFuture,
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();

        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc){
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);
          searchResults.add(searchResult);

        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(

      appBar: buildSearchField(),
      body: searchResultFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {

  final User user;
  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff121212),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(user.displayName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              subtitle: Text(user.username, style: TextStyle(color: Colors.white),),
            ),
          ),
          Divider(
            height: 2,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}
