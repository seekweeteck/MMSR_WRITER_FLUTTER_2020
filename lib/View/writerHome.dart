import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mmsr/View/Homepage/detail.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mmsr/utils/navigator.dart';
import 'package:mmsr/utils/transparent_image.dart';

//First page of the app (display all book)
class LoadBook extends StatefulWidget { 
  LoadBook({Key key}) : super(key: key);
  @override
  _LoadBookState createState() => new _LoadBookState(); 
}
//load the book before entering the page
class _LoadBookState extends State<LoadBook> {
  String url = 'http://i2hub.tarc.edu.my:8887/mmsr/';

  var storyData;
  var contributorData;

  Future<List> _getAllStorybook() async { //Get all storybook data
    try {
      final readResponse = await http.post(
        url + "allStorybook.php", 
      ); 
      storyData = json.decode(readResponse.body); 
    } on SocketException {//Network connection error
      print("Poor connection");
    } on http.ClientException {//Unknown error
      print("Error");
    }
    return storyData;
  }

  Future<List> _getAllContributor() async {//Get all contributor data
    try {
      final contributorResponse = await http.post(
        url + "getAllContributor.php",
      );
      contributorData = json.decode(contributorResponse.body);
    } on SocketException {
      print("Poor connection");
    } on http.ClientException {
      print("Error");
    }
    return contributorData;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new FutureBuilder<List>(
        future: _getAllStorybook(),//Get all storybook first
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return new FutureBuilder<List>(
              future: _getAllContributor(),//Then get all contributor
              builder: (context, snapshot2) {
                return snapshot2.hasData
                    ? new WriterHome(//Push to the page to display all book
                        data: snapshot.data,//storybook data
                        contributorData: snapshot2.data,//contributor data
                      )
                    : new Center(
                        child: new SpinKitThreeBounce(color: Colors.blue),//loading indicator
                      );
              },
            );
          } else {
            new Center(
              child: new SpinKitThreeBounce(color: Colors.blue),//loading indicator
            );
          }
          return SpinKitThreeBounce(color: Colors.blue);//loading indicator
        },
      ),
    );
  }
}

class WriterHome extends StatefulWidget {
  final List data;//storybook data
  final List contributorData;//contributor data

  WriterHome({
    Key key,
    this.data,
    this.contributorData,
  }) : super(key: key);
  
  @override
  _WriterHomeState createState() => new _WriterHomeState();
}

class _WriterHomeState extends State<WriterHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String url = 'http://i2hub.tarc.edu.my:8887/mmsr/';
  String language;

  List<String> nameList = List<String>();

  @override
  void initState() {
    super.initState();
  }

  Future<Null> refreshList() async {//refresh function
    await Future.delayed(Duration(seconds: 1));//refresh icon remain 1 second
    if (this.mounted) {
      setState(() { //when refresh, push to the same page
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => NavigatorWriter(
                page: 'zero',
              ),
            ),
            (Route<dynamic> route) => false);
      });
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        title: Text('Home'),
      ),
      key: _scaffoldKey,
      body: new RefreshIndicator(
        child: new Container(
          decoration: new BoxDecoration(
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
          child: new GridView.count(
            crossAxisCount: 1,
            children: List.generate(
              widget.data.length,
              (index) {
                Uint8List bytes =
                    base64Decode(widget.data[index]['storybookCover']); //Convert storybook cover from base64 to Uint8List

                //To show complete language description (a bit hardcoding)
                widget.data[index]['languageCode'] == 'EN'
                    ? language = 'English'
                    : widget.data[index]['languageCode'] == 'MS'
                        ? language = 'Bahasa Melayu'
                        : widget.data[index]['languageCode'] == 'TA'
                            ? language = 'தமிழ்'
                            : widget.data[index]['languageCode'] == 'ZH(Sim)'
                                ? language = '中文简体'
                                : widget.data[index]['languageCode'] ==
                                        'ZH(Tra)'
                                    ? language = '中文繁体'
                                    : language = null;

                for (int i = 0; i < widget.contributorData.length; i++) { //Store contributor full name in a list (based on the order of displaying storybook)
                  if (widget.contributorData[i]['ContributorID'] ==
                      widget.data[index]['ContributorID']) {
                    nameList
                        .add((widget.contributorData[i]['Name']).toString());
                  }
                }

                return new GestureDetector(
                  onTap: () { //Push to next page(showing detail of the book)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoadDetail(
                          bookData: widget.data,
                          index: index,
                          contributor: nameList[index],
                          contributorID: widget.data[index]['ContributorID'],
                          language: language,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 10.0,
                    margin: EdgeInsets.all(10.0),
                    shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(20.0),
                    ),
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        new Expanded(
                          child: new Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              new Expanded(
                                child: new Padding(
                                  padding: EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                                  child: new Align(
                                    alignment: Alignment.centerLeft,
                                    child: new FadeInImage(
                                      fit: BoxFit.fill,
                                      height:
                                          MediaQuery.of(context).size.height /
                                              2,
                                      width: MediaQuery.of(context).size.width /
                                          2.1,
                                      image: MemoryImage(bytes),//storybook cover
                                      placeholder:
                                          MemoryImage(kTransparentImage), //to solve image blinking problem
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        new Expanded(
                          child: new Padding(
                            padding:
                                new EdgeInsets.fromLTRB(5.0, 1.0, 10.0, 5.0),
                            child: new Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                new Align(
                                  alignment: Alignment.centerLeft,
                                  child: new Text(
                                    widget.data[index]['storybookTitle'], //storybook title
                                    style: new TextStyle(
                                        fontSize: 25,
                                        fontFamily: 'WorkSansBold'),
                                  ),
                                ),
                                new Align(
                                  alignment: Alignment.centerLeft,
                                  child: new Text(
                                    'by ' + nameList[index].toString(), //contributor name
                                    style: new TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontFamily: 'WorkSansMedium'),
                                  ),
                                ),
                                new Align(
                                  alignment: Alignment.centerLeft,
                                  child: new Text(
                                    'Created: ' +
                                        widget.data[index]['dateOfCreation'], //date of creation of the book
                                    style: new TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'WorkSansSemiBold'),
                                  ),
                                ),

                                new Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      color: Colors.black12,
                                      child: Text(
                                        language, //language of the book
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                            fontFamily: 'WorkSansSemiBold'),
                                      ),
                                    ),
                                  ],
                                ),
                                // ),
                                new Align(
                                  alignment: Alignment.centerLeft,
                                  child: new Container(
                                    child: FlutterRatingBarIndicator(//rating bar
                                      rating:
                                          widget.data[index]['rating'] == null
                                              ? 0
                                              : double.parse(
                                                  widget.data[index]['rating']),
                                      itemCount: 5,
                                      itemSize: 20.0,
                                      emptyColor: Colors.amber.withAlpha(50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        onRefresh: refreshList,
      ),
    );
  }
}
