import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:http/http.dart' as http;
import 'package:mmsr/View/Homepage/page_content.dart';


class LoadDetail extends StatefulWidget {
  final List bookData;
  final String contributorID;
  final int index;
  final String contributor;
  final String language;

  LoadDetail(
      {Key key,
      this.bookData,
      this.contributorID,
      this.index,
      this.contributor,
      this.language,
      })
      : super(key: key);
  @override
  _LoadDetailState createState() => new _LoadDetailState();
}

class _LoadDetailState extends State<LoadDetail> {
  var db = DBHelper();
  String url = 'http://i2hub.tarc.edu.my:8887/mmsr/';

  @override
  void initState() {
    getReview();
    getLowHighRating();
    super.initState();
  }

  Future<List> getReview() async //retrieve all review data from server
  {
    final response = await http.post(
      url + "getRating.php", 
      body: {
        "storybookID": widget.bookData[widget.index]['storybookID'],
        "language": widget.bookData[widget.index]['languageCode']
      },
    );
    var reviewData = json.decode(response.body);
    return reviewData;
  }

   Future<List> getLowHighRating() async //retrieve all writer data from server
  {
    final response = await http.post(
      url + "getLowHighRating2.php",
      body: {"storyID": widget.bookData[widget.index]['storybookID']},
    );
    var lowHighRating = json.decode(response.body);
    return lowHighRating;
  }

 @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new FutureBuilder<List>(
        future: db.getStories(widget
            .contributorID), //widget.contributorID. Means using object of _LoadDetailState. The data are passed by previous pages.
        builder: (context, snapshot) {
          // if (snapshot.hasError) print(snapshot.error);
          if (snapshot.hasData) {
            return new FutureBuilder<List>(
                //if equal to true then continue retrieve other data
                future: getReview(),
                builder: (context, snapshot2) {
                  if (snapshot2.hasData) {
                    return new FutureBuilder<List> (
                      future:getLowHighRating(),
                      builder: (context,lowHigh){
                        if(lowHigh.hasData){
                          return new Detail(
                            localData: snapshot.data,
                            bookData: widget.bookData,
                            contributorID: widget.contributorID, 
                            index: widget.index,
                            contributor: widget.contributor,
                            language: widget.language,
                            review: snapshot2.data, 
                            lowHigh: lowHigh.data,
                      //Passing data into next widget.
                    );
                        }else{
                          return new Center(
                            child: SpinKitThreeBounce(color: Colors.blue),
                          );
                        }
                      }
                    );
                  } else {
                    return new Center(
                      child: SpinKitThreeBounce(color: Colors.blue),
                    );
                  }
                });
          } else {
            return new Center(
              child: SpinKitThreeBounce(color: Colors.blue),
            );
          }
        },
      ),
    );
  }
}

class Detail extends StatefulWidget {
  final List bookData,localData,review,lowHigh;
  final String contributorID;
  final int index;
  final String contributor;
  final String language;

  Detail(
      {Key key,
      this.bookData,
      this.contributorID,
      this.index,
      this.contributor,
      this.localData,
      this.language,
      this.review,
      this.lowHigh,})
      : super(key: key);
  @override
  _DetailState createState() => new _DetailState();
}

class _DetailState extends State<Detail> {
  String url = 'http://i2hub.tarc.edu.my:8887/mmsr/';
  bool exist = false;
  String storyLanguage = '', storyID = '', storyTitle = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Widget build(BuildContext context) {
    //app bar

    for (int i = 0; i < widget.localData.length; i++) {
      setState(() {
        if (widget.localData[i].storybookID ==
                widget.bookData[widget.index]['storybookID'] &&
            widget.localData[i].languageCode ==
                widget.bookData[widget.index]['languageCode']) {
          exist = true;
          // storyLanguage = widget.localData[i].languageCode;
          // storyTitle = widget.localData[i].story_title;
          // storyID = widget.localData[i].story_id;
        }
      });
    }

    final appBar = AppBar(
      elevation: 0.5,
      title: Text('Books Details'),
      actions: <Widget>[],
    );

    ///detail of book image and it's pages
    Uint8List bytes =
        base64Decode(widget.bookData[widget.index]['storybookCover']);
        bool rating = false;
    for (int j = 0; j < widget.review.length; j++) {
      if (widget.review[j]['storybookID'] ==
              widget.bookData[widget.index]['storybookID'] &&
          widget.review[j]['languageCode'] ==
              widget.bookData[widget.index]['languageCode']) {
        rating = true;
        break;
      }
    }

    final topLeft = Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Hero(
            tag: widget.bookData[widget.index]['storybookID'],
            child: Container(
              height: 200,
              child: Card(
                child: Image.memory(
                  bytes,
                  gaplessPlayback: true,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        //text('${book.pages} pages', color: Colors.black38, size: 12)
      ],
    );

    ///detail top right
    final topRight = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        text(widget.bookData[widget.index]['storybookTitle'],
            size: 22, isBold: true,  color: Colors.white, padding: EdgeInsets.only(top: 16.0)),
        SizedBox(height: 10),

        Material(
          borderRadius: BorderRadius.circular(20.0),
          shadowColor: Colors.blue.shade200,
          elevation: 5.0,
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 5, top: 5),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: 'by ${widget.contributor}',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                      ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        Table(
          columnWidths: {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(3),
          },
          children: [
            TableRow(
              children: [
                text(
                  'Genre',
                  color: Colors.white,
                  isBold: true,
                  padding: EdgeInsets.only(right: 8.0, top: 10),
                ),
                text(
                  '${widget.bookData[widget.index]['storybookGenre']}',
                  color: Colors.white70,
                  padding: EdgeInsets.only(right: 8.0, top: 10),
                ),
              ],
            ),
            TableRow(
              children: [
                text(
                  'Level',
                  color: Colors.white,
                  isBold: true,
                  padding: EdgeInsets.only(right: 8.0, top: 10),
                ),
                text(
                  '${widget.bookData[widget.index]['ReadabilityLevel']}',
                  color: Colors.white70,
                  padding: EdgeInsets.only(right: 8.0, top: 10),
                ),
              ],
            ),
            TableRow(
              children: [
                text(
                  'Created',
                  color: Colors.white,
                  isBold: true,
                  padding: EdgeInsets.only(right: 8.0, top: 10),
                ),
                text(
                  '${widget.bookData[widget.index]['PublishedDate']}',
                  color: Colors.white70,
                  padding: EdgeInsets.only(right: 8.0, top: 10),
                ),
              ],
            ),
            TableRow(
              children: [
                text(
                  'Rating',
                  color: Colors.white,
                  isBold: true,
                  padding: EdgeInsets.only(right: 8.0, top: 10),
                ),
                rating == true
                    ? Container(
                        padding: EdgeInsets.only(top: 6),
                        child: FlutterRatingBarIndicator(
                          rating: double.parse(
                              widget.bookData[widget.index]['rating']),
                          itemCount: 5,
                          itemSize: 16.0,
                          emptyColor: Colors.amber.withAlpha(100),
                        ),
                      )
                    : text(
                        "(No rating yet)",
                        color: Colors.white70,
                        padding: EdgeInsets.only(right: 8.0, top: 10),
                      ),
              ],
            ),
          ],
        ),


   
        SizedBox(height: 32.0),
        new GestureDetector(
          onTap: () {
            Navigator.push( //Push to read page content
              context,
              MaterialPageRoute(
                builder: (context) => LoadContent(
                  contributorID: widget.contributorID,
                  storyID: widget.bookData[widget.index]['storybookID'],
                  storyLanguage: widget.bookData[widget.index]['languageCode'],
                  storyTitle: widget.bookData[widget.index]['storybookTitle'],
                  storybookDesc: widget.bookData[widget.index]['storybookDesc'],
                  storybookGenre: widget.bookData[widget.index]
                      ['storybookGenre'],
                  storybookCover: widget.bookData[widget.index]
                      ['storybookCover'],
                ),
              ),
            );
          },
          child: new Material(
            borderRadius: BorderRadius.circular(20.0),
            shadowColor: Colors.blue.shade900,
            elevation: 5.0,
            child: new Container(
              width: MediaQuery.of(context).size.width / 1.8,
              height: 40.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.ThemeColors.lightColorButton,
                    Theme.ThemeColors.customButtonStart
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(5, 5),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Center( //Read now button
                child: Text(
                  'Read now',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final topContent = Container(
      color: Colors.blue,
      padding: EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(flex: 2, child: topLeft),
          Flexible(flex: 3, child: topRight),
        ],
      ),
    );

    ///scrolling text description 
        final bottomContent = Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Container(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Description',
                  style: TextStyle(
                      fontSize: 25.0,
                      height: 1.5,
                      fontFamily: 'WorkSansSemiBold')),
              SizedBox(height: 5),
              Text(
                widget.bookData[widget.index]['storybookDesc'],
                style: TextStyle(
                    fontSize: 15.0, height: 1.5, fontFamily: 'WorkSansLight'),
              ),
              SizedBox(height: 30),
              widget.lowHigh.length != 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              height: 27,
                              child: Image.asset("assets/img/recommend.png"),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Highly recommended',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  height: 1.5,
                                  fontFamily: 'WorkSansSemiBold'),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.lowHigh[0]['comment'],
                            style: TextStyle(
                                fontSize: 15.0,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'WorkSansLight'),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              SizedBox(height: 30),
              rating == true
                  ? Text('Review',
                      style: TextStyle(
                          fontSize: 25.0,
                          height: 1.5,
                          fontFamily: 'WorkSansSemiBold'))
                  : Container(),
              rating == true ? SizedBox(height: 5) : Container(),
              rating == true
                  ? Container(
                      child: ListView.builder(
                        primary: false,
                        shrinkWrap: true,
                        itemCount:
                            widget.review == null ? 0 : widget.review.length,
                        itemBuilder: (context, i) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(widget.review[i]['children_name'],
                                      style: TextStyle(
                                          fontSize: 15.0,
                                          height: 1.5,
                                          fontFamily: 'WorkSansMedium')),
                                  Text(widget.review[i]['rating_date'],
                                      style: TextStyle(
                                          fontSize: 13.0,
                                          height: 1.5,
                                          fontFamily: 'WorkSansLight')),
                                ],
                              ),
                              SizedBox(height: 5),
                              Container(
                                child: FlutterRatingBarIndicator(
                                  itemPadding: EdgeInsets.only(right: 1),
                                  rating: double.parse(
                                              widget.review[i]['value']) ==
                                          null
                                      ? 0
                                      : double.parse(widget.review[i]['value']),
                                  itemCount: 5,
                                  itemSize: 15.0,
                                  emptyColor: Color(0xFF525252),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                  widget.review[i]['comments'].isEmpty
                                      ? "(No comments)"
                                      : widget.review[i]['comments'],
                                  style: TextStyle(
                                      fontSize: 15.0,
                                      height: 1.5,
                                      fontFamily: 'WorkSansLight')),
                              SizedBox(
                                height: 10,
                              ),
                              i < widget.review.length - 1
                                  ? Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey, width: 0.6),
                                        ),
                                      ),
                                    )
                                  : Container(),
                              SizedBox(
                                height: 10,
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );

    //Main Scaffold Here
    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar,
      body: Column(
        children: <Widget>[
          topContent,
          bottomContent,
        ],
      ),
    );
  }

  ///create text widget
  text(String data,
          {Color color = Colors.black87,
          num size = 14,
          EdgeInsetsGeometry padding = EdgeInsets.zero,
          bool isBold = false}) =>
      Padding(
        padding: padding,
        child: Text(
          data,
          style: TextStyle(
              color: color,
              fontSize: size.toDouble(),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
      );

  void showInSnackBar(String value) { //Red snackbar
    FocusScope.of(context).requestFocus(new FocusNode());
    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontFamily: "WorkSansSemiBold"),
      ),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    ));
  }
}
