import 'package:flutter/material.dart';
import 'package:mmsr/View/profile.dart';
import 'package:mmsr/View/publish.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:mmsr/Model/languageModel.dart';
import 'package:mmsr/Model/storybook.dart';
import 'package:mmsr/Model/status.dart';
import 'package:mmsr/View/writerHome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class NavigatorWriter extends StatefulWidget {
  final String page; //parameter to check which page should direct to
  final String title; //useless (may delete?)
  final bool check; //useless (may delete?)
  NavigatorWriter({Key key, this.title, this.check, this.page})
      : super(key: key);

  @override
  _NavigatorState createState() => new _NavigatorState();
}

class _NavigatorState extends State<NavigatorWriter>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1; //initial page when the app open [0,1,2]
  final List<Widget> _children = [
    LoadBook(), //first page (display all book)
    PublishLoad(), //second page (write storybook)
    ProfilePage(), //third page (profile)
  ];
  var db;

  bool checkFirstTime;

  bool check;
  var languageData;

  String username;
  var storybookData;
  var updateStatus;

  Future<List<Storybook>> storybooks;
  StorybookStatus updateStorybook;

  bool mainPage;

  Future getContributorUpdateStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.get('loginID');
    mainPage = prefs.getBool('checkMain'); 

    if (mainPage == true || mainPage == null) {//first time use the app in the device
      try {
        if (username != null) {
          final updateResponse = await http.post(
              "http://i2hub.tarc.edu.my:8887/mmsr/uploadStoryPage.php",
              body: {
                "ContributorID": username,
              });
          storybookData = json.decode(updateResponse.body);

          if (storybookData.length != 0) {
            //Delete all storybook data while first time using the app
            db.deleteAllStorybook(username);
            for (int i = 0; i < storybookData.length; i++) {
              // db.deletePage(storybookData[i]['storybookID'],
              //     storybookData[i]['languageCode']);

              Storybook s = Storybook(
                storybookData[i]['storybookID'],
                storybookData[i]['storybookTitle'],
                storybookData[i]['storybookCover'],
                storybookData[i]['storybookDesc'],
                storybookData[i]['storybookGenre'],
                storybookData[i]['ReadabilityLevel'],
                storybookData[i]['status'],
                storybookData[i]['dateOfCreation'],
                storybookData[i]['ContributorID'],
                storybookData[i]['languageCode'],
              );

              db.saveStorybook(s); //insert all storybook data from server to local storage
              //this step is necessary in case user change device to login, so the new device contain all the storybook data of the user
            }
          }
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => NavigatorWriter()),
              (Route<dynamic> route) => false);
        }
      } on SocketException { 
        print("Poor connection");
      } on NoSuchMethodError {
        print("Error");
      }

      prefs.setBool('checkMain', false);
      return storybookData;
    } else { //not first time use the app in the device
      try {
        final statusResponse = await http
            .post("http://i2hub.tarc.edu.my:8887/mmsr/updateStatus.php", body: {
          "ContributorID": username,
        });
        updateStatus = json.decode(statusResponse.body);

        if (updateStatus.length > 0) {
          for (int i = 0; i < updateStatus.length; i++) {
            updateStorybook = StorybookStatus(
              updateStatus[i]['storybookID'],
              updateStatus[i]['status'],
              updateStatus[i]['languageCode'],
            );
            db.updateStorybookStatus(updateStorybook); //update status of the storybook only
          }
        }
      } on SocketException { //catch network connection error
        print("Poor connection"); //print on console
      } on NoSuchMethodError { //error that cannot be defined
        print("Error");
      }
    }
  }

  Future _check() async { //First time open the app display the first page [index 0]
    SharedPreferences prefs = await SharedPreferences.getInstance();

    checkFirstTime = prefs.getBool('checkNav');

    if (checkFirstTime == true || checkFirstTime == null) {
      _currentIndex = 0; 
      prefs.setBool('checkNav', false);
    }
  }

  Future _insertLanguage() async { //First time open the app will insert all the language into local storage (In future everytime can retrieve language data from local storage, faster speed)
    SharedPreferences prefs = await SharedPreferences.getInstance();

    check = prefs.getBool('checkLanguage');

    if (check == true || check == null) {
      final response =
          await http.post("http://i2hub.tarc.edu.my:8887/mmsr/getLanguage.php"); //retrieve language data from server
      languageData = json.decode(response.body);

      if (languageData.length > 0) {
        for (int i = 0; i < languageData.length; i++) {
          LanguageModel l = LanguageModel( //language class
              languageData[i]['languageCode'], languageData[i]['languageDesc']);
          db.saveLanguage(l); //save language data into local storage
        }
      }

      prefs.setBool('checkLanguage', false);
    }
  }

  @override
  void initState() {//initialize function when the navigator tab changed
    db = DBHelper();
    if (widget.page.toString() == 'zero') { //Based on the parameter passing, zero is first page (display book)
      _currentIndex = 0;
    } else if (widget.page.toString() == 'one') { //one is second page (write story)
      _currentIndex = 1;
    } else if (widget.page.toString() == 'two') { //two is third page (profile)
      _currentIndex = 2;
    }

    _check();
    _insertLanguage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex, //this will be set when a new tab is tapped
        items: [
          new BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.home),
            title: new Text('Home'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.pencilAlt),
            title: new Text('Upload Story'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.user),
            title: new Text('Profile'),
          )
        ],
      ),
    );
  }

  void onTabTapped(int index) { //this function change the page based on the user tapped [0,1,2]
    setState(() {
      if (index == 1) {
        getContributorUpdateStatus(); //if click on the write story page, update the status of the book
      }
      _currentIndex = index;
    });
  }
}
