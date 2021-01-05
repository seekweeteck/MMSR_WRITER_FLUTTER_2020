import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mmsr/View/createStory/selectGenre.dart';
import 'package:mmsr/View/createStory/language.dart';
import'package:mmsr/View/createStory/difficulty.dart';
import 'package:mmsr/View/createStory/storyList.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class AddStoryInfo extends StatefulWidget {
  final String genreValue;
  final String languageValue;
  final String readabilityLevel;
  final String titlePassText;
  final String descPassText;
  final String readFrequencyText; //read

  AddStoryInfo(
      {Key key,
      this.genreValue,
      this.readabilityLevel,
      this.languageValue,
      this.titlePassText,
      this.descPassText,
      this.readFrequencyText})
      : super(key: key);

  @override
  _AddStoryInfoState createState() => new _AddStoryInfoState();
}

class _AddStoryInfoState extends State<AddStoryInfo> {
  String titleText = "Type your story title here";
  final _titleController = TextEditingController();
  String descriptionText = "Describe your book";
  final _descriptionController = TextEditingController();
  String genreText = "Select the genre of your story";
  bool genreCheck = false;
  String languageText = "Select the language of your story";
  bool languageCheck = false;
  String readFrequencyText = "Select the difficulty of your story"; //read
  bool frequencyCheck = false; //read
  String passLanguage;
  final int titleRemaining = 50; //max length of title
  final int descriptionRemaining = 250; //max length of description

  Future _language(String text) async {
    //pass languageDesc to check languageCode
    var languageData;
    try {
      final response = await http
          .post("http://i2hub.tarc.edu.my:8887/mmsr/passLanguage.php", body: {
        'languageDesc': text,
      });
      languageData = json.decode(response.body);
      passLanguage = (languageData[0]['languageCode']).toString();
    } on SocketException { //network connection error
      print("Poor connection");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Add Story Info'),
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
              onPressed: () {
                //title,genre,language or description or difficulty cannot be empty
                if (_titleController.text.isEmpty == true ||
                    genreCheck == false || frequencyCheck == false ||
                    languageCheck == false ||
                    _descriptionController.text.isEmpty == true) {
                  _showDialog(); //alert dialog (information not complete)
                  return null;
                } else { //click 'Next' to next page (pick cover image)
                  _language(languageText);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoverImage(
                        titlePassText: _titleController.text,
                        descPassText: _descriptionController.text,
                        genreValue: genreText,
                        readabilityLevel: readFrequencyText,
                        languageValue: passLanguage,
                      ),
                    ),
                  );
                }
              }),
        ],
      ),
      body: new GestureDetector(
        onTap: () {//Dismiss keyboard when clicking on somewhere
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: new SingleChildScrollView(
          child: new Column(
            children: <Widget>[
              ListView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: <Widget>[
                  ListTile(
                    contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                    title: Text('Title',
                        style:
                            new TextStyle(fontSize: 20.0, color: Colors.blue)),
                    subtitle: new TextField(
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      maxLength: titleRemaining,
                      controller: _titleController, //capture the text of the title field
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
                        style:
                            new TextStyle(fontSize: 20.0, color: Colors.blue)),
                    subtitle: new TextField(
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      maxLength: descriptionRemaining,
                      controller: _descriptionController, //capture the text of the description field
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
                        style:
                            new TextStyle(fontSize: 20.0, color: Colors.blue)),
                    contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                    subtitle: new TextField(
                      enabled: false,
                      decoration: new InputDecoration(
                        hintText: genreText, //display the genre
                        border: InputBorder.none,
                      ),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      navigateToGenre(context); //go to another page to select genre
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
                    title: Text('Language',
                        style:
                            new TextStyle(fontSize: 20.0, color: Colors.blue)),
                    contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                    subtitle: new TextField(
                      enabled: false,
                      decoration: new InputDecoration(
                        hintText: languageText,//display the language
                        border: InputBorder.none,
                      ),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      navigateToLanguage(context);//go to another page to select language
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
                        style:
                            new TextStyle(fontSize: 20.0, color: Colors.blue)),
                    contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                    subtitle: new TextField(
                      enabled: false,
                      decoration: new InputDecoration(
                        hintText: readFrequencyText, //display the frequency text
                        border: InputBorder.none,
                      ),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      navigateToDifficulty(context); //go to another page to select reading frequency --> change 
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
          ), //column
        ),
      ),
    );
  }

  Future navigateToGenre(context) async {
    genreText = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectGenre(//genre page
                //newText: genreText
                )));
    genreCheck = true;
    if (genreText == null) {
      genreText = "Select the genre of your story";
      genreCheck = false;
    }
  }

  //Select difficulty navigation
  Future navigateToDifficulty(context) async {
    readFrequencyText = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectDifficulty(//difficulty page
                )));
    frequencyCheck = true;
    if (readFrequencyText == null) {
      readFrequencyText = "Select the difficulty of your story";
      frequencyCheck = false;
    }
  }

  Future navigateToLanguage(context) async {
    languageText = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => LanguageLoad()));//language page
    languageCheck = true;
    if (languageText == null) {
      languageText = "Select the language of your story";
      languageCheck = false;
    }
  }

  void _showDialog() {//incomplete information dialog
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
//cover image page
class CoverImage extends StatefulWidget {
  final String genreValue;
  final String readabilityLevel;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  final File passImage;

  CoverImage(
      {Key key,
      this.titlePassText,
      this.genreValue,
      this.readabilityLevel,
      this.languageValue,
      this.descPassText,
      this.passImage,
      this.passStorybookID})
      : super(key: key);

  @override
  _CoverImageState createState() => new _CoverImageState();
}

class _CoverImageState extends State<CoverImage> {
  File galleryFile;//image from gallery
  File cameraFile;//image from camera
  File passImage;
  var random = new Random();//random value for some exception case
  final String storybookIDAlphabet = "S";//Alphabet of the storybook ID, Eg: S10001,S10002
  static int storybookIDNumber = 10001;  //useless
  String storybookID = "";
  int min = 00001;//random min
  int max = 99999;//random max

  bool cancel;

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
              onPressed: () {//next page
                if (galleryFile == null && cameraFile == null) { //ensure storybook cover cannot be empty
                  _showBookCoverDialog();
                } else {//store the image into passImage variable
                  if (galleryFile != null) {
                    passImage = galleryFile;
                  } else if (cameraFile != null) {
                    passImage = cameraFile;
                  } else {
                    passImage = null;
                  }
                 // _storybook();
                    
                  if (storybookID == null || storybookID == '') {
                    //this function run when the storybook ID is empty, slightly happen, not sure functioning or not
                    //is to ensure storybook ID cannot be empty
                    //the concept is random a storybook ID
                    storybookID = storybookIDAlphabet +
                        (min + random.nextInt(max - min)).toString();
                  }
                  Navigator.push( //go to next page (story list)
                    context,
                    MaterialPageRoute(
                        builder: (context) => StoryList(
                              titlePassText: widget.titlePassText,
                              descPassText: widget.descPassText,
                              genreValue: widget.genreValue,
                              readabilityLevel: widget.readabilityLevel,
                              languageValue: widget.languageValue,
                              passImage: passImage,
                              //passStorybookID: storybookID,
                            )),
                  );
                }
              }),
        ],
      ),
      body: new SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            //display the image selected immediately through displaySelectedFile function
            galleryFile != null && cancel == false
                ? displaySelectedFile(galleryFile)
                : cameraFile != null && cancel == false
                    ? displaySelectedFile(cameraFile)
                    : displaySelectedFile(null),
          ],
        ),
      ),
      //floating action button
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, //make floating action button in the center
    );
  }

  void imageSelectorGallery() async {
    var result;
    File croppedFile;

    try {
      galleryFile = await ImagePicker.pickImage(
        source: ImageSource.gallery, //pick image from gallery
      );

      try {//crop image
        croppedFile = await ImageCropper.cropImage(
          sourcePath: galleryFile.path,
          //define the height and width of the cropped image
          maxHeight: 512,
          maxWidth: 512,
        );


        result = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path,
          croppedFile.path + "temp.jpeg",
          quality: 88,//image quality, the higher the larger size of the image
        );
      } on NoSuchMethodError { //when user click on cancel selecting image
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
    } on PlatformException { //When user deny the permission to gallery
      print("Deny to gallery");
    }
  }

  void imageSelectorCamera() async {
    var result;
    File croppedFile;
    try {
      cameraFile = await ImagePicker.pickImage(
        source: ImageSource.camera,//camera
      );

      try {
        croppedFile = await ImageCropper.cropImage(
          sourcePath: cameraFile.path,
          //define the image height and width
          maxHeight: 512,
          maxWidth: 512,
        );

        result = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path,
          croppedFile.path + "temp.jpeg",
          //image quality
          quality: 88,
        );
      } on NoSuchMethodError {//cancel the result after entering the camera section
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
    } on PlatformException {//Deny permission to camera
      print("Deny to camera");
    }
  }

  Widget displaySelectedFile(File file) {//function to display the storybook cover
    return new Container(
      alignment: Alignment.center,
      //the height and width just for displaying purpose, not the actual height and width of the image
      height: 450.0,//height of the storybook cover to display
      width: 550.0,//width of the storybook cover to display
      child: file == null || cancel == true
          ? new Text(
              "Add image",//default text when no image selected
              style: TextStyle(color: Colors.grey, fontSize: 20.0),
              textAlign: TextAlign.center,
            )
          : new Image.file( //the image selected, either in gallery/camera
              file,
              height: 450.0,
              width: 550.0,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
    );
  }

  void _showBookCoverDialog() {//when not picking storybook cover and click on next page, a dialog will show
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Incomplete Information"),
            content: new Text("Please select an image for book cover"),
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

  // Future _storybook() async {
  //   var storybookIDCheck;
  //   try {
  //     final storybookResponse = await http.post(
  //         "http://i2hub.tarc.edu.my:8887/mmsr/checkStorybookID.php"); //Read last storybook ID
  //     storybookIDCheck = json.decode(storybookResponse.body); //1 data only
  //   } on SocketException {
  //     print("Poor connection");
  //   }

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
}
