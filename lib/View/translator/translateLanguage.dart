import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mmsr/View/translator/translateInfo.dart';
import 'package:mmsr/Model/page.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:translator/translator.dart';

class TranslateLanguageLoad extends StatefulWidget {
  final String desc;
  final String genre;
  final String languageCode;
  final String storybookID;
  final String title;
  final String image;
  @override
  TranslateLanguageLoad(
      {Key key,
      this.languageCode,
      this.storybookID,
      this.title,
      this.desc,
      this.genre,
      this.image})
      : super(key: key);
  _TranslateLanguageLoadState createState() =>
      new _TranslateLanguageLoadState();
}
//Load all the language before entering the page
class _TranslateLanguageLoadState extends State<TranslateLanguageLoad> {
  var languageData;
  Future<List> getLanguage() async {//disable the original language from the translate language list (prevent user from confusing)
    try {
      final response = await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/translatorLanguage.php",
          body: {
            'languageCode': widget.languageCode,
          });
      languageData = json.decode(response.body);
    } on SocketException {
      print("Poor connection");
    }

    return languageData;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new FutureBuilder<List>(
        future: getLanguage(),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? new TranslateLanguage(//proceed to the language page
                  data: snapshot.data,
                  title: widget.title,
                  storybookID: widget.storybookID,
                  languageCode: widget.languageCode,
                  genre: widget.genre,
                  image: widget.image,
                  desc: widget.desc,
                )
              : new Center(
                  child: new CircularProgressIndicator(),//loading indicator
                );
        },
      ),
    );
  }
}

class TranslateLanguage extends StatefulWidget {
  final String storybookID;
  final String title;
  final String languageCode;
  final String desc;
  final String genre;
  final String image;
  final List data;
  TranslateLanguage(
      {Key key,
      this.data,
      this.storybookID,
      this.title,
      this.languageCode,
      this.desc,
      this.genre,
      this.image})
      : super(key: key);
  @override
  _TranslateLanguageState createState() => new _TranslateLanguageState();
}

class _TranslateLanguageState extends State<TranslateLanguage> {
  final String storybookIDAlphabet = "S";
  static int storybookIDNumber = 10001; //useless
  String storybookID = "";

  int selected;
  int radioValue = 0;

  var languageVar;
  bool check = true;
  var pageData;
  var db;
  bool checkTranslatePage;

  ProgressDialog pr; //progress dialog

  final translator = GoogleTranslator(); //google translator declare
  String translationTitle;//translated title
  String translationDesc;//translated description

  String fromLanguage;//from which language
  String toLanguage;//to which language

  @override
  void initState() {
    db = DBHelper();
    _limit();
    getPage();
    super.initState();
  }

  Future _limit() async {//check whether this story translated or not, only a story without translation can be translate
    try {
      final lanResponse = await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/translateLimitLanguage.php",
          body: {
            'storybookID': widget.storybookID,
          });
      languageVar = json.decode(lanResponse.body);
    } on SocketException {
      print("Poor connection");
    }

    return languageVar;
  }

  Widget _buildPageList() {
    return new ListView.separated(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: widget.data == null ? 0 : widget.data.length,
      itemBuilder: (context, index) {
        return new RadioListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          value: 1,
          groupValue: selected,
          title: new Text(widget.data[index]['languageDesc']), //display list of language
          onChanged: (value) {
            setState(() {
              selected = value;
            });
            selected = 0;

            if (languageVar.length != 0) {//meaning this story already translated by someone
              for (int i = 0; i < languageVar.length; i++) {
                if (widget.data[index]['languageCode'] ==
                    languageVar[i]['languageCode']) {
                  check = false;
                }
              }
            }

            if (check == true) {//this book is ok to translate
              pr = new ProgressDialog(context, type: ProgressDialogType.Normal);//progress dialog
              pr.style(
                message: 'Translating...',//message of progress dialog
                borderRadius: 10.0,
                backgroundColor: Colors.white,
                progressWidget: CircularProgressIndicator(),
                elevation: 10.0,
                insetAnimCurve: Curves.easeInOut,
                progressTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400),
                messageTextStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 19.0,
                    fontWeight: FontWeight.w600),
              );

              //_storybook();
              translate(index);//translate to which language, index indicate the order of language
              pr.show();//show progress dialog
              Future.delayed(Duration(seconds: 3)).then((onValue) {
                if (pr.isShowing()) {
                  pr.hide();//dismiss progress dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TranslateInfo(//next page (edit translated info)
                        fromLanguage: widget.languageCode,
                        descPassText: translationDesc,
                        genreValue: widget.genre,
                        languageValue: widget.data[index]['languageCode'],
                        passStorybookID: widget.storybookID,
                        titlePassText: translationTitle,
                        newStoryID: storybookID,
                        passImage: widget.image,
                      ),
                    ),
                  );
                }
              });
            } else {
              _showMessage(widget.data[index]['languageDesc']); //meaning this language of this book has translated by someone
              check = true;
            }
          },
        );
      },
      separatorBuilder: (context, index) {
        return new Divider(
          height: 1.0,
          color: Colors.grey,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose language to translate'),
        centerTitle: true,
      ),
      body: new SingleChildScrollView(
          child: new Column(
        children: <Widget>[
          _buildPageList(),
          new Divider(
            height: 1.0,
            color: Colors.grey,
          ),
        ],
      )),
    );
  }

  void _showMessage(String lang) {//Dialog to tell user this story with this language already exist
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Unable translate to " + lang),
            content: new Text("Storybook with " + lang + " already exist"),
            actions: <Widget>[
              new FlatButton(
                child: new Text(
                  "OK",
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16.0,
                      wordSpacing: 1.5),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void translate(int index) async {//translation process
    //language part abit hardcoding
    //languageCode is the original language code that we defined for own use
    //from & to language is the google language code
    if (widget.languageCode == 'EN') {
      fromLanguage = 'en';
    } else if (widget.languageCode == 'TA') {
      fromLanguage = 'hi';
    } else if (widget.languageCode == 'MS') {
      fromLanguage = 'ms';
    } else if (widget.languageCode == 'ZH(Sim)') {
      fromLanguage = 'zh-CN';
    } else if (widget.languageCode == 'ZH(Tra)') {
      fromLanguage = 'zh-TW';
    }

    if (widget.data[index]['languageCode'] == 'EN') {
      toLanguage = 'en';
    } else if (widget.data[index]['languageCode'] == 'TA') {
      toLanguage = 'hi';
    } else if (widget.data[index]['languageCode'] == 'MS') {
      toLanguage = 'ms';
    } else if (widget.data[index]['languageCode'] == 'ZH(Sim)') {
      toLanguage = 'zh-CN';
    } else if (widget.data[index]['languageCode'] == 'ZH(Tra)') {
      toLanguage = 'zh-TW';
    }

    try {//this is the process of translating title and description
      translationTitle = await translator.translate(widget.title,
          from: fromLanguage, to: toLanguage);
      translationDesc = await translator.translate(widget.desc,
          from: fromLanguage, to: toLanguage);
    } on SocketException {//network connection error and cause fail linking to translation API
      print("Translation fail");//Here should do something instead of print on console
    }
  }

  // Future _storybook() async {
  //   var storybookIDCheck;

  //   final storybookResponse = await http.post(
  //       "http://i2hub.tarc.edu.my:8887/mmsr/checkStorybookID.php"); //Read last storybook ID
  //   //SELECT * FROM Storybook
  //   storybookIDCheck = json.decode(storybookResponse.body); //1 data only

  //   //Initialize storybookID
  //   if (storybookIDCheck.length == 0) {
  //     storybookID =
  //         storybookIDAlphabet + (storybookIDNumber.toString()); //S10001
  //   } else {
  //     int storybookTempNo = int.parse(storybookIDCheck[0]['storybookID']
  //         .substring(storybookIDCheck[0]['storybookID'].length - 5));

  //     storybookTempNo++;
  //     storybookID = storybookIDAlphabet + storybookTempNo.toString();
  //   }
  // }

  Future<List> getPage() async {
    //this function ensure the page information never be empty
    //it retrieve page data from server to local storage
    //incase user clear app storage, this function still can retrieve info from server
    //this function only run 1 time (first time unless user clear the app storage)
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    checkTranslatePage = prefs.getBool(
        'checkTranslatePage' + widget.storybookID + widget.languageCode);//this unique shared preference ensure it only run 1 time

    if (checkTranslatePage == true || checkTranslatePage == null) {
      try {
        //retrieve from server
        final response = await http
            .post("http://i2hub.tarc.edu.my:8887/mmsr/getPage.php", body: {
          'storybookID': widget.storybookID,
          'languageCode': widget.languageCode,
        });
        pageData = json.decode(response.body);

        for (int i = 0; i < pageData.length; i++) {
          Page p = Page(
            pageData[i]['pageID'],
            pageData[i]['pageNo'],
            pageData[i]['pagePhoto'],
            pageData[i]['pageContent'],
            pageData[i]['storybookID'],
            pageData[i]['languageCode'],
          );
          db.savePage(p);//store in local storage
        }
      } on SocketException {
        print("Poor connection");
      }
      prefs.setBool(
          'checkTranslatePage' + widget.storybookID + widget.languageCode,
          false);//this flow ensure it only run 1 time
    }
    return pageData;
  }
}
