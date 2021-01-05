import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mmsr/View/createStory/selectGenre.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mmsr/View/translator/translatePageList.dart';

class TranslateInfo extends StatefulWidget {
  final String newStoryID;
  final String genreValue;
  final String fromLanguage;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  final String passImage;

  TranslateInfo(
      {Key key,
      this.genreValue,
      this.languageValue,
      this.titlePassText,
      this.descPassText,
      this.newStoryID,
      this.fromLanguage,
      this.passStorybookID,
      this.passImage})
      : super(key: key);

  @override
  _TranslateInfoState createState() => new _TranslateInfoState();
}

class _TranslateInfoState extends State<TranslateInfo> {
  String titleText = "Type your story title here";
  final _titleController = TextEditingController();
  String descriptionText = "Describe your book";
  final _descriptionController = TextEditingController();
  final _genreController = TextEditingController();
  String genreText = "Select the genre of your story";
  bool genreCheck = false;
  final _languageController = TextEditingController();
  String languageText = "Select the language of your story";
  bool languageCheck = false;
  String passLanguage; //useless (may remove)
  final int descriptionRemaining = 250;//max description length
  String passLanguageDesc;

  @override
  void initState() {
    //translate();
    //initialize all field
    _titleController.text = widget.titlePassText;
    _descriptionController.text = widget.descPassText;
    _genreController.text = widget.genreValue;
    _languageController.text = widget.languageValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Edit Story Info'),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
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
              onPressed: () {//no field allow to be empty before proceeding
                if (_titleController.text.isEmpty == true ||
                    _genreController.text.isEmpty == true ||
                    _languageController.text.isEmpty == true ||
                    _descriptionController.text.isEmpty == true) {
                  _showDialog();//show warning dialog
                  return null;
                } else {
                  Navigator.push(//proceed to next page (cover)
                      context,
                      MaterialPageRoute(
                          builder: (context) => TranslateCoverImage(
                                fromLanguage: widget.fromLanguage,
                                descPassText: _descriptionController.text,
                                genreValue: _genreController.text,
                                languageValue: widget.languageValue,
                                passStorybookID: widget.passStorybookID,
                                titlePassText: _titleController.text,
                                newStoryID: widget.newStoryID,
                                passImage: widget.passImage,
                              )));
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
                  subtitle: new TextField(//title text field
                    //cursor setting
                    cursorColor: Colors.blue,
                    cursorRadius: Radius.circular(8.0),
                    cursorWidth: 8.0,
                    //
                    controller: _titleController,//capture text in the field
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
                  subtitle: new TextField(//description text field
                    //cursor setting
                    cursorColor: Colors.blue,
                    cursorRadius: Radius.circular(8.0),
                    cursorWidth: 8.0,
                    //
                    maxLength: descriptionRemaining,//max length of description
                    controller: _descriptionController,//capture text in the field
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
                  subtitle: new TextField(//display the genre
                    //cursor setting
                    cursorColor: Colors.blue,
                    cursorRadius: Radius.circular(8.0),
                    cursorWidth: 8.0,
                    //
                    style: new TextStyle(color: Colors.grey),
                    controller: _genreController,//capture text in the field
                    enabled: false,//now allow to type
                    decoration: new InputDecoration(
                      hintText: genreText,
                      border: InputBorder.none,
                    ),
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    navigateToGenre(context);//go to pick genre (new screen)
                  },
                ),
                new Container(
                  padding: EdgeInsets.all(1.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          top: new BorderSide(
                              width: 1.0, color: Colors.black26))),
                ),
                
                // ListTile(
                //   title: Text('Language', style: new TextStyle(fontSize: 20.0)),
                //   contentPadding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
                //   subtitle: new TextField(
                // cursorColor: Colors.blue,
                //     cursorRadius: Radius.circular(8.0),
                //     cursorWidth: 8.0,
                //     style: new TextStyle(color: Colors.grey),
                //     controller: _languageController,
                //     enabled: false,
                //     decoration: new InputDecoration(
                //       hintText: languageText,
                //       border: InputBorder.none,
                //     ),
                //   ),
                //   trailing: Icon(Icons.keyboard_arrow_right),
                //   onTap: () {
                //     navigateToLanguage(context);
                //   },
                // ),
                // new Container(
                //   padding: EdgeInsets.all(1.0),
                //   decoration: new BoxDecoration(
                //       border: new Border(
                //           top: new BorderSide(
                //               width: 1.0, color: Colors.black26))),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future navigateToGenre(context) async {//function proceed to pick genre
    _genreController.text = await Navigator.push(
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

  // Future navigateToLanguage(context) async {
  //   _languageController.text = await Navigator.push(
  //       context, MaterialPageRoute(builder: (context) => LanguageLoad()));
  //   languageCheck = true;
  //   if (languageText == null) {
  //     languageText = "Select the language of your story";
  //     languageCheck = false;
  //   }
  // }

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
//storybook cover (in translate section, cover only for viewing but not edit)
class TranslateCoverImage extends StatefulWidget {
  final String newStoryID;
  final String genreValue;
  final String fromLanguage;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  final String passImage;

  TranslateCoverImage(
      {Key key,
      this.titlePassText,
      this.genreValue,
      this.languageValue,
      this.descPassText,
      // this.passImage,
      this.passStorybookID,
      this.newStoryID,
      this.fromLanguage,
      this.passImage})
      : super(key: key);

  @override
  _TranslateCoverImageState createState() => new _TranslateCoverImageState();
}

class _TranslateCoverImageState extends State<TranslateCoverImage> {
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
    //getPage();
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
                //convert cover from File to base64 (String) and store in passImage
                if (galleryFile != null) {
                  passImage = base64Encode(galleryFile.readAsBytesSync());
                } else if (cameraFile != null) {
                  passImage = base64Encode(cameraFile.readAsBytesSync());
                } else {
                  passImage = widget.passImage;
                }

                Navigator.push(//proceed to next page(translated story list)
                    context,
                    MaterialPageRoute(
                        builder: (context) => TranslatePageListLoad(
                              fromLanguage: widget.fromLanguage,
                              descPassText: widget.descPassText,
                              genreValue: widget.genreValue,
                              languageValue: widget.languageValue,
                              passStorybookID: widget.passStorybookID,
                              titlePassText: widget.titlePassText,
                              newStoryID: widget.newStoryID,
                              passImage: passImage,
                            )));
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
      floatingActionButton: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          //disable floating action button
          // FloatingActionButton.extended(
          //   elevation: 5.0,
          //   heroTag: "buttonGallery",
          //   onPressed: imageSelectorGallery,
          //   tooltip: "Pick image",
          //   icon: Icon(Icons.wallpaper),
          //   label: Text("Gallery"),
          // ),
          // FloatingActionButton.extended(
          //   elevation: 5.0,
          //   heroTag: "buttonCamera",
          //   onPressed: imageSelectorCamera,
          //   tooltip: "Pick image",
          //   icon: Icon(Icons.add_a_photo),
          //   label: Text("Camera"),
          // ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void imageSelectorGallery() async {//useless at this screen
    var result;
    File croppedFile;

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
  }

  void imageSelectorCamera() async {//useless at this screen
    var result;
    File croppedFile;

    cameraFile = await ImagePicker.pickImage(
      source: ImageSource.camera,
    );

    try {
      croppedFile = await ImageCropper.cropImage(
        sourcePath: cameraFile.path,
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

  Widget displaySelectedFile(File file) {//function to display storybook cover
    Uint8List bytes = base64.decode(widget.passImage);
    return new Container(
      alignment: Alignment.center,
      //display size (not actual image size)
      height: 450.0,
      width: 550.0,
      child: file == null || cancel == true
          ? new Image(
              image: new MemoryImage(bytes),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              height: 420.0,
              width: 550.0,
            )
          : new Image.file(//probably only run this, the above statement might never run unless this screen allow user to modify cover
              file,
              height: 420.0,
              width: 550.0,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ), //no image selected
    );
  }
}
