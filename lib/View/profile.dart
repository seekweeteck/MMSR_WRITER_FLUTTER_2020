import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mmsr/Miscellaneous/settings.dart';
import 'package:mmsr/View/writerPublished.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:mmsr/View/login_page.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mmsr/Miscellaneous/inbox.dart';

import 'package:http/http.dart' as http;

import '../profilePicture.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => new _ProfilePageState();
}

//profile page (third page)
class _ProfilePageState extends State<ProfilePage> {
  String username;
  
  var contributorInfo; //follower

  void _getID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.get('loginID');
    });
  }

final _followersController = TextEditingController();

 var followers = "";
   Uint8List bytes;

 Future _getFollowers() async{
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var username = prefs.get('loginID');
 
  try {
      final contributorResponse = await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/checkExistContributor.php",
          body: {
            "ContributorID": username.toString(),
          });
      contributorInfo = json.decode(contributorResponse.body);
      if (contributorInfo[0]['picture'] != null)
        bytes = base64Decode(contributorInfo[0]['picture']);
      else
        bytes = null;
      if (contributorInfo.length > 0) {  
        
        _followersController.text = contributorInfo[0]['followers'];
        setState(() {
          followers = _followersController.text;
        });
      }
    } on SocketException {
      print("Connection error");
    }

    if(followers == null)
    {
      followers = "0";
    }
    
 }


  File galleryFile;
  var db;
  bool cancel;

  var totalStory;
  var storyPublished;
 

  var profileImage = AssetImage("assets/img/profile.png"); //default profile image

  bool switchVal = false;

  checkValue() async {
    totalStory = await db.getStorybookCount(); //count storybooks belongs to the user
    storyPublished = await db.getStorybookCountPublished(); //count storybooks which are published and belongs to the user
  }

  @override
  void initState() {
    _getID();
    _getFollowers();
    db = DBHelper();
    checkValue();

    //sometime the page run too fast and cause the count function cannot work properly, just simply initialize 0 instead of displaying 'NULL'
    if (totalStory == null) {
      totalStory = '0'; 
    }
    if (storyPublished == null) {
      storyPublished = '0';
    }
    
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //final appStyleMode = Provider.of<AppStyleModeNotifier>(context);
    return Scaffold(
      //backgroundColor: appStyleMode.primaryBackgroundColor,
      // appBar: AppBar(
      //   title: Text("Profile"),
      //   // actions: <Widget>[
      //   //   IconButton(
      //   //     icon: new Icon(Icons.settings),
      //   //     tooltip: 'Setting',
      //   //     onPressed: () {
      //   //       Navigator.push(
      //   //           context, MaterialPageRoute(builder: (context) => Settings()));
      //   //     },
      //   //   ),
      //   // ],
      //   automaticallyImplyLeading: false,
      // ),
      body: new SingleChildScrollView(
        child: new Container(
          height: MediaQuery.of(context).size.height,
          decoration: new BoxDecoration(
            borderRadius: BorderRadius.only(
              // topLeft: Radius.circular(55.0),
              // topRight: Radius.circular(55.0),
              // bottomLeft: Radius.circular(55.0),
              // bottomRight: Radius.circular(55.0),
            ),
            gradient: new LinearGradient(
                colors: [
                  Theme.ThemeColors.loginGradientStart,
                  Theme.ThemeColors.loginGradientEnd
                ],
                begin: const FractionalOffset(0.0, 0.0),
                end: const FractionalOffset(1.0, 1.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp),
          ),
          child:
              // new SingleChildScrollView(
              //   child:
              new Column(
            children: <Widget>[
              new Column(
                children: <Widget>[
                  new SizedBox(
                    height: 32,
                  ),
                  new Padding(
                    padding: new EdgeInsets.symmetric(
                        horizontal: 1.0, vertical: 1.0),
                    child: new Column(
                      children: <Widget>[
                        new Padding(
                          padding: new EdgeInsets.all(5.0),
                          child: new GestureDetector(
                            child: new Container(
                              height: 120.0,
                              width: 120.0,
                              decoration: bytes == null
                                  ? new BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      shape: BoxShape.circle,
                                      image: new DecorationImage(
                                        fit: BoxFit.fill,
                                        image: (galleryFile != null
                                            ? new FileImage(galleryFile)
                                            : profileImage),
                                      ),
                                    )
                                  : new BoxDecoration(),
                              child: bytes != null
                                  ? Image.memory(
                                      bytes,
                                      fit: BoxFit.cover,
                                    )
                                  : new Container(),
                            ),
                            onTap: () { //tap on image
                              // imageSelectorGallery();
                              Navigator.push(
                                //go to next page (story list)
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ProfilePicture(
                                          contributorID: contributorInfo[0]
                                              ['ContributorID'],
                                          //passStorybookID: storybookID,
                                        )),
                              );
                            },
                          ),
                        ),
                        // new CircleAvatar(
                        //   backgroundImage: profileImage,
                        // ),
                        new SizedBox(
                          height: 24.0,
                        ),
                        new Text(
                          ("ID: " + username.toString()), //display username
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ],
                    ),
                  ),
                  new SizedBox(
                    height: 16.0,
                  ),
                  new Padding(
                    padding: EdgeInsets.only(left: 32.0, right: 32.0),
                    child: new Container(
                      height: 4.0,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                            Theme.ThemeColors.buttonGradientStart,
                            Theme.ThemeColors.buttonGradientEnd,
                          ])),
                    ),
                  ),
                      
                  // new Padding(
                  //   padding: EdgeInsets.all(32.0),
                  //   child: new Row (
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: <Widget>[
                  //       new Column(
                  //         children: <Widget>[
                  //             new Container(
                  //               height:50,
                  //               width:50,
                  //               margin: const EdgeInsets.symmetric(
                  //                 horizontal: 20.0,
                  //               ),
                  //               child: Image.asset(
                  //                   "assets/img/story_created.png",
                  //                   fit: BoxFit.fill,
                  //         )
                  //       ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),



                  new Padding(
                    padding: EdgeInsets.all(32.0),
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                       
                        new Column(
                          children: <Widget>[
                            new Container(
                              height:50,
                              width: 50,
                              child: Image.asset("assets/img/story_created.png",
                              fit: BoxFit.fill,),
                            ),
                             new SizedBox(
                              height: 4.0,
                            ),
                            new Text(
                              (totalStory.toString()),
                              style: TextStyle(fontSize: 20.0, color: Colors.indigo),
                            ),
                            new SizedBox(
                              height: 4.0,
                            ),
                            new Text(
                              "Story Created",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15.0, color: Colors.blue,decoration:TextDecoration.underline),
                            ),
                            // new Text(
                            //   "created",
                            //   textAlign: TextAlign.justify,
                            //   style:
                            //       TextStyle(fontSize: 20.0, color: Colors.blue,decoration:TextDecoration.underline),
                            // ),
                          ],
                        ),
                        new Container(
                          width: 1,
                          height: 100.0,
                          color: Colors.grey,
                        ),
                         new Column(
                          children: <Widget>[
                            new Container(
                              height:50,
                              width: 50,
                              child: Image.asset("assets/img/followers.png",
                              fit: BoxFit.fill,),
                            ),
                             new SizedBox(
                              height: 4.0,
                            ),
                            new Text(
                              (followers.toString()), //Followers .toString()
                              style: TextStyle(fontSize: 20.0, color: Colors.indigo),
                            ),
                            new SizedBox(
                              height: 4.0,
                            ),
                            new Text(
                              "Followers",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16.0, color: Colors.blue,decoration:TextDecoration.underline),
                            ), 
                          ],
                        ),
                         new Container(
                          width: 1,
                          height: 100.0,
                          color: Colors.grey,
                        ), 
                        
                        GestureDetector(
                          onTap: () {
                          Navigator.push(context,
                          MaterialPageRoute(builder: (context) => LoadBookWriter(
                           contributorID:username.toString(),
                          ))); //Push to Published Book Details
                       }, 
                        child: Column(
                          children: <Widget>[
                            new Container(
                              height:50,
                              width: 50,
                              child: Image.asset("assets/img/story_published.png",
                              fit: BoxFit.fill,),
                            ),
                             new SizedBox(
                              height: 4.0,
                            ),
                            new Text(
                              (storyPublished.toString()),
                              style: TextStyle(fontSize: 20.0, color: Colors.indigo),
                            ),
                            new SizedBox(
                              height: 4.0,
                            ),
                            new Text(
                              "Story Published",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16.0, color: Colors.blue,decoration:TextDecoration.underline),
                            ),
                            // new Text(
                            //   "published",
                            //   textAlign: TextAlign.justify,
                            //   style:
                            //       TextStyle(fontSize: 20.0, color: Colors.blue,decoration:TextDecoration.underline),
                            // ),
                          ],
                        ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              new Divider(
                height: 1.0,
                color: Colors.grey,
              ),
              
              new ListTile(
                leading: new Icon(Icons.settings), //settings icon
                title: new Text('Settings'),
                onTap: () async {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Settings()));
                }, 
              ),
              new Divider(
                height: 1.0,
                color: Colors.grey,
              ),
              new ListTile(
                leading: new Icon(FontAwesomeIcons.signOutAlt),
                title: new Text('Sign Out'),
                onTap: () async {
                  _delete();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.remove('loginID'); //clear the shared preference so user can go to login page
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (Route<dynamic> route) => false);
                },
              ),
              new Divider(
                height: 1.0,
                color: Colors.grey,
              ),
            ],
          ),
          //),
          //
          ///),
        ),
      ),
    );
  }

  void imageSelectorGallery() async { //useless function (can use to change profile image, but not apply yet)
    var result;
    File croppedFile;

    try {
      galleryFile = await ImagePicker.pickImage(
        source: ImageSource.gallery,
      );

      try {
        croppedFile = await ImageCropper.cropImage(
          sourcePath: galleryFile.path,
          maxHeight: 512,
          maxWidth: 512,
        );

        result = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path,
          croppedFile.path,
          quality: 88,
        );
      } on NoSuchMethodError {
        setState(() {
          cancel = true;
          galleryFile = null;
        });

        print("Cancel selection");
      }

      if (galleryFile != null) {
        cancel = false;
        setState(() {
          if (cancel == false) {
            galleryFile = result;
          }
        });
      }
    } on PlatformException {
      print("Deny to gallery");
    }
  }

  _delete() async { //clear all the shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('loginID');
    prefs.remove('checkNav');
    prefs.remove('checkMain');
  }
}
