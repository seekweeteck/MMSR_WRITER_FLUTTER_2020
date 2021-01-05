import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:mmsr/utils/navigator.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:mmsr/Model/storybook.dart';
import 'package:mmsr/Model/page.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:progress_dialog/progress_dialog.dart';

class EditListLoad extends StatefulWidget {
  final String genreValue;
  final String readabilityLevel;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  final String passImage;

  @override
  EditListLoad({
    Key key,
    this.genreValue,
    this.readabilityLevel,
    this.languageValue,
    this.titlePassText,
    this.descPassText,
    this.passStorybookID,
    this.passImage,
  }) : super(key: key);
  _EditListLoadState createState() => new _EditListLoadState();
}
//load the page data info before entering the screen
class _EditListLoadState extends State<EditListLoad> {
  Future<List<Page>> pages;
  var db;

  @override
  void initState() {
    super.initState();
    db = DBHelper();
    pages = db.getPage(widget.passStorybookID, widget.languageValue);//get page data from local storage
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new FutureBuilder<List>(
        future: pages,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? new EditList(//story list
                  data: snapshot.data,
                  titlePassText: widget.titlePassText,
                  descPassText: widget.descPassText,
                  genreValue: widget.genreValue,
                  languageValue: widget.languageValue,
                  readabilityLevel: widget.readabilityLevel,
                  passImage: widget.passImage,
                  passStorybookID: widget.passStorybookID,
                )
              : new Center(
                  child: new CircularProgressIndicator(), //loading indicator
                );
        },
      ),
    );
  }
}

class EditList extends StatefulWidget {
  final List data;
  final String genreValue;
  final String languageValue;
  final String readabilityLevel;
  final String titlePassText;
  final String descPassText;
  final String passStorybookID;
  final String passImage;

  EditList({
    Key key,
    this.titlePassText,
    this.genreValue,
    this.languageValue,
    this.readabilityLevel,
    this.descPassText,
    this.passImage,
    this.passStorybookID,
    this.data,
  }) : super(key: key);
  @override
  _EditListState createState() => new _EditListState();
}

class _EditListState extends State<EditList> {
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  File galleryFile;
  File cameraFile;
  String contentText = "Type your story";
  final _contentController = TextEditingController();

  final int contentRemaining = 100;

  List<String> _pageContent = [];
  List<String> _pageImage = [];

  String base64Image;
  String content = "";

  final String pageIDAlphabet = "P";
  int pageIDNumber = 10001;
  String pageID = "";
  int lastPageNo = 99999;

  final String storybookIDAlphabet = "S";
  static int storybookIDNumber = 10001; //useless
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

  bool solveEmpty = false;
  bool cancel;

  ProgressDialog pr;//progress dialog

  var editInfo;

  bool unableEdit; //to limit story with translated version cannot add new page

  void _addPageContent(String content) {
    if (content.length > 0) {//if page content not empty, add into _pageContent list
      setState(() => _pageContent.add(content));
    }
  }

  void _addPageImage(String path) async {
    if (path != null) {
      setState(() => _pageImage.add(//if page image not empty, add into _pageImage list
            (path),
          ));

      _insertImage.add(path);
      //clear state of image
      galleryFile = null;
      cameraFile = null;
    } else {
      //default empty image
      base64Image =
          "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";
      _insertImage.add(base64Image); //add default empty image into the list (this list is use when inserting to server)
      setState(() => _pageImage.add(""));//leave a space in the list to indicate it is the empty image
    }
  }

  Future limitFunction() async {//story with translated version cannot add new page
    try {
      final editResponse = await http
          .post("http://i2hub.tarc.edu.my:8887/mmsr/limitEdit.php", body: {
        "storybookID": widget.passStorybookID,
      });

      editInfo = json.decode(editResponse.body);

      if (editInfo.length > 1) { 
        //this means same storybook ID appears more than 1
        //we use storybookID and languageCode as PK
        //translated book will have same storybook ID but different language Code
        //this if statement means this is a translated book
        unableEdit = true;
      } else {
        unableEdit = false;
      }
    } on SocketException {
      print("Connection error");
    }
  }

  @override
  void initState() {
    limitFunction();
    db = DBHelper();
    for (int i = 0; i < widget.data.length; i++) {
      //initialize all the list from previously
      _insertPageID.add(widget.data[i].pageID);
      _pageContent.add(widget.data[i].pageContent);

      _pageImage.add(widget.data[i].pagePhoto);
      _insertImage.add(_pageImage[i]);
    }

    super.initState();
  }

  Widget _buildPageList() {
    return new Column ( 
      children: <Widget> [
      ListView.builder(
      shrinkWrap: true,
      itemCount: widget.data == null ? 0 : _pageContent.length,
      itemBuilder: (context, index) {
        if (index < widget.data.length) {
          try {//the entire try statement should be useless (may remove?, include the if else statement inside)
            if (widget.data[index].pagePhoto.length == 0) { 
              bytes = base64.decode(widget.data[index].pagePhoto + "==");
            } else if (widget.data[index].pagePhoto.toString() == '' ||
                widget.data[index].pagePhoto.length == 57308) {
              bytes = base64.decode(widget.data[index].pagePhoto);
              solveEmpty = true;
            } else {
              bytes = base64.decode(widget.data[index].pagePhoto);
            }
          } on FormatException {
            print("Format Exception");
            solveEmpty = true;
          }

          if ((galleryFile != null || cameraFile != null) &&
              index == currentIndex) {//this statement is to decode the image from base64 to Uint8List
            bytes = base64.decode(encodeImage);
          }
        }

        return new GestureDetector(
          onTap: () {
            tempPageNo = (index + 1);
            tempPageContent = _pageContent[index];
            currentIndex = index;
            // unableEdit == true
            //     ? _limitedTranslateEditScren(index)
            //     :
            _editStoryContentScreen(index);//tap on each page then go edit page content
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
                    //this statement means the page that user created last time
                    (index < widget.data.length) &&
                            checkUpdate == false &&
                            solveEmpty == false //solve empty may be useless?
                        ? Image(//image last time pick by the user
                            image: new MemoryImage(bytes),
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                            width: 80.0,
                          )
                        : _pageImage[index] == ""//if the page without page image then display empty image
                            ? new Image.asset(
                                "assets/img/empty_image.png",
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
                              )
                            : Image(//new image from the new page
                                image: new MemoryImage(
                                  base64.decode(_pageImage[index]),
                                ),
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
                                width: 80.0,
                              )
                  ],
                ),
                title: new Text("Page ${index + 1}"),
                subtitle: new Text(_pageContent[index]),
              ),
              secondaryActions: <Widget>[//slide to delete page
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
    ),
    SizedBox(
      height:10,
    ),
    Container(
      child: Text ('To Delete, swipe to the left',
      style: TextStyle(color: Colors.red, fontSize:16),),
    ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.titlePassText,
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
                if (_pageContent.length == 0) {//no page has been created
                  _showDialog();//warning dialog
                  return null;
                } else {
                  _save();//saving, here might be some error, this function already inside _showSaveSucess(), extra function?
                  confirmSave();//confirm to save dialog
                }
              }),
          IconButton(//publish
              icon: new Icon(Icons.publish),
              tooltip: "Publish",
              onPressed: () {
                if (_pageContent.length == 0) {//no page has been created
                  _showDialog();//warning dialog
                  return null;
                } else {
                  _publish();//publishing, here might be some error, this function already place inside _showPublishSuccess()
                  confirmPublish();//confirm to publish dialog
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
        child: _buildPageList(), 
      ),

     
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          if (unableEdit == true) {//if the story is translated version
            setState(() {
              _scaffoldKey.currentState.showSnackBar(
                new SnackBar(
                  content: new Text(
                    'Story translation cannot add new page',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          } else {//if not translated version then add new page
            _pushStoryContentScreen();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _pushStoryContentScreen() {//add new page
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
                    //clear image state
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
                    if (_contentController.text.isEmpty == true) {//page content is empty
                      _showEmptyDialog();//warning dialog
                    } else {
                      //generate random page ID
                      pageID = pageIDAlphabet +
                          (min + random.nextInt(max - min)).toString();
                      //add page ID,content and image into separate list
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
            onTap: () {//tap on somewhere to dismiss keyboard
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
                  galleryFile != null && cancel != true
                      ? displaySelectedFile(galleryFile)
                      : cameraFile != null && cancel != true
                          ? displaySelectedFile(cameraFile)
                          : displaySelectedFile(null),
                  new SizedBox(
                    height: 20.0,
                  ),
                  new Row(//floating action button (gallery/camera)
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
                  ListTile(//field to type page content
                    subtitle: new TextField(
                      //cursor setting
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      keyboardType: TextInputType.text,
                      maxLength: contentRemaining, //max length of page content
                      controller: _contentController,//capture the page content in the field
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

  void _editStoryContentScreen(int index) {//if user click on the page to edit content
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
                    if (_contentController.text.isEmpty == true) {//if page content is empty
                      _showEmptyDialog();//warning dialog
                    } else {
                      //generate random page ID
                      pageID = pageIDAlphabet +
                          (min + random.nextInt(max - min)).toString();
                      _insertPageID.add(pageID);
                      content = _contentController.text;
                      if (content.length > 0) {
                        _pageContent[index] = _contentController.text;
                        if (galleryFile != null || cameraFile != null) {
                          setState(() {
                            //maybe can _insertImage[index]=encodeImage
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
                  //display page image in the screen
                  galleryFile != null
                      ? displaySelectedFile(galleryFile)//display gallery image
                      : cameraFile != null
                          ? displaySelectedFile(cameraFile)//display camera image
                          : _pageImage[index] == ''
                              ? Image.asset("assets/img/empty_image.png")//display empty default image
                              : Image(
                                  image: new MemoryImage(
                                      base64.decode(_pageImage[index])),//display new added image (previously not in the list)
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.high,
                                  width: 80.0,
                                ),
                  new SizedBox(
                    height: 20.0,
                  ),
                  new Row(//floating action button (gallery/camera)
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
                      )
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
                    subtitle: new TextField(//page content
                      //cursor setting
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      keyboardType: TextInputType.text,//keyboard type
                      maxLength: contentRemaining,//max length of page content
                      controller: _contentController,//capture page content in the field
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

  void _limitedTranslateEditScren(int index) { //This whole function useless (not apply, may remove)
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
                    if (_contentController.text.isEmpty == true) {
                      _showEmptyDialog();
                    } else {
                      pageID = pageIDAlphabet +
                          (min + random.nextInt(max - min)).toString();
                      _insertPageID.add(pageID);
                      content = _contentController.text;
                      if (content.length > 0) {
                        _pageContent[index] = _contentController.text;
                        if (galleryFile != null || cameraFile != null) {
                          setState(() {
                            _pageImage[index] = encodeImage;
                            _insertImage[index] = _pageImage[index];
                            checkUpdate = true;
                          });
                        }
                      }

                      galleryFile = null;
                      cameraFile = null;
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
                  galleryFile != null
                      ? displaySelectedFile(galleryFile)
                      : cameraFile != null
                          ? displaySelectedFile(cameraFile)
                          : _pageImage[index] == ''
                              ? Image.asset("assets/img/empty_image.png")
                              : Image(
                                  image: new MemoryImage(
                                      base64.decode(_pageImage[index])),
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.high,
                                  width: 80.0,
                                ),
                  new SizedBox(
                    height: 20.0,
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

  void imageSelectorGallery() async {//gallery
    var result;
    File croppedFile;

    galleryFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,//pick from gallery
    );

    try {
      croppedFile = await ImageCropper.cropImage(//cropped image
        sourcePath: galleryFile.path,
        //height and width of cropped image
        maxHeight: 512,
        maxWidth: 512,
      );

      result = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        croppedFile.path + "temp.jpeg",
        //quality of the cropped image, better quality larger size of image
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
    //this is to solve bug (sometime after user click on camera then cannot type page content, may be keyboard issue)
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    // FocusScopeNode currentFocus = FocusScope.of(context);
    // if (!currentFocus.hasPrimaryFocus) {
    //   currentFocus.unfocus();
    // }
    var result;
    File croppedFile;

    cameraFile = await ImagePicker.pickImage(//camera
      source: ImageSource.camera,
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
        croppedFile.path + "temp.jpeg",
        //quality of cropped image
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
          ? new Text(//default text when no image
              "Add image",
              style: TextStyle(color: Colors.grey, fontSize: 20.0),
              textAlign: TextAlign.center,
            )
          : new Image.file(//the selected image (gallery/camera)
              file,
              height: 265.0,
              width: 400.0,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
    );
  }

  void _showEmptyDialog() {//incomplete information dialog (page content cannot be empty)
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

  void _showDialog() {//incomplete information dialog (no page has been created)
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

  void confirmSave() {//confirmation to save
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
              new FlatButton(//confirm to save
                  child: new Text(
                    "Confirm",
                    style: new TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0),
                  ),
                  onPressed: () {
                    _showSaveSuccess();
                  })
            ],
          );
        });
  }

  void _showSaveSuccess() {//saving dialog
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
              ? AlertDialog(//dialog of story saved
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
                          _save();//saving operation
                          Future.delayed(Duration(seconds: 3)).then((onValue) {
                            if (pr.isShowing()) {
                              pr.hide();//dismiss progress dialog
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => NavigatorWriter()),
                                  (Route<dynamic> route) => false);
                            }
                          });
                        })
                  ],
                )
              : AlertDialog(//exception when no storbook ID
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

  void confirmPublish() {//confirmation to publish
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
              new FlatButton(//confirm to publish
                  child: new Text(
                    "Confirm",
                    style: new TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0),
                  ),
                  onPressed: () {
                    _showPublishSuccess();
                  })
            ],
          );
        });
  }

  void _showPublishSuccess() {//publishing
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal); //progress dialog
    pr.style(
      message: 'Submitting...',//message of progres dialog
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
                                      builder: (context) => NavigatorWriter()),
                                  (Route<dynamic> route) => false);
                            }
                          });
                        })
                  ],
                )
              : AlertDialog(//exception to catch if storybook id is empty
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');//get username
    //String base64PassImage = base64Encode(widget.passImage.readAsBytesSync());
    //save in server
    http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php", body: {
      //Insert storybook
      'storybookID': widget.passStorybookID,
      'storybookTitle': widget.titlePassText,
      'storybookCover': widget.passImage,
      'storybookDesc': widget.descPassText,
      'storybookGenre': widget.genreValue,
      'ReadabilityLevel': widget.readabilityLevel,
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

    db.saveStorybook(s);//save in local storage

    _insertPageNo.clear();

    for (int i = 0; i < _pageContent.length; i++) {
      //pageID insert
      // pageID = pageIDAlphabet + (min + random.nextInt(max - min)).toString();
      // _insertPageID.add(pageID);

      //pageNo
      _insertPageNo.add((i + 1).toString());

      http.post("http://i2hub.tarc.edu.my:8887/mmsr/updatePage.php", body: {
        //Insert page

        "pageID": _insertPageID[i],
        "pagePhoto": _insertImage[i],
        "pageNo": _insertPageNo[i],
        "pageContent": _pageContent[i],
        "storybookID": widget.passStorybookID,
        'languageCode': widget.languageValue,
      });
      Page p = Page(_insertPageID[i], _insertPageNo[i], _pageImage[i],
          _pageContent[i], widget.passStorybookID, widget.languageValue);
      db.updatePage(p);//update the page as it exist
      db.savePage(p);//save page (new page)
    }
    //below is to solve some deleting issue with list
    //when delete, content might mix and confuse due to some logic issue?
    //below is to solve by always deleting the last page and bring forward the remaining page
    //start from the page that user require to delete
    //
    final pageResponse = await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/pageByPageNo.php", body: {
      'storybookID': widget.passStorybookID,
      'languageCode': widget.languageValue,
    });
    allPages = json.decode(pageResponse.body);
    if (allPages.length > 0) {
      if (allPages.length != _pageContent.length) {
        await http.post(
            "http://i2hub.tarc.edu.my:8887/mmsr/deletePageByPageNo.php",
            body: {
              'storybookID': widget.passStorybookID,
              'languageCode': widget.languageValue,
              'pageNo': _insertPageNo[_pageContent.length - 1],
            });
        db.deletePageByPageNo(widget.passStorybookID, widget.languageValue,
            int.parse(_insertPageNo[_pageContent.length - 1]));
      }
    }
    //
  }

  Future _publish() async {//publishing
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');//get username
    //String base64PassImage = base64Encode(widget.passImage.readAsBytesSync());
    //publish to server
    http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php", 
    body: {
      //Insert storybook
      'storybookID': widget.passStorybookID,
      'storybookTitle': widget.titlePassText,
      'storybookCover': widget.passImage,
      'storybookDesc': widget.descPassText,
      'storybookGenre': widget.genreValue,
      'ReadabilityLevel': widget.readabilityLevel,
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

    db.saveStorybook(s);//save in local storage

    _insertPageNo.clear();

    for (int i = 0; i < _pageContent.length; i++) {
      //pageNo
      _insertPageNo.add((i + 1).toString());

      http.post("http://i2hub.tarc.edu.my:8887/mmsr/updatePage.php", body: {
        //Insert page

        "pageID": _insertPageID[i],
        "pagePhoto": _insertImage[i],
        "pageNo": _insertPageNo[i],
        "pageContent": _pageContent[i],
        "storybookID": widget.passStorybookID,
        'languageCode': widget.languageValue,
      });
      Page p = Page(_insertPageID[i], _insertPageNo[i], _pageImage[i],
          _pageContent[i], widget.passStorybookID, widget.languageValue);
      db.updatePage(p);//update page if it exist
      db.savePage(p);//save new page
    }
    //below is to solve some deleting issue with list
    //when delete, content might mix and confuse due to some logic issue?
    //below is to solve by always deleting the last page and bring forward the remaining page
    //start from the page that user require to delete
    //
    final pageResponse = await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/pageByPageNo.php", body: {
      'storybookID': widget.passStorybookID,
      'languageCode': widget.languageValue,
    });
    allPages = json.decode(pageResponse.body);
    if (allPages.length > 0) {
      if (allPages.length != _pageContent.length) {
        await http.post(
            "http://i2hub.tarc.edu.my:8887/mmsr/deletePageByPageNo.php",
            body: {
              'storybookID': widget.passStorybookID,
              'languageCode': widget.languageValue,
              'pageNo': _insertPageNo[_pageContent.length - 1],
            });
        db.deletePageByPageNo(widget.passStorybookID, widget.languageValue,
            int.parse(_insertPageNo[_pageContent.length - 1]));
      }
    }
    //
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
                onPressed: () {//remove everything
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
    db.deletePagebyPageID(localID, code);//delete local storage

    //delete in server
    await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/deleteByPageID.php", body: {
      "pageID": id,
      "languageCode": code,
    });
  }
}
