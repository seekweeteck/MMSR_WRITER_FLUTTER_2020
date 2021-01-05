import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mmsr/View/Homepage/detail.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mmsr/View/translator/translateLanguage.dart';
import 'package:mmsr/View/createStory/addStoryInfo.dart';
import 'package:mmsr/View/editStory/editInfo.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:mmsr/Controller/db.dart';
import 'package:mmsr/Model/storybook.dart';
import 'package:mmsr/Model/status.dart';
import 'package:mmsr/utils/navigator.dart';
import 'package:progress_dialog/progress_dialog.dart';

class PublishLoad extends StatefulWidget {
  @override
  PublishLoad({Key key}) : super(key: key);
  _PublishLoadState createState() => new _PublishLoadState();
}
//load state before entering the page
class _PublishLoadState extends State<PublishLoad> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  //String username;
  Future<List<Storybook>> storybooks;

  var db;

//init state
  @override
  void initState() {
    super.initState();
    db = DBHelper(); //open database
    storybooks = db.getStorybook(); //get all storybook belongs to the user from local storage
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      body: new FutureBuilder<List>(
          future: storybooks, 
          builder: (context, snapshot) {
            return snapshot.hasData 
                ? new UploadStory( //when all data finish loading, direct to write story page(second page)
                    data: snapshot.data, //pass the data to the next class
                  )
                : // new Text('No Storybooks Found');
                new Center( //when loading data, display loading icon
                    child: new SpinKitThreeBounce(color: Colors.blue),
                  );
          }),
    );
  }

}


class UploadStory extends StatefulWidget {
  final List data; //List of storybook data retrieved from the previous class
  
  UploadStory({Key key, this.data}) : super(key: key);
  @override
  _UploadStoryState createState() => new _UploadStoryState();
}

class _UploadStoryState extends State<UploadStory> {
  ProgressDialog pr; //progress dialog

  String passLanguageText;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //var refreshKey = GlobalKey<RefreshIndicatorState>();

  var updateStatus;

  StorybookStatus updateStorybook;

  var db;

  String username;

  Icon getStatus(String status) { //Icon function to display different icon based on the storybook's status
    Icon resultIcon;

    if (status == "Published") {
      resultIcon = Icon(Icons.publish, color: Colors.green);
    } else if (status == "Rejected") {
      resultIcon = Icon(Icons.no_sim, color: Colors.red);
    } else if (status == "Submitted") {
      //Pending
      resultIcon = Icon(Icons.done_all, color: Colors.blue);
    } else if (status == "In Progress") {
      resultIcon = Icon(Icons.mode_edit);
    }

    return resultIcon;
  }

  Future _getID() async { //get the username
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.get('loginID');
    });
  }

  @override
  void initState() {
    super.initState();
    db = DBHelper();
    _getID();
  }

  Future update() async { //update the storybook status (when swipe to refresh)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.get('loginID');

    try {
      final statusResponse = await http
          .post("http://i2hub.tarc.edu.my:8887/mmsr/updateStatus.php", body: {
        "ContributorID": username.toString(),
      });
      updateStatus = json.decode(statusResponse.body);

      if (updateStatus.length > 0) {
        for (int i = 0; i < updateStatus.length; i++) {
          updateStorybook = StorybookStatus(
            updateStatus[i]['storybookID'],
            updateStatus[i]['status'],
            updateStatus[i]['languageCode'],
          );
          db.updateStorybookStatus(updateStorybook);
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
  }

  Future<Null> refreshList() async {
    //refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 1)); //refresh icon remain 1 seconds
    if (this.mounted) {
      setState(() {
        update(); //when swipe to refresh, perform this function
      });
    }

    return null;
  }

//Header
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      //key: refreshKey,
      appBar: AppBar(
        title: Text('Your Work'),
        actions: <Widget>[
          IconButton(
              icon: new Icon(Icons.add),
              tooltip: 'Add a New Story',
              onPressed: () { //add new story
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddStoryInfo()),
                );
              }),
        ],
        automaticallyImplyLeading: false,
      ),
      body: new RefreshIndicator(
        child: new Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height >= 650.0
              ? MediaQuery.of(context).size.height
              : 1000.0,
          decoration: new BoxDecoration(
            gradient: widget.data.length != 0
                ? new LinearGradient(
                    colors: [
                      Theme.ThemeColors.loginGradientStart,
                      Theme.ThemeColors.loginGradientEnd
                    ],
                    begin: const FractionalOffset(0.0, 0.0),
                    end: const FractionalOffset(1.0, 1.0),
                    stops: [0.0, 1.0],
                    tileMode: TileMode.clamp)
                : new LinearGradient(
                    colors: [Colors.white, Colors.white],
                    begin: const FractionalOffset(0.0, 0.0),
                    end: const FractionalOffset(1.0, 1.0),
                    stops: [0.0, 1.0],
                    tileMode: TileMode.clamp),
          ),
          child: new Padding(
            padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
            child: widget.data.length != 0
                ? getBookContent(context)
                : _getEmpty(context),
          ),
        ),
        onRefresh: refreshList,
      ),
    );
  }

//Body of the page
  getBookContent(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: widget.data == null ? 0 : widget.data.length,
      itemBuilder: _getItemUI,
      padding: EdgeInsets.all(1.0),
    );
  }

  _getEmpty(BuildContext context) { //no storybook
    return new SingleChildScrollView(
      child: Center(
        child: new Padding(
          padding: EdgeInsets.fromLTRB(1.0, 100.0, 1.0, 100.0),
          child: new Column(
            children: <Widget>[
              new Image.asset(
                "assets/img/empty.png", //display image to show no storybook
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width / 1.2,
              ),
              Text(
                'No storybook yet',
                style: TextStyle(
                  fontFamily: 'WorkSansMedium',
                  fontSize: 30,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

//book rating 

//UI
  Widget _getItemUI(BuildContext context, int index) {
    Uint8List bytes = base64.decode(widget.data[index].storybookCover); //Convert the image from base64 format to Uint8List

    return new GestureDetector(
      onTap: () { //This is use to display the complete description of the language (a bit hardcoding)
        if (widget.data[index].languageCode == 'EN') {
          passLanguageText = 'English';
        } else if (widget.data[index].languageCode == 'MS') {
          passLanguageText = 'Bahasa Melayu';
        } else if (widget.data[index].languageCode == 'TA') {
          passLanguageText = 'தமிழ்';
        } else if (widget.data[index].languageCode == 'ZH(Sim)') {
          passLanguageText = '中文简体';
        } else if (widget.data[index].languageCode == 'ZH(Tra)') {
          passLanguageText = '中文繁体';
        } else {
          passLanguageText = null;
        }
        if (widget.data[index].status == 'Published' ||
            widget.data[index].status == 'Submitted') { //this is to show the dialog of not allow to edit if status = published/submitted
          _editDialog((widget.data[index].status).toString());
        } else { //when click on the storybook, it push to next page (edit info)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditInfo(
                titlePassText: widget.data[index].storybookTitle,
                descPassText: widget.data[index].storybookDesc,
                genreValue: widget.data[index].storybookGenre,
                languageValue: passLanguageText,
                readabilityLevel: widget.data[index].readabilityLevel,
                status: widget.data[index].status,
                cover: widget.data[index].storybookCover,
                id: widget.data[index].storybookID,
              ),
            ),
          );
        }
      },
      child: new Padding(
        padding: new EdgeInsets.symmetric(
            vertical: 8.0, horizontal: 16.0), //height and width of each box
        child: new Card(
          elevation: 8.0,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(16.0),
          ),
          child: new Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Card(
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(16.0),
                        ),
                        child: new Column(
                          children: <Widget>[
                            new Padding(
                              padding: new EdgeInsets.symmetric(
                                  horizontal: 1.0, vertical: 1.0),
                              child: new Row(
                                children: <Widget>[
                                  new Padding(
                                    padding: new EdgeInsets.all(5.0),
                                    child: new Container(
                                      height: 150.0,
                                      width: 115.0,
                                      child: new Image(
                                        image: new MemoryImage(bytes), //storybook cover display in list
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      new Expanded(
                        child: new ListTile(
                          trailing: PopupMenuButton<String>(
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuItem<String>>[
                              new PopupMenuItem<String>( //Translate 
                                value: 'Translate',
                                child: new Text('Translate'),
                              ),
                              widget.data[index].status == 'In Progress'
                                  ? new PopupMenuItem<String>( //If the status = in progress, show 'Publish' option
                                      value: 'Submitted',
                                      child: new Text('Publish'),
                                    )
                                  : widget.data[index].status == 'Submitted'
                                      ? new PopupMenuItem<String>( //If the status = submitted, show 'Unsubmitted' option
                                          value: 'Unsubmit',
                                          child: new Text('Unsubmitted'),
                                        )
                                      : widget.data[index].status == 'Published'
                                          ? new PopupMenuItem<String>( //If the status = published , show 'Unpublish' option
                                              value: 'Unpublish',
                                              child: new Text('Unpublish'),
                                            )
                                          : new PopupMenuItem<String>( //If the status = rejected, show 'Edit' option
                                              value: 'Edit',
                                              child: new Text('Edit'),
                                            ),
                              widget.data[index].status == 'In Progress'
                                  ? new PopupMenuItem<String>( //If the status = in progress, show 'Edit' option
                                      value: 'Edit',
                                      child: new Text('Edit'),
                                    )
                                  : null,
                              widget.data[index].status == 'Rejected'
                                  ? new PopupMenuItem<String>( //If the status = rejected, show 'Publish' option
                                      value: 'Submitted',
                                      child: new Text('Publish'),
                                    )
                                  : null,
                            ],
                            onSelected: (String value) {
                              if (value == 'Translate') {
                                setState(() {
                                  if (widget.data[index].status !=
                                      'Published') { //only published work can translate
                                    _translateDialog(); //dialog to tell user cannot translate
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TranslateLanguageLoad( //Translate page
                                          languageCode:
                                              widget.data[index].languageCode,
                                          storybookID:
                                              widget.data[index].storybookID,
                                          title:
                                              widget.data[index].storybookTitle,
                                          desc:
                                              widget.data[index].storybookDesc,
                                          genre:
                                              widget.data[index].storybookGenre,
                                          image:
                                              widget.data[index].storybookCover,
                                        ),
                                      ),
                                    );
                                  }
                                });
                              } else if (value == 'Unsubmit') {
                                confirmInProgress( //confirmation dialog (change to 'In Progress' status)
                                    widget.data[index].storybookID,
                                    widget.data[index].languageCode,
                                    "unsubmit");
                              } else if (value == 'Unpublish') {
                                confirmInProgress( //confirmation dialog (change to 'In Progress' status)
                                    widget.data[index].storybookID,
                                    widget.data[index].languageCode,
                                    "unpublish");
                              } else if (value == 'Submitted') {
                                confirmPublish(widget.data[index].storybookID,
                                    widget.data[index].languageCode);  //confirmation dialog (change to 'Published' status)
                              } else if (value == 'Edit') {
                                //To display complete language description (a bit hardcoding)
                                if (widget.data[index].languageCode == 'EN') {
                                  passLanguageText = 'English';
                                } else if (widget.data[index].languageCode ==
                                    'MS') {
                                  passLanguageText = 'Bahasa Melayu';
                                } else if (widget.data[index].languageCode ==
                                    'TA') {
                                  passLanguageText = 'தமிழ்';
                                } else if (widget.data[index].languageCode ==
                                    'ZH(Sim)') {
                                  passLanguageText = '中文简体';
                                } else if (widget.data[index].languageCode ==
                                    'ZH(Tra)') {
                                  passLanguageText = '中文繁体';
                                } else {
                                  passLanguageText = null;
                                }

                                Navigator.push( //push to edit info page
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditInfo(
                                       titlePassText: widget.data[index].storybookTitle,
                                       descPassText: widget.data[index].storybookDesc,
                                       genreValue: widget.data[index].storybookGenre,
                                       languageValue: passLanguageText,
                                       readabilityLevel: widget.data[index].readabilityLevel,
                                       status: widget.data[index].status,
                                       cover: widget.data[index].storybookCover,
                                       id: widget.data[index].storybookID,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          isThreeLine: true,
                          title: new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              new Expanded(
                                child: new Container(
                                  padding:
                                      EdgeInsets.fromLTRB(1.0, 10.0, 0.1, 5.0),
                                  child: new Text(
                                    widget.data[index].storybookTitle, //Title of the book
                                    textAlign: TextAlign.justify,
                                    style: new TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        wordSpacing: 0.1,
                                        height: 1.0,
                                        letterSpacing: 0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: new Text(
                            widget.data[index].storybookDesc, //Description of the book
                            textAlign: TextAlign.justify, //In justify
                            style: new TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.normal,
                                wordSpacing: 1.5,
                                height: 1.5),
                          ),
                        ),
                      ),
                    ], 
                  ),

              

                  //'ButtonTheme.bar' is deprecated and shouldn't be used. Use ButtonBarTheme instead. This feature was deprecated after
                  ButtonTheme.bar(//Bottom of the card
                    child: ButtonBar(
                      children: <Widget>[
                        getStatus(widget.data[index].status), //Status icon of the book
                        new Text(
                          widget.data[index].status, //Status of the book (Text,Eg: Published, Submitted)
                          style: new TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.normal,
                              wordSpacing: 1.5),
                        ),
                        new FlatButton( //Delete option for the book
                          splashColor: Colors.grey,
                          child: new Text(
                            "Delete",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                wordSpacing: 1.5),
                          ),
                          onPressed: () => _confirmDelete( //Confirmation dialog to delete the book
                              (widget.data[index].storybookTitle),
                              (widget.data[index].storybookID),
                              (widget.data[index].languageCode),
                              (widget.data[index].storybookCover),
                              (widget.data[index].storybookDesc),
                              (widget.data[index].storybookGenre),
                              username),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void confirmInProgress(String storybookID, String languageCode, String text) {//Confirmation dialog of changing the book status to 'In Progress'
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal); //Progress dialog
    pr.style(
      message: 'Please Wait...', //Message of the progress dialog
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      progressWidget: CircularProgressIndicator(),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progressTextStyle: TextStyle(
          color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
      messageTextStyle: TextStyle(
          color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    );
    showDialog( //Confirmation dialog
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Confirm to " + text + "?"),
            content: new Text("Story will back to editing mode."),
            actions: <Widget>[
              new FlatButton(
                  child: new Text(
                    "Cancel",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              new FlatButton(
                  child: new Text(
                    "Confirm",
                    style: new TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0),
                  ),
                  onPressed: () {
                    inProgress(storybookID, languageCode);
                    pr.show(); //Show progress dialog
                    Future.delayed(Duration(seconds: 3)).then((onValue) {
                      if (pr.isShowing()) {
                        pr.hide(); //Dismiss progress dialog
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => NavigatorWriter(
                                      page: 'one',
                                    )), //Back to second page on the bottom navigator bar[0,1,2]
                            (Route<dynamic> route) => false);
                      }
                    });
                  })
            ],
          );
        });
  }

  void confirmPublish(String storybookID, String languageCode) {//Confirmation dialog of changing the book status to 'Published'
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal); //Progress dialog
    pr.style(
      message: 'Submitting...',//Message of the progress dialog
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      progressWidget: CircularProgressIndicator(),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progressTextStyle: TextStyle(
          color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
      messageTextStyle: TextStyle(
          color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    );
    showDialog(//Confirmation dialog
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Confirm to publish?"),
            content: new Text("Approval process may take few days."),
            actions: <Widget>[
              new FlatButton(
                  child: new Text(
                    "Cancel",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              new FlatButton(
                  child: new Text(
                    "Confirm",
                    style: new TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0),
                  ),
                  onPressed: () {
                    submitted(storybookID, languageCode);
                    pr.show();//Show progress dialog
                    Future.delayed(Duration(seconds: 3)).then((onValue) {
                      if (pr.isShowing()) {
                        pr.hide();//Dismiss progress dialog
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => NavigatorWriter(
                                      page: 'one',
                                    )),//Back to second page on the bottom navigator bar[0,1,2]
                            (Route<dynamic> route) => false);
                      }
                    });
                  })
            ],
          );
        });
  }

  Future inProgress(String storybookID, String languageCode) async { //Update status to in progress
    try {
      await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/changeStoryStatus.php",
          body: {
            "status": "In Progress",
            "storybookID": storybookID,
            "languageCode": languageCode,
          });
    } on SocketException { //Network connection error
      print("Poor connection");
    }

    showInSnackBar('Story has changed to In Progress status');//Display snackbar
  }

  Future submitted(String storybookID, String languageCode) async {//Update status to submitted
    try {
      await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/changeStoryStatus.php",
          body: {
            "status": "Submitted",
            "storybookID": storybookID,
            "languageCode": languageCode,
          });
    } on SocketException {//Network connection error
      print("Poor connection");
    }
    showInSnackBar('Approval process may take few days');//Display snackbar
  }

  void _confirmDelete(String title, String id, String code, String cover,
      String desc, String genre, String contributorID) {//Confirmation dialog to delete
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal);//Progress dialog
    pr.style(
      message: 'Deleting...',//Message of the progress dialog
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      progressWidget: CircularProgressIndicator(),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progressTextStyle: TextStyle(
          color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
      messageTextStyle: TextStyle(
          color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600),
    );
    var db;
    db = DBHelper();
    showDialog(//Confirmation of deleting
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Confirm Deletion"),
            content: new Text("Delete the storybook " + title + " ?"),
            actions: <Widget>[
              new FlatButton(
                  child: new Text(
                    "Cancel",
                    style: new TextStyle(fontSize: 16.0, wordSpacing: 1.5),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              new FlatButton(
                child: new Text(
                  "Delete",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16.0,
                      wordSpacing: 1.5),
                ),
                onPressed: () {
                  db.deleteStorybook(id, code);
                  db.deletePage(id, code);
                  _deleteStorybook(
                      id, code, title, cover, desc, genre, contributorID);
                  pr.show();//Show progress dialog
                  Future.delayed(Duration(seconds: 3)).then((onValue) {
                    if (pr.isShowing()) {
                      pr.hide();//Dismiss progress dialog
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => NavigatorWriter()),
                          (Route<dynamic> route) => false);
                    }
                  });
                  setState(() {
                    showInSnackBar(title + ' has deleted'); //Display snackbar
                  });
                },
              ),
            ],
          );
        });
  }

  void showInSnackBar(String value) {//Red color snackbar function
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

  Future _deleteStorybook(String id, String code, String title, String cover,
      String desc, String genre, String contributorID) async {//Delete operation
    http.post("http://i2hub.tarc.edu.my:8887/mmsr/insertDeletebook.php", body: { //Insert deleted book into a new table
      "storybookTitle": title,
      "storybookCover": cover,
      "storybookDesc": desc,
      "storybookGenre": genre,
      "ContributorID": contributorID,
      "languageCode": code,
    });

    await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/deleteStorybook.php", body: { //Delete the storybook
      "storybookID": id,
      "languageCode": code,
    });

    await http.post("http://i2hub.tarc.edu.my:8887/mmsr/deletePage.php", body: { //Delete its related page
      "storybookID": id,
      "languageCode": code,
    });
  }

  void _editDialog(String status) { //Dialog to show unable to edit
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Unable to edit"),
            content: new Text("Book has " + status + " cannot be edit"),
            actions: <Widget>[
              new FlatButton(
                  child: new Text(
                    "OK",
                    style: new TextStyle(fontSize: 18.0, color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ],
          );
        });
  }

  void _translateDialog() { //Dialog to show unable to translate
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Unable to translate"),
            content: new Text("Only book has published can be translate"),
            actions: <Widget>[
              new FlatButton(
                  child: new Text(
                    "OK",
                    style: new TextStyle(fontSize: 18.0, color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ],
          );
        });
  }
}
