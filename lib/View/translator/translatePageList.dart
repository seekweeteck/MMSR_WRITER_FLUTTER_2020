import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mmsr/utils/navigator.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:mmsr/Model/storybook.dart';
import 'package:mmsr/Model/page.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:progress_dialog/progress_dialog.dart';

class TranslatePageListLoad extends StatefulWidget {
  final String newStoryID;
  final String genreValue;
  final String readabilityLevel;
  final String fromLanguage;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  final String passImage;

  @override
  TranslatePageListLoad({
    Key key,
    this.genreValue,
    this.readabilityLevel,
    this.languageValue,
    this.titlePassText,
    this.descPassText,
    this.passStorybookID,
    this.passImage,
    this.newStoryID,
    this.fromLanguage,
  }) : super(key: key);
  _TranslatePageListLoadState createState() =>
      new _TranslatePageListLoadState();
}
//Load page data before entering the page
class _TranslatePageListLoadState extends State<TranslatePageListLoad> {
  Future<List<Page>> pages;
  var db;

  @override
  void initState() {
    super.initState();
    db = DBHelper();
    pages = db.getPage(widget.passStorybookID, widget.fromLanguage);//get page data from local storage
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new FutureBuilder<List>(
        future: pages,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? new TranslatePageList(//after get page data then enter the page
                  data: snapshot.data,
                  titlePassText: widget.titlePassText,
                  fromLanguage: widget.fromLanguage,
                  descPassText: widget.descPassText,
                  genreValue: widget.genreValue,
                  readabilityLevel: widget.readabilityLevel,
                  languageValue: widget.languageValue,
                  passImage: widget.passImage,
                  passStorybookID: widget.passStorybookID,
                  newStoryID: widget.newStoryID,
                )
              : new Center(
                  child: new CircularProgressIndicator(),//loading indicator
                );
        },
      ),
    );
  }
}

class TranslatePageList extends StatefulWidget {
  final List data;
  final String newStoryID;
  final String genreValue;
  final String readabilityLevel;
  final String fromLanguage;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  final String passImage;

  TranslatePageList({
    Key key,
    this.titlePassText,
    this.genreValue,
    this.readabilityLevel,
    this.languageValue,
    this.descPassText,
    this.passImage,
    this.passStorybookID,
    this.data,
    this.newStoryID,
    this.fromLanguage,
  }) : super(key: key);
  @override
  _TranslatePageListState createState() => new _TranslatePageListState();
}

class _TranslatePageListState extends State<TranslatePageList> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");//date format

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  File galleryFile;
  File cameraFile;
  String contentText = "Type your story";
  final _contentController = TextEditingController();

  final int contentRemaining = 100;//max length of page content

  List<String> _pageContent = [];
  List<String> _pageImage = [];

  String base64Image;
  String content = "";

  final String pageIDAlphabet = "P";
  int pageIDNumber = 10001;
  String pageID = "";
  int lastPageNo = 99999;

  final String storybookIDAlphabet = "S";
  static int storybookIDNumber = 10001; //might useless at this screen
  String storybookID = "";

  List<String> _insertPageID = [];
  List<String> _insertPageNo = [];
  List<String> _insertImage = [];

  var random = new Random();
  int min = 00001;
  int max = 99999;

  int tempPageNo;
  String tempPageContent;
  File tempPageImage;

  String encodeImage;

  Uint8List bytes;

  int currentIndex;

  var db;

  var allPages;

  bool checkUpdate = false;

  bool solveEmpty = false;//useless, may remove
  bool cancel;

  final translator = GoogleTranslator();//google translator API
  String translation;//translation of page content (use in loop to translate a list)
  String fromLanguage;//from which language
  String toLanguage;//to which language

  ProgressDialog pr; //progress dialog

  void translate() async {
    //the language is a bit hardcoding
    //widget.fromLanguage -> from language is from the language code we define to the proper google language code
    if (widget.fromLanguage == 'EN') {
      fromLanguage = 'en';
    } else if (widget.fromLanguage == 'TA') {
      fromLanguage = 'hi';
    } else if (widget.fromLanguage == 'MS') {
      fromLanguage = 'ms';
    } else if (widget.fromLanguage == 'ZH(Sim)') {
      fromLanguage = 'zh-CN';
    } else if (widget.fromLanguage == 'ZH(Tra)') {
      fromLanguage = 'zh-TW';
    }

    //this also converting the language code to proper google language code
    if (widget.languageValue == 'EN') {
      toLanguage = 'en';
    } else if (widget.languageValue == 'TA') {
      toLanguage = 'hi';
    } else if (widget.languageValue == 'MS') {
      toLanguage = 'ms';
    } else if (widget.languageValue == 'ZH(Sim)') {
      toLanguage = 'zh-CN';
    } else if (widget.languageValue == 'ZH(Tra)') {
      toLanguage = 'zh-TW';
    }

    try {//translation process
      for (int i = 0; i < widget.data.length; i++) { //translate based on the length of page and store in _pageContent
        translation = await translator.translate(widget.data[i].pageContent,
            from: fromLanguage, to: toLanguage);
        if (this.mounted) {
          setState(() {
            _pageContent.add(translation);
          });
        }
      }
    } on SocketException {//network connection error cause fail linking to google translator API
      print("Translation fail");
    }
  }

  void _addPageContent(String content) {//might useless at this screen, translate book now allow to add new page content
    if (content.length > 0) {
      setState(() => _pageContent.add(content));
    }
  }

  void _addPageImage(String path) async {//might useless at this screen, translate book now allow to add new page image
    if (path != null) {
      setState(() => _pageImage.add(
            (path),
          ));

      _insertImage.add(path);

      galleryFile = null;
      cameraFile = null;
    } else {
      base64Image =
          "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";
      _insertImage.add(base64Image);
      setState(() => _pageImage.add(""));
    }
  }

  @override
  void initState() {
    db = DBHelper();//open database
    translate();//translate process
    for (int i = 0; i < widget.data.length; i++) {
      //store page ID, and image into a seperate list
      _insertPageID.add(widget.data[i].pageID);
      //_pageContent.add(widget.data[i].pageContent);

      _pageImage.add(widget.data[i].pagePhoto);
      _insertImage.add(_pageImage[i]);
    }

    super.initState();
  }

  Widget _buildPageList() {
    return new ListView.builder(
      itemCount: widget.data == null ? 0 : _pageContent.length,
      itemBuilder: (context, index) {
        if (index < widget.data.length) {//decode page image from base64(string) to Uint8List
          bytes = base64.decode(widget.data[index].pagePhoto);
          if ((galleryFile != null || cameraFile != null) &&
              index == currentIndex) {
            bytes = base64.decode(encodeImage);
          }
        }

        return new GestureDetector(
          onTap: () {
            tempPageNo = (index + 1);
            tempPageContent = _pageContent[index];
            currentIndex = index;
            _editStoryContentScreen(index);//edit translated page
          },
          child: new Card(
            shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(16.0),
            ),
            child: new Slidable(
              actionPane: SlidableDrawerActionPane(),
              actionExtentRatio: 0.25,
              child: new ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    (index < widget.data.length) &&
                            checkUpdate == false &&
                            solveEmpty == false //solve empty is useless variable
                        ? Image(//display page image that pre-stored
                            image: new MemoryImage(bytes),
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                            width: 80.0,
                          )
                        : _pageImage[index] == ""//display default empty image
                            ? new Image.asset(
                                "assets/img/empty_image.png",
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
                              )
                            : Image(//display image that new picked by the user
                                image: new MemoryImage(
                                  base64.decode(_pageImage[index]),
                                ),
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
                                width: 80.0,
                              )
                  ],
                ),
                title: new Text("Page ${index + 1}"),//display page number
                subtitle: new Text(_pageContent[index]),//display page content
              ),
              secondaryActions: <Widget>[//swipe to delete
                IconSlideAction(
                  caption: 'Delete',
                  color: Colors.red,
                  icon: Icons.delete,
                  onTap: () => setState(() {
                    _confirmDelete(//confirmation dialog to delete
                        ((index + 1).toString()),
                        ((_insertPageID[_pageContent.length - 1]).toString()),
                        widget.languageValue,
                        index,
                        ((_insertPageID[index]).toString()),
                        widget.passStorybookID);
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.titlePassText == null ? '' : widget.titlePassText,
          style: new TextStyle(
              fontWeight: FontWeight.bold,
              wordSpacing: 1.1,
              letterSpacing: 1.1,
              fontSize: 21.0),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(//save
              icon: new Icon(Icons.save),
              tooltip: "Save",
              onPressed: () {
                if (_pageContent.length == 0) {//cannot be 0 page
                  _showDialog();//warning dialog
                  return null;
                } else {
                  _save();//saving, might useless, this function already inside _showSaveSuccess()
                  confirmSave();//confirmation dialog to save
                }
              }),
          IconButton(//publish
              icon: new Icon(Icons.publish),
              tooltip: "Publish",
              onPressed: () {
                if (_pageContent.length == 0) {//cannot be 0 page
                  _showDialog();//warning dialog
                  return null;
                } else {
                  _publish();//publishing, might useless, this function already inside _showPublishSuccess()
                  confirmPublish();//confirmation dialog to publish
                }
              }),
        ],
      ),
      body: new Container(
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
        //when translation fail then go to _getEmpty else display the result
        child: translation == null ? _getEmpty() : _buildPageList(),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.add),
      //   onPressed: () {
      //     _pushStoryContentScreen();
      //   },
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _getEmpty() {
    return new Center(
      child: new Padding(
        padding: EdgeInsets.all(10.0),
        child: new Center(
          child: new SpinKitThreeBounce(color: Colors.blueAccent),//loading indicator
        ),
      ),
    );
  }

  void _pushStoryContentScreen() {//add new page (not apply in translation screen)
    _contentController.clear();
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    galleryFile = null;
                    cameraFile = null;
                    Navigator.pop(context);
                  },
                );
              },
            ),
            title: Text('Page ${_pageContent.length + 1}'),
            automaticallyImplyLeading: false,
            actions: <Widget>[
              FlatButton(
                  padding: EdgeInsets.fromLTRB(16.0, 16.5, 15.0, 16.0),
                  textColor: Colors.white,
                  child: new Text(
                    'Done',
                    style: new TextStyle(fontSize: 18.0),
                  ),
                  shape:
                      CircleBorder(side: BorderSide(color: Colors.transparent)),
                  onPressed: () async {
                    if (_contentController.text.isEmpty == true) {
                      _showEmptyDialog();
                    } else {
                      pageID = pageIDAlphabet +
                          (min + random.nextInt(max - min)).toString();
                      _insertPageID.add(pageID);
                      _addPageContent(_contentController.text);
                      if (galleryFile != null) {
                        _addPageImage(
                            base64Encode(galleryFile.readAsBytesSync()));
                      } else if (cameraFile != null) {
                        _addPageImage(
                            base64Encode(cameraFile.readAsBytesSync()));
                      } else {
                        _addPageImage(null);
                      }
                      content = _contentController.text;

                      Navigator.pop(context);
                    }
                  }),
            ],
          ),
          body: new GestureDetector(
            onTap: () {
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
            child: new SingleChildScrollView(
              child: new Column(
                children: <Widget>[
                  new SizedBox(
                    height: 20.0,
                  ),
                  galleryFile != null && cancel != true
                      ? displaySelectedFile(galleryFile)
                      : cameraFile != null && cancel != true
                          ? displaySelectedFile(cameraFile)
                          : displaySelectedFile(null),
                  new SizedBox(
                    height: 20.0,
                  ),
                  new Row(
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
                  new SizedBox(
                    height: 49.0,
                  ),
                  new Divider(
                    height: 1.0,
                    color: Colors.grey,
                  ),
                  ListTile(
                    subtitle: new TextField(
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      keyboardType: TextInputType.text,
                      maxLength: contentRemaining,
                      controller: _contentController,
                      decoration: new InputDecoration(
                        hintText: contentText,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  new Divider(
                    height: 20.0,
                    color: Colors.grey,
                  ),
                ],
              ),
            ), //
          ),
        );
      }),
    );
  }

  void _editStoryContentScreen(int index) {//edit translated data
    _contentController.text = tempPageContent;
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    //clear image state
                    galleryFile = null;
                    cameraFile = null;
                    Navigator.pop(context);
                  },
                );
              },
            ),
            title: Text('Page $tempPageNo'),
            automaticallyImplyLeading: false,
            actions: <Widget>[
              FlatButton(
                  padding: EdgeInsets.fromLTRB(16.0, 16.5, 15.0, 16.0),
                  textColor: Colors.white,
                  child: new Text(
                    'Done',
                    style: new TextStyle(fontSize: 18.0),
                  ),
                  shape:
                      CircleBorder(side: BorderSide(color: Colors.transparent)),
                  onPressed: () async {
                    if (_contentController.text.isEmpty == true) {//page content cannot be empty
                      _showEmptyDialog();//warning dialog
                    } else {
                      //generate a random page ID
                      pageID = pageIDAlphabet +
                          (min + random.nextInt(max - min)).toString();
                      _insertPageID.add(pageID);
                      content = _contentController.text;
                      if (content.length > 0) {
                        _pageContent[index] = _contentController.text;
                        if (galleryFile != null || cameraFile != null) {
                          setState(() {
                            //maybe can _insertImage[index]=encodeImage?
                            _pageImage[index] = encodeImage;
                            _insertImage[index] = _pageImage[index];
                            checkUpdate = true;
                          });
                        }
                      }

                      //clear image state
                      galleryFile = null;
                      cameraFile = null;
                      Navigator.pop(context);
                    }
                  }),
            ],
          ),
          body: new GestureDetector(
            onTap: () {//click on somewhere to dismiss keyboard
              FocusScopeNode currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus) {
                currentFocus.unfocus();
              }
            },
            child: new SingleChildScrollView(
              child: new Column(
                children: <Widget>[
                  new SizedBox(
                    height: 20.0,
                  ),
                  //display page image
                  galleryFile != null
                      ? displaySelectedFile(galleryFile)//image from gallery
                      : cameraFile != null
                          ? displaySelectedFile(cameraFile)//image from camera
                          : _pageImage[index] == ''//empty image
                              ? Image.asset("assets/img/empty_image.png")
                              : Image(//image previously selected by the user
                                  image: new MemoryImage(
                                      base64.decode(_pageImage[index])),
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.high,
                                  width: 80.0,
                                ),
                  new SizedBox(
                    height: 20.0,
                  ),
                  //floating action button (gallery/camera)
                  new Row(
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
                  new SizedBox(
                    height: 49.0,
                  ),
                  new Divider(
                    height: 1.0,
                    color: Colors.grey,
                  ),
                  ListTile(
                    subtitle: new TextField(//page content textfield
                      //cursor setting
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      //
                      keyboardType: TextInputType.text,//keyboard type
                      maxLength: contentRemaining,//max length of page content
                      controller: _contentController,//capture the text of the text field(page content)
                      decoration: new InputDecoration(
                        hintText: contentText,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  new Divider(
                    height: 20.0,
                    color: Colors.grey,
                  ),
                ],
              ),
            ), //
          ),
        );
      }),
    );
  }

  void imageSelectorGallery() async {//pick image from gallery
    var result;
    File croppedFile;

    galleryFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,//pick image from gallery
    );

    try {
      croppedFile = await ImageCropper.cropImage(//crop image
        sourcePath: galleryFile.path,
        //height and width of the cropped image
        maxHeight: 512,
        maxWidth: 512,
      );

      result = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        croppedFile.path,
        //quality of the cropped image, the better quality the larger image size
        quality: 88,
      );
    } on NoSuchMethodError {//cancel selection in gallery
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
          encodeImage = base64Encode(result.readAsBytesSync());
        }
      });
    }
  }

  void imageSelectorCamera() async {//camera
    //to solve bug (sometime after user click on camera and cannot type on page content, believe is keyboard dismiss issue)
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    // FocusScopeNode currentFocus = FocusScope.of(context);
    // if (!currentFocus.hasPrimaryFocus) {
    //   currentFocus.unfocus();
    // }
    var result;
    File croppedFile;

    cameraFile = await ImagePicker.pickImage(
      source: ImageSource.camera,//camera
    );

    try {
      croppedFile = await ImageCropper.cropImage(//crop image
        sourcePath: cameraFile.path,
        //height and width of cropped image
        maxHeight: 512,
        maxWidth: 512,
      );

      result = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        croppedFile.path,
        //quality of cropped image, the better quality the larger image size
        quality: 88,
      );
    } on NoSuchMethodError {//cancel action in camera
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
          encodeImage = base64Encode(result.readAsBytesSync());
        }
      });
    }
  }

  Widget displaySelectedFile(File file) {//display page image in the screen
    return new Container(
      alignment: Alignment.center,
      //display size, not the actual image size
      height: 265.0,
      width: 400.0,
      child: file == null || cancel == true
          ? new Text(//default text when no image (this part may not run in translation, as a default empty image is provided)
              "Add image",
              style: TextStyle(color: Colors.grey, fontSize: 20.0),
              textAlign: TextAlign.center,
            )
          : new Image.file(//page image
              file,
              height: 265.0,
              width: 400.0,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
    );
  }

  void _showEmptyDialog() {//dialog of incomplete information (empty page content)
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Incomplete Information"),
            content: new Text("Content cannot be empty."),
            actions: <Widget>[
              new FlatButton(
                  child: new Text(
                    "Close",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ],
          );
        });
  }

  void _showDialog() {//dialog of incomplete information (empty page)
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Incomplete Information"),
            content: new Text("No story has been created."),
            actions: <Widget>[
              new FlatButton(
                  child: new Text(
                    "Close",
                    style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ],
          );
        });
  }

  void confirmSave() {//confirmation dialog to save
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Confirm to save?"),
            content: new Text("You may edit next time."),
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
                    _showSaveSuccess();//dialog of saving
                  })
            ],
          );
        });
  }

  void _showSaveSuccess() {//dialog of saving
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal);//progress dialog
    pr.style(
      message: 'Saving...',//message of progress dialog
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
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return widget.passStorybookID != null
              ? AlertDialog(
                  title: new Text("Story saved"),
                  //content: new Text("You may edit next time."),
                  actions: <Widget>[
                    new FlatButton(
                        child: new Text(
                          "OK",
                          style: new TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () {
                          pr.show();//show progress dialog
                          _save();//save operation
                          Future.delayed(Duration(seconds: 3)).then((onValue) {
                            if (pr.isShowing()) {
                              pr.hide();//dismiss progress dialog
                              Navigator.of(context).pushAndRemoveUntil(//back to homepage
                                  MaterialPageRoute(
                                      builder: (context) => NavigatorWriter()),
                                  (Route<dynamic> route) => false);
                            }
                          });
                        })
                  ],
                )
              : AlertDialog(//exception of empty storybook ID (slightly happen)
                  title: new Text("Fail to save"),
                  content: new Text("System error, please save again."),
                  actions: <Widget>[
                    new FlatButton(
                        child: new Text(
                          "OK",
                          style: new TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        })
                  ],
                );
        });
  }

  void confirmPublish() {//confirmation dialog to publish
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Confirm to submit?"),
            content: new Text("You may still unsubmit your story after this."),
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
                    _showPublishSuccess();//dialog of publishing
                  })
            ],
          );
        });
  }

  void _showPublishSuccess() {//dialog of publishing
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal);//progress dialog
    pr.style(
      message: 'Submitting...',//message of progress dialog
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
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return widget.passStorybookID != null
              ? AlertDialog(
                  title: new Text("Story submitted"),
                  content: new Text("Approval process may take few days."),
                  actions: <Widget>[
                    new FlatButton(
                        child: new Text(
                          "OK",
                          style: new TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () {
                          pr.show();//show progress dialog
                          _publish();//publish operation
                          Future.delayed(Duration(seconds: 3)).then((onValue) {
                            if (pr.isShowing()) {
                              pr.hide();//dismiss progress dialog
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => NavigatorWriter()),//back to homepage
                                  (Route<dynamic> route) => false);
                            }
                          });
                        })
                  ],
                )
              : AlertDialog(//exception that empty storybook ID (slightly happen)
                  title: new Text("Fail to submit"),
                  content: new Text("System error, please re-submit."),
                  actions: <Widget>[
                    new FlatButton(
                        child: new Text(
                          "OK",
                          style: new TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        })
                  ],
                );
        });
  }

  Future _save() async {//save operation
    // bool duplicateStoryCheck = false;

    // String tempStorybookTitle;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');//get username

    //if (allStorybook.length != 0) {
    //Storybook gt data
    // for (int i = 0; i < allStorybook.length; i++) {
    // tempStorybookTitle = allStorybook[i]['storybookTitle'];

    // if (tempStorybookTitle == widget.titlePassText &&
    //     duplicateStoryCheck == false) {
    //saving the storybook to server
    http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php", body: {
      //Insert storybook
      'storybookID': widget.passStorybookID,
      'storybookTitle': widget.titlePassText,
      'storybookCover': widget.passImage,
      'storybookDesc': widget.descPassText,
      'storybookGenre': widget.genreValue,
      'readabilityLevel': widget.readabilityLevel,
      'status': "In Progress",//book status
      'ContributorID': username,
      'rating': (0.0)
          .toString(), //initialize rating
      'languageCode': widget.languageValue,
    });

    Storybook s = Storybook(
        widget.passStorybookID,
        widget.titlePassText,
        widget.passImage,
        widget.descPassText,
        widget.genreValue,
        widget.readabilityLevel,
        "In Progress",
        dateFormat.format(DateTime.now()),
        username,
        widget.languageValue);

    db.saveStorybook(s);//saving in local storage
    // duplicateStoryCheck = true;
    // }
    // else if (tempStorybookTitle != widget.titlePassText &&
    //     duplicateStoryCheck == false) {
    //   http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //       body: {
    //         //Insert storybook
    //         'storybookID': widget.passStorybookID,
    //         'storybookTitle': widget.titlePassText,
    //         'storybookCover': widget.passImage,
    //         'storybookDesc': widget.descPassText,
    //         'storybookGenre': widget.genreValue,
    //         'status': "In Progress",
    //         'ContributorID': username,
    //         'rating': (0.0).toString(),
    //         'languageCode': widget.languageValue,
    //       });
    //   Storybook s = Storybook(
    //       widget.passStorybookID,
    //       widget.titlePassText,
    //       widget.passImage,
    //       widget.descPassText,
    //       widget.genreValue,
    //       "In Progress",
    //       dateFormat.format(DateTime.now()),
    //       username,
    //       widget.languageValue);

    //   db.saveStorybook(s);
    //   duplicateStoryCheck = true;
    // }
    // }
    // }
    // else {
    //   //1st Storybook Data
    //   http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //       body: {
    //         //Insert storybook
    //         'storybookID': widget.passStorybookID,
    //         'storybookTitle': widget.titlePassText,
    //         'storybookCover': widget.passImage,
    //         'storybookDesc': widget.descPassText,
    //         'storybookGenre': widget.genreValue,
    //         'status': "In Progress",
    //         'ContributorID': username,
    //         'rating': (0.0).toString(),
    //         'languageCode': widget.languageValue,
    //       });
    // }
    // Storybook s = Storybook(
    //     widget.passStorybookID,
    //     widget.titlePassText,
    //     widget.passImage,
    //     widget.descPassText,
    //     widget.genreValue,
    //     "In Progress",
    //     dateFormat.format(DateTime.now()),
    //     username,
    //     widget.languageValue);

    // db.saveStorybook(s);
    // duplicateStoryCheck = true;

    _insertPageNo.clear();
    for (int i = 0; i < _pageContent.length; i++) {
      //pageID insert
      pageID = pageIDAlphabet + (min + random.nextInt(max - min)).toString();
      _insertPageID.add(pageID);
      //pageNo
      _insertPageNo.add((i + 1).toString());

      //insert the translated page into server
      http.post("http://i2hub.tarc.edu.my:8887/mmsr/insertTranslatePage.php",
          body: {
            //Insert page
            "pageID": _insertPageID[i],
            "pagePhoto": _pageImage[i],
            "pageNo": _insertPageNo[i],
            "pageContent": _pageContent[i],
            "storybookID": widget.passStorybookID,
            'languageCode': widget.languageValue,
          });
      Page p = Page(_insertPageID[i], _insertPageNo[i], _pageImage[i],
          _pageContent[i], widget.passStorybookID, widget.languageValue);
      db.savePage(p);//also save pages into local storage
    }
  }

  Future _publish() async {//publish operation
    // bool duplicateStoryCheck = false;

    // String tempStorybookTitle;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');//get username

    //if (allStorybook.length != 0) {
    //Storybook gt data
    // for (int i = 0; i < allStorybook.length; i++) {
    // tempStorybookTitle = allStorybook[i]['storybookTitle'];

    // if (tempStorybookTitle == widget.titlePassText &&
    //     duplicateStoryCheck == false) {
    //saving the storybook to server
    http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php", body: {
      //Insert storybook
      'storybookID': widget.passStorybookID,
      'storybookTitle': widget.titlePassText,
      'storybookCover': widget.passImage,
      'storybookDesc': widget.descPassText,
      'storybookGenre': widget.genreValue,
      'readabilityLevel': widget.readabilityLevel,
      'status': "Submitted",//book status
      'ContributorID': username,
      'rating': (0.0)
          .toString(), //initialize rating
      'languageCode': widget.languageValue,
    });

    Storybook s = Storybook(
        widget.passStorybookID,
        widget.titlePassText,
        widget.passImage,
        widget.descPassText,
        widget.genreValue,
        widget.readabilityLevel,
        "Submitted",
        dateFormat.format(DateTime.now()),
        username,
        widget.languageValue);

    db.saveStorybook(s);//also save in local storage
    //   duplicateStoryCheck = true;
    //  }
    //   else if (tempStorybookTitle != widget.titlePassText &&
    //       duplicateStoryCheck == false) {
    //     http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //         body: {
    //           //Insert storybook
    //           'storybookID': widget.passStorybookID,
    //           'storybookTitle': widget.titlePassText,
    //           'storybookCover': widget.passImage,
    //           'storybookDesc': widget.descPassText,
    //           'storybookGenre': widget.genreValue,
    //           'status': "Submitted",
    //           'ContributorID': username,
    //           'rating': (0.0).toString(),
    //           'languageCode': widget.languageValue,
    //         });
    //     Storybook s = Storybook(
    //         widget.passStorybookID,
    //         widget.titlePassText,
    //         widget.passImage,
    //         widget.descPassText,
    //         widget.genreValue,
    //         "Submitted",
    //         dateFormat.format(DateTime.now()),
    //         username,
    //         widget.languageValue);

    //     db.saveStorybook(s);
    //  //   duplicateStoryCheck = true;
    //   }
    //  }
    // }
    // else {
    //   //1st Storybook Data
    //   http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //       body: {
    //         //Insert storybook
    //         'storybookID': widget.passStorybookID,
    //         'storybookTitle': widget.titlePassText,
    //         'storybookCover': widget.passImage,
    //         'storybookDesc': widget.descPassText,
    //         'storybookGenre': widget.genreValue,
    //         'status': "Submitted",
    //         'ContributorID': username,
    //         'rating': (0.0).toString(),
    //         'languageCode': widget.languageValue,
    //       });
    // }
    // Storybook s = Storybook(
    //     widget.passStorybookID,
    //     widget.titlePassText,
    //     widget.passImage,
    //     widget.descPassText,
    //     widget.genreValue,
    //     "Submitted",
    //     dateFormat.format(DateTime.now()),
    //     username,
    //     widget.languageValue);

    // db.saveStorybook(s);
    // duplicateStoryCheck = true;

    _insertPageNo.clear();
    for (int i = 0; i < _pageContent.length; i++) {
      //pageID insert
      pageID = pageIDAlphabet + (min + random.nextInt(max - min)).toString();
      _insertPageID.add(pageID);
      //pageNo
      _insertPageNo.add((i + 1).toString());

      //insert translated page into server
      http.post("http://i2hub.tarc.edu.my:8887/mmsr/insertTranslatePage.php",
          body: {
            //Insert page
            "pageID": _insertPageID[i],
            "pagePhoto": _pageImage[i],
            "pageNo": _insertPageNo[i],
            "pageContent": _pageContent[i],
            "storybookID": widget.passStorybookID,
            'languageCode': widget.languageValue,
          });
      Page p = Page(_insertPageID[i], _insertPageNo[i], _pageImage[i],
          _pageContent[i], widget.passStorybookID, widget.languageValue);
      db.savePage(p);//also save in local storage
    }
  }

  void _confirmDelete(String title, String id, String code, int index,
      String localID, String storybookID) {//confirmation dialog to delete
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Confirm Deletion"),
            content: new Text("Delete page " + title + " ?"),
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
                  //remove all state
                  _pageContent.removeAt(index);
                  _insertImage.removeAt(index);
                  _pageImage.removeAt(index);
                  _insertPageID.removeAt(index);
                  _deletePage(id, code, localID, index, storybookID);
                  setState(() {
                    _scaffoldKey.currentState.showSnackBar(//snackbar
                      new SnackBar(
                        content: new Text(
                          'Page ' + title + ' Deleted',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    Navigator.of(context).pop(); 
                  });
                },
              ),
            ],
          );
        });
  }

  Future _deletePage(String id, String code, String localID, int index,
      String storybookID) async {//delete page operation
    db.deletePagebyPageID(localID, code);//delete page in local storage

    //delete page in server
    await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/deleteByPageID.php", body: {
      "pageID": id,
      "languageCode": code,
    });

  }
}
