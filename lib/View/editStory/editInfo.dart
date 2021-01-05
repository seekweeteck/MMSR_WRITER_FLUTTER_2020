import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mmsr/View/createStory/selectGenre.dart';
import'package:mmsr/View/createStory/difficulty.dart';
import 'package:mmsr/View/createStory/language.dart';
import 'package:mmsr/View/editStory/editList.dart';
import 'package:mmsr/Model/page.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditInfo extends StatefulWidget {
  final String genreValue;
  final String readabilityLevel;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String status;
  final String cover;
  final String id;

  EditInfo(
      {Key key,
      this.genreValue,
      this.readabilityLevel,
      this.languageValue,
      this.titlePassText,
      this.descPassText,
      this.status,
      this.cover,
      this.id})
      : super(key: key);

  @override
  _EditInfoState createState() => new _EditInfoState();
}

class _EditInfoState extends State<EditInfo> {
  String titleText = "Type your story title here";
  final _titleController = TextEditingController();
  String descriptionText = "Describe your book";
  final _descriptionController = TextEditingController();
  final _genreController = TextEditingController();
  String genreText = "Select the genre of your story";
  bool genreCheck = false;
  final _difficultController = TextEditingController();
  String difficultyText = "Select the difficulty of your story";
  bool difficultyCheck = false;
  final _languageController = TextEditingController();
  String languageText = "Select the language of your story";
  bool languageCheck = false;
  String passLanguage; //might useless
  final int descriptionRemaining = 250;
  String passLanguageDesc;

  Future _language(String text) async { //this function might be useless too
    //pass languageDesc to check languageCode
    var languageData;
    final response = await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/passLanguage.php", body: {
      'languageDesc': text,
    });
    languageData = json.decode(response.body);
    passLanguage = (languageData[0]['languageCode']).toString();
  }

  @override
  void initState() {//initialize in all the value to the field
    _titleController.text = widget.titlePassText;
    _descriptionController.text = widget.descPassText;
    _genreController.text = widget.genreValue;
    _languageController.text = widget.languageValue;
    _difficultController.text = widget.readabilityLevel;
    print(widget.languageValue);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String passLanguageCode;
    return Scaffold(
      //resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Edit Story Info'),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            );
          },
        ),
        actions: <Widget>[
          FlatButton(
              padding: EdgeInsets.fromLTRB(16.0, 16.5, 15.0, 16.0),
              textColor: Colors.white,
              child: new Text(
                'Next',
                style: new TextStyle(fontSize: 16.0),
              ),
              shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
              onPressed: () {//title,genre,language,difficulty or description cannot be empty
                if (_titleController.text.isEmpty == true ||
                    _genreController.text.isEmpty == true || 
                    _languageController.text.isEmpty == true ||
                    _difficultController.text.isEmpty == true ||
                    _descriptionController.text.isEmpty == true) {
                  _showDialog(); //show warning dialog
                  return null;
                } else {
                  _language(_languageController.text);//this function might be useless
                  //This is using language description to get language code (a bit hardcoding)
                  if (_languageController.text == 'English') {
                    passLanguageCode = 'EN';
                  } else if (_languageController.text == 'Bahasa Melayu') {
                    passLanguageCode = 'MS';
                  } else if (_languageController.text == 'தமிழ்') {
                    passLanguageCode = 'TA';
                  } else if (_languageController.text == '中文简体') {
                    passLanguageCode = 'ZH(Sim)';
                  } else if (_languageController.text == '中文繁体') {
                    passLanguageCode = 'ZH(Tra)';
                  } else {
                    passLanguageCode = null;
                  }
                  Navigator.push(//push to next page(pick storybook cover)
                    context,
                    MaterialPageRoute(
                        builder: (context) => CoverImage(
                              titlePassText: _titleController.text,
                              descPassText: _descriptionController.text,
                              genreValue: _genreController.text,
                              readabilityLevel: _difficultController.text,
                              languageValue: passLanguageCode,
                              cover: widget.cover,
                              id: widget.id,
                            )),
                  );
                }
              }),
        ],
      ),
      body: new SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                  title: Text('Title',
                      style: new TextStyle(fontSize: 20.0, color: Colors.blue)),
                  subtitle: new TextField(
                    //cursor setting
                    cursorColor: Colors.blue,
                    cursorRadius: Radius.circular(8.0),
                    cursorWidth: 8.0,
                    //
                    controller: _titleController,//capture title textfield
                    decoration: new InputDecoration(
                      hintText: titleText,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                new Container(
                  padding: EdgeInsets.all(1.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          top: new BorderSide(
                              width: 1.0, color: Colors.black26))),
                ),
                ListTile(
                  contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                  title: Text('Description',
                      style: new TextStyle(fontSize: 20.0, color: Colors.blue)),
                  subtitle: new TextField(
                    //cursor setting
                    cursorColor: Colors.blue,
                    cursorRadius: Radius.circular(8.0),
                    cursorWidth: 8.0,
                    maxLength: descriptionRemaining,//max length of description
                    controller: _descriptionController,//capture description textfield
                    decoration: new InputDecoration(
                      hintText: descriptionText,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    maxLines: 5,
                  ),
                ),
                new Container(
                  padding: EdgeInsets.all(1.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          top: new BorderSide(
                              width: 1.0, color: Colors.black26))),
                ),
                ListTile(
                  title: Text('Genre',
                      style: new TextStyle(fontSize: 20.0, color: Colors.blue)),
                  contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                  subtitle: new TextField(
                    //cursor setting
                    cursorColor: Colors.blue,
                    cursorRadius: Radius.circular(8.0),
                    cursorWidth: 8.0,
                    style: new TextStyle(color: Colors.grey),
                    controller: _genreController,//capture genre field
                    enabled: false,
                    decoration: new InputDecoration(
                      hintText: genreText,
                      border: InputBorder.none,
                    ),
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    navigateToGenre(context);//go to pick genre
                  },
                ),
                new Container(
                  padding: EdgeInsets.all(1.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          top: new BorderSide(
                              width: 1.0, color: Colors.black26))),
                ),
                ListTile(
                  title: Text('Difficulty',
                      style: new TextStyle(fontSize: 20.0, color: Colors.blue)),
                  contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                  subtitle: new TextField(
                    //cursor setting
                    cursorColor: Colors.blue,
                    cursorRadius: Radius.circular(8.0),
                    cursorWidth: 8.0,
                    style: new TextStyle(color: Colors.grey),
                    controller: _difficultController,//capture difficulty field
                    enabled: false,
                    decoration: new InputDecoration(
                      hintText: difficultyText,
                      border: InputBorder.none,
                    ),
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                   
                    navigateToDifficulty(context);//go to pick difficulty
                  },
                ),
                new Container(
                  padding: EdgeInsets.all(1.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          top: new BorderSide(
                              width: 1.0, color: Colors.black26))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future navigateToGenre(context) async {//function go to genre page
    _genreController.text = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectGenre(//Genre page
                //newText: genreText
                )));
    genreCheck = true;
    if (genreText == null) {
      genreText = "Select the genre of your story";
      genreCheck = false;
    }
  }

   Future navigateToDifficulty(context) async {//function go to genre page
    _difficultController.text = await Navigator.push(
       context, MaterialPageRoute(builder: (context) => SelectDifficulty()));
    difficultyCheck = true;
    if (difficultyText == null) {
      difficultyText = "Select the difficulty of your story";
      difficultyCheck = false;
    }
  }

  Future navigateToLanguage(context) async {//Function go to language page (useless at this moment)
    _languageController.text = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => LanguageLoad()));
    languageCheck = true;
    if (languageText == null) {
      languageText = "Select the language of your story";
      languageCheck = false;
    }
  }

  void _showDialog() {//Incomplete information dialog
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Incomplete Information"),
            content: new Text("Please complete the information of story book"),
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

//Storybook cover screen
class CoverImage extends StatefulWidget {
  final String genreValue;
  final String readabilityLevel;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  //final String passImage; //pass to editList.dart
  final String cover; //read image from publish.dart (storybook cover)
  final String id;

  CoverImage(
      {Key key,
      this.titlePassText,
      this.genreValue,
      this.readabilityLevel,
      this.languageValue,
      this.descPassText,
      // this.passImage,
      this.passStorybookID,
      this.cover,
      this.id})
      : super(key: key);

  @override
  _CoverImageState createState() => new _CoverImageState();
}

class _CoverImageState extends State<CoverImage> {
  File galleryFile;
  File cameraFile;
  String passImage;

  var db;

  bool checkPage;

  var pageData;

  bool cancel;

  @override
  void initState() {
    super.initState();
    db = DBHelper();//open database
    getPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Cover Image'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
              icon: Icon(
                FontAwesomeIcons.check,
                color: Colors.white,
                size: 20.0,
              ),
              tooltip: 'Continue',
              onPressed: () {
                // if (galleryFile == null && cameraFile == null) {
                //   _showBookCoverDialog();
                // } else {
                //Storybook cover cannot be null
                //If user pick from gallery/camera, it has to encode to base 64 format first
                //base 64 format is in String
                if (galleryFile != null) {
                  passImage = base64Encode(galleryFile.readAsBytesSync());
                } else if (cameraFile != null) {
                  passImage = base64Encode(cameraFile.readAsBytesSync());
                } else {
                  passImage = widget.cover;//here is the storybook cover last time the user pick
                }
                //_storybook();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditListLoad( //Story list
                            titlePassText: widget.titlePassText,
                            descPassText: widget.descPassText,
                            genreValue: widget.genreValue,
                            languageValue: widget.languageValue,
                            readabilityLevel: widget.readabilityLevel,
                            passImage: passImage,
                            passStorybookID: widget.id,
                          )),
                );
                // }
              }),
        ],
      ),
      body: new SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            //display storybook cover
            galleryFile == null
                ? displaySelectedFile(cameraFile)
                : displaySelectedFile(galleryFile),
          ],
        ),
      ),
      //floating action button (gallery/camera)
      floatingActionButton: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FloatingActionButton.extended(
            elevation: 5.0,
            heroTag: "buttonGallery",
            onPressed: imageSelectorGallery,
            tooltip: "Pick image",
            icon: Icon(Icons.wallpaper),
            label: Text("Gallery"),
          ),
          FloatingActionButton.extended(
            elevation: 5.0,
            heroTag: "buttonCamera",
            onPressed: imageSelectorCamera,
            tooltip: "Pick image",
            icon: Icon(Icons.add_a_photo),
            label: Text("Camera"),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,//location of floating action button
    );
  }

  void imageSelectorGallery() async {//pick from gallery
    var result;//final result
    File croppedFile;

    galleryFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,//pick from gallery
    );

    try {
      croppedFile = await ImageCropper.cropImage(//cropped imgage
        sourcePath: galleryFile.path,
        //define the height and width of cropped image
        maxHeight: 512,
        maxWidth: 512,
      );

      result = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        croppedFile.path + "temp.jpeg",
        //quality of the cropped image, the higher the larger size
        quality: 88,
      );
    } on NoSuchMethodError {//Cancel selection in gallery
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
  }

  void imageSelectorCamera() async {//camera
    var result;//final result
    File croppedFile;

    cameraFile = await ImagePicker.pickImage(
      source: ImageSource.camera,//camera
    );

    try {
      croppedFile = await ImageCropper.cropImage(//crop image
        sourcePath: cameraFile.path,
        //height and width of the cropped image
        maxHeight: 512,
        maxWidth: 512,
      );

      result = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        croppedFile.path + "temp.jpeg",
        //quality of the cropped image
        quality: 88,
      );
    } on NoSuchMethodError {//cancel in camera
      setState(() {
        cancel = true;
        cameraFile = null;
      });

      print("Cancel selection");
    }
    if (cameraFile != null) {
      cancel = false;
      setState(() {
        if (cancel == false) {
          cameraFile = result;
        }
      });
    }
  }

  Widget displaySelectedFile(File file) {//display storybook cover in the screen
    Uint8List bytes = base64.decode(widget.cover);//decode from base 64 (String) to Uint8List (File)
    return new Container(
      alignment: Alignment.center,
      //display size, not the actual image size
      height: 450.0,
      width: 550.0,
      child: file == null || cancel == true
          ? new Image(//this is the image last time the user pick (in case the user does not change the storybook cover)
              image: new MemoryImage(bytes),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              height: 420.0,
              width: 550.0,
            )
          : new Image.file(//this is the new storybook cover (in case user change the cover)
              file,
              height: 420.0,
              width: 550.0,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ), //no image selected
    );
  }

  Future<List> getPage() async {//this function is to retrieve page info from server to local storage
    //This is just in case when user clear the app storage, the page data store in local storage will also gone
    //So this shared preferences ensure the page data will be there
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //this is a unique sharedPreferences name for each storybook with different language
    checkPage = prefs.getBool('checkPage' + widget.id + widget.languageValue);

    if (checkPage == true || checkPage == null) {
      //run one time only
      try {
        final response = await http
            .post("http://i2hub.tarc.edu.my:8887/mmsr/getPage.php", body: {
          'storybookID': widget.id,
          'languageCode': widget.languageValue,
        });
        pageData = json.decode(response.body);
        //db.deletePage(widget.id, widget.languageValue);
        for (int i = 0; i < pageData.length; i++) {
          Page p = Page(
            pageData[i]['pageID'],
            pageData[i]['pageNo'],
            pageData[i]['pagePhoto'],
            pageData[i]['pageContent'],
            pageData[i]['storybookID'],
            pageData[i]['languageCode'],
          );
          db.savePage(p);//save page data in local storage/update page data
        }
      } on SocketException {
        print("Poor connection");
      }
    //this flow make this if statement only run for the first time (unless user clear the app storage)
      prefs.setBool('checkPage' + widget.id + widget.languageValue, false);
    }
    return pageData;
  }
}
