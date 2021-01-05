import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart';
import 'dart:math';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:mmsr/utils/navigator.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:mmsr/Model/storybook.dart';
import 'package:mmsr/Model/page.dart';
import 'package:mmsr/Controller/db.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:progress_dialog/progress_dialog.dart';

class StoryList extends StatefulWidget {
  final String genreValue;
  final String readabilityLevel;
  final String languageValue;
  final String titlePassText;
  final String descPassText;
  //final String passStorybookID;
  final File passImage;

  StoryList({
    Key key,
    this.titlePassText,
    this.genreValue,
    this.readabilityLevel,
    this.languageValue,
    this.descPassText,
    this.passImage,
    //this.passStorybookID,
  }) : super(key: key);
  @override
  _StoryListState createState() => new _StoryListState();
}

class _StoryListState extends State<StoryList> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  File galleryFile;
  File cameraFile;
  String contentText = "Type your story";
  final _contentController = TextEditingController();

  final int contentRemaining = 100; //max length of page content

  List<String> _pageContent = [];
  List<String> _pageImage = [];

  String base64Image;
  String content = "";

  final String pageIDAlphabet = "P"; //alphabet of page ID,Eg: P10001
  int pageIDNumber = 10001;//initial digit of page ID
  String pageID = "";
  int lastPageNo = 99999; //max page number

  final String storybookIDAlphabet = "S";//alphabet of storybook ID,Eg: S10001
  static int storybookIDNumber = 10001;//initial digit of storybook ID
  static String storybookID = "";

  List<String> _insertPageID = [];
  List<String> _insertPageNo = [];
  List<String> _insertImage = [];

  var random = new Random();//random value (for page ID)
  int min = 00001;//random min
  int max = 99999;//random max

  int tempPageNo;
  String tempPageContent;
  File tempPageImage;

  String encodeImage;

  Uint8List bytes;

  var allPages;
  var deletePages;

  bool cancel;

  ProgressDialog pr; //progress dialog

  var db;

  DateFormat dateFormat = DateFormat("yyyy-MM-dd");//date format

  @override
  void initState() {
    db = DBHelper();//open local database
    super.initState();
  }

  void _addPageContent(String content) {
    if (content.length > 0) {//every page content which is not empty will be added into a list (_pageContent)
      setState(() => _pageContent.add(content));
    }
  }

  void _addPageImage(String path) async {
    if (path != null) {
      setState(() => _pageImage.add(//every page image which is not empty will be added into a list (_pageImage)
            (path),
          ));

      _insertImage.add(path);
//after that, clear the gallery and camera file, this action is to clear the state
      galleryFile = null;
      cameraFile = null;
    } else {//if user no pick image from gallery/camera, insert a default image into (_pageImage)
      //this is the default empty image
      base64Image =
          "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";
      _insertImage.add(base64Image);
      setState(() => _pageImage.add(""));
    }
  }

  Future _storybook() async {//function to generate storybook ID
    var storybookIDCheck;
    try {
      final storybookResponse = await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/checkStorybookID.php"); //Read last storybook ID
      storybookIDCheck = json.decode(storybookResponse.body); //1 data only
    } on SocketException {
      print("Poor connection");
    }

    //Initialize storybookID
    if (storybookIDCheck.length == 0) {
      setState(() {
        storybookID =
            storybookIDAlphabet + (storybookIDNumber.toString()); //S10001
      });
    } else {//Add digit of storybook ID
      setState(() {
        int storybookTempNo = int.parse(storybookIDCheck[0]['storybookID']
            .substring(storybookIDCheck[0]['storybookID'].length - 5));//the value 5 means the last 5 digits of the storybook ID

        storybookTempNo++;//add the digit of the storybook ID
        storybookID = storybookIDAlphabet + storybookTempNo.toString();//new storybook ID
       
      });
    }
  }

  Widget _buildPageList() {
    return new Column(
      children: <Widget>[
     ListView.builder(
      shrinkWrap: true,
      itemExtent: 100.0,
      itemCount: _pageContent.length,
      itemBuilder: (context, index) {
        return new GestureDetector(
          onTap: () {
            tempPageNo = (index + 1);
            tempPageContent = _pageContent[index];
            //currentIndex = index;
            _editStoryContentScreen(index);//click on the page can edit content
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
                    new Padding(
                      padding: EdgeInsets.fromLTRB(1.0, 10.0, 1.0, 1.0),
                      child: _pageImage[index] == ""//if no page image then display default empty image
                          ? new Image.asset(
                              "assets/img/empty_image.png",//default empty image
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                              width: 80.0,
                            )
                          : new Image(//else display the image selected
                              image: new MemoryImage(
                                  base64.decode(_pageImage[index])),
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                              width: 80.0,
                            ),
                    ),
                  ],
                ),
                title: new Text("Page ${index + 1}"),//page number
                subtitle: new Text(_pageContent[index]),//page content
              ),
              secondaryActions: <Widget>[//swipe the card to delete the page
                IconSlideAction(
                  caption: 'Delete',
                  color: Colors.red,
                  icon: Icons.delete,
                  onTap: () => setState(() {
                    _confirmDelete(//confirmation delete dialog
                        ((index + 1).toString()),
                        ((_insertPageID[_pageContent.length - 1]).toString()),
                        widget.languageValue,
                        index,
                        storybookID);
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
          widget.titlePassText,//title of the storybook display on the appbar
          style: new TextStyle(
              fontWeight: FontWeight.bold,
              wordSpacing: 1.1,
              letterSpacing: 1.1,
              fontSize: 21.0),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(//save for future edit
              icon: new Icon(Icons.save),
              tooltip: "Save",
              onPressed: () {
                if (_pageContent.length == 0) {//no page has been created
                  _showDialog();//warn user (cannot save without page content)
                  return null;
                } else {
                  confirmSave();//confirmation dialog to save
                }
              }),
          IconButton(//publish to server
              icon: new Icon(Icons.publish),
              tooltip: "Publish",
              onPressed: () {
                if (_pageContent.length == 0) {//no page has been created
                  _showDialog();//warn user (cannot publish without page content)
                  return null;
                } else {
                  confirmPublish();//confirmation dialog to publish
                }
              }),
        ],
      ),
      body: new Container(//background color
        decoration: new BoxDecoration(
          gradient: _pageContent.length != 0
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
        child: _pageContent.length != 0 ? _buildPageList() : _getEmpty(context),
        //if no page content then go to getEmpty()
        //else go to _buildPageList()
      ),
      floatingActionButton: FloatingActionButton(//floating action button (add)
        child: Icon(Icons.add),
        onPressed: _pushStoryContentScreen,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, //location of floating action button
    );
  }

  _getEmpty(BuildContext context) {//To show no page content yet
    return new SingleChildScrollView(
      child: Center(
        child: new Padding(
          padding: EdgeInsets.fromLTRB(1.0, 100.0, 1.0, 100.0),
          child: new Column(
            children: <Widget>[
              new Image.asset(
                "assets/img/empty_page.png",//image of telling the user no page content
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                height: MediaQuery.of(context).size.height / 1.95,
                width: MediaQuery.of(context).size.width,
              ),
              Text(
                'No content yet',
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

  void _pushStoryContentScreen() {//add new page (new screen)
    _contentController.clear();//clear text field (needed to clear state)
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {//when click on close icon(cancel), pop to previous page, also clear gallery and camera state
                    galleryFile = null;
                    cameraFile = null;
                    Navigator.pop(context);
                  },
                );
              },
            ),
            title: Text('Page ${_pageContent.length + 1}'),//+1 because length start from 0
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
                      _showEmptyDialog();//show dialog to tell user page content cannot be empty
                    } else {//page content is not empty (valid)
                      //pageID insert
                      //This part is generate page ID, I didn't apply solution to prevent collision of page ID
                      //I just increase the random max for this moment
                      pageID = pageIDAlphabet +
                          (min + random.nextInt(max - min)).toString();//random a page ID
                      _insertPageID.add(pageID);//Store page ID in a list

                      _addPageContent(_contentController.text);//Store page content in a list
                      //Store image in a list
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
            onTap: () {//tap somewhere to dismiss keyboard
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
                  //display image from gallery/camera
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
                  ListTile(
                    subtitle: new TextField(//Textfield for page content
                      //autofocus: true,
                      //cursor setting
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      //
                      keyboardType: TextInputType.text,//keyboard type
                      maxLength: contentRemaining,//length of page content
                      controller: _contentController,//capture page content
                      decoration: new InputDecoration(
                        hintText: contentText,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  new Divider(
                    height: 20.0,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  //This is edit page screen
  //Similar like above (add page), just slightly different method
  void _editStoryContentScreen(int index) {
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
                    //clear state when leaving the screen
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
                      //pageID insert
                      pageID = pageIDAlphabet +
                          (min + random.nextInt(max - min)).toString();
                      _insertPageID.add(pageID);

                      content = _contentController.text;
                      if (content.length > 0) {
                        _pageContent[index] = _contentController.text;//update the content in the list
                      }
                      if (galleryFile != null || cameraFile != null) {
                        setState(() {
                          //update the image in the list
                          //maybe can _insertImage[index]=encodeImage?
                          _pageImage[index] = encodeImage;
                          _insertImage[index] = _pageImage[index];
                        });
                      }
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
                  //here is still the edit part
                  //display image from gallery/camera (in case user pick new image from gallery/camera)
                  //or previously it has no image then display default image
                  //else display the selected page image
                  galleryFile != null
                      ? displaySelectedFile(galleryFile)
                      : cameraFile != null
                          ? displaySelectedFile(cameraFile)
                          : _pageImage[index] == ''
                              ? Image.asset("assets/img/empty_image.png")
                              : new Image(
                                  image: new MemoryImage(
                                      base64.decode(_pageImage[index])),
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
                    subtitle: new TextField(//text field of page contnet
                      //cursor setting
                      cursorColor: Colors.blue,
                      cursorRadius: Radius.circular(8.0),
                      cursorWidth: 8.0,
                      //
                      keyboardType: TextInputType.text,//keyboard type
                      maxLength: contentRemaining,//page content length
                      controller: _contentController,//capture content in the textfield 
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

  void imageSelectorGallery() async {//function to pick image from gallery
    var result;
    File croppedFile;

    galleryFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,//pick image from gallery
    );

    try {
      croppedFile = await ImageCropper.cropImage(//crop image
        sourcePath: galleryFile.path,
        //define the height and width of the cropped image
        maxHeight: 512,
        maxWidth: 512,
      );

      result = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        croppedFile.path,
        quality: 88,//quality of the cropped image (higher quality, larger size)
      );
    } on NoSuchMethodError {//cancel selection when user in gallery
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

  void imageSelectorCamera() async {//camera function
    //This is to solve some bug 
    //Sometime after user click on camera then cannot type on the textfield(page content)
    //This is a temporary solving method
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
    } on NoSuchMethodError {//cancel on camera
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

  Widget displaySelectedFile(File file) {//display the image from gallery/camera
    return new Container(
      alignment: Alignment.center,
      //The height and width is the display size, not the actual image size
      height: 265.0,
      width: 400.0,
      child: file == null || cancel == true
          ? new Text(//default text when no image
              "Add image",
              style: TextStyle(color: Colors.grey, fontSize: 20.0),
              textAlign: TextAlign.center,
            )
          : new Image.file(//The image from gallery/camera
              file,
              height: 265.0,
              width: 400.0,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
    );
  }

  void _showEmptyDialog() {//Incomplete information dialog (page content empty)
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

  void _showDialog() {//Incomplete information dialog (empty page)
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

  void confirmSave() {//Confirmation dialog to save
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
                    _storybook();//generate storybook id
                    _showSaveSuccess();//saving dialog 
                  })
            ],
          );
        });
  }

  void _showSaveSuccess() {//saving
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal);//progress dialog
    pr.style(
      message: 'Saving...',//message of the progress dialog
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
          return storybookID != null && storybookID != '' //if storybook ID is not empty then show the dialog
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
                          _save();//The save operation
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
              : AlertDialog(//Empty storybook ID then display error (slightly happen)
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

  void confirmPublish() {//Confirmation dialog to publish
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
                    _storybook();//generate storybook ID
                    _showPublishSuccess();//publishing dialog
                  })
            ],
          );
        });
  }

  void _showPublishSuccess() {//publishing dialog
    pr = new ProgressDialog(context, type: ProgressDialogType.Normal);//progress dialog
    pr.style(
      message: 'Submitting...',//progress dialog message
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
          return storybookID != null && storybookID != ''//if storybook ID is not empty then show the dialog
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
              : AlertDialog(//If storybook ID is empty (slightly happen)
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

  Future _save() async {//Save operation
    // bool duplicateStoryCheck = false;

    //String tempStorybookTitle;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');//get the username

    // var allStorybook;

    // final readStoryResponse = await http.post(
    //   "http://i2hub.tarc.edu.my:8887/mmsr/readStorybookID.php", //Select * From storybook
    // );

    // allStorybook = json.decode(readStoryResponse.body);

    String base64PassImage = base64Encode(widget.passImage.readAsBytesSync());//This is the storybook cover, encode from File to String

    // if (allStorybook.length != 0) {
    //Storybook gt data
    //for (int i = 0; i < allStorybook.length; i++) {
    // tempStorybookTitle = allStorybook[i]['storybookTitle'];

    // if (tempStorybookTitle == widget.titlePassText &&
    //     duplicateStoryCheck == false) {
    http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php", body: {
      //Insert storybook
      'storybookID': storybookID,
      'storybookTitle': widget.titlePassText,
      'storybookCover': base64PassImage,
      'storybookDesc': widget.descPassText,
      'storybookGenre': widget.genreValue,
      'ReadabilityLevel': widget.readabilityLevel,
      'status': "In Progress", //Status of the book
      'ContributorID': username,
      'rating': (0.0).toString(), //initialize value of rating
      'languageCode': widget.languageValue,
    });

    
    Storybook s = Storybook(
        storybookID,
        widget.titlePassText,
        base64PassImage,
        widget.descPassText,
        widget.genreValue,
        widget.readabilityLevel,
        "In Progress",
        dateFormat.format(DateTime.now()),
        username,
        widget.languageValue);

    db.saveStorybook(s);//This is to save in local storage

    // duplicateStoryCheck = true;
    //}
    // }
    // }
    //     else if (tempStorybookTitle != widget.titlePassText &&
    //         duplicateStoryCheck == false) {
    //       http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //           body: {
    //             //Insert storybook
    //             'storybookID': widget.passStorybookID,
    //             'storybookTitle': widget.titlePassText,
    //             'storybookCover': base64PassImage,
    //             'storybookDesc': widget.descPassText,
    //             'storybookGenre': widget.genreValue,
    //             'status': "In Progress",
    //             'ContributorID': username,
    //             'rating': (0.0).toString(),
    //             'languageCode': widget.languageValue,
    //           });
    //       Storybook s = Storybook(
    //           widget.passStorybookID,
    //           widget.titlePassText,
    //           base64PassImage,
    //           widget.descPassText,
    //           widget.genreValue,
    //           "In Progress",
    //           dateFormat.format(DateTime.now()),
    //           username,
    //           widget.languageValue);

    //       db.saveStorybook(s);
    //       duplicateStoryCheck = true;
    //     }
    //   }
    // } else {
    //   http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //       body: {
    //         //Insert storybook
    //         'storybookID': widget.passStorybookID,
    //         'storybookTitle': widget.titlePassText,
    //         'storybookCover': base64PassImage,
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
    //       base64PassImage,
    //       widget.descPassText,
    //       widget.genreValue,
    //       "In Progress",
    //       dateFormat.format(DateTime.now()),
    //       username,
    //       widget.languageValue);

    //   db.saveStorybook(s);
    // }
    // duplicateStoryCheck = true;

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
        "storybookID": storybookID,
        'languageCode': widget.languageValue,
      });

      Page p = Page(_insertPageID[i], _insertPageNo[i], _insertImage[i],
          _pageContent[i], storybookID, widget.languageValue);
      db.savePage(p);//save page in local storage
    }

    //Below is the solution to solve deleting issue (page number and content confuse and mix up,only happen when deleting page)
    //The concept of solution is like no matter what user delete, the system also delete the last page and move the content forward
    //Of course also delete what user want to delete
    //Here is some sort like a logic solution to solve the issue
    final pageResponse = await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/pageByPageNo.php", body: {
      'storybookID': storybookID,
      'languageCode': widget.languageValue,
    });
    allPages = json.decode(pageResponse.body);
    if (allPages.length > 0) {
      if (allPages.length != _pageContent.length) {
        await http.post(
            "http://i2hub.tarc.edu.my:8887/mmsr/deletePageByPageNo.php",
            body: {
              'storybookID': storybookID,
              'languageCode': widget.languageValue,
              'pageNo': _insertPageNo[_pageContent.length - 1],
            }); //Delete page in server
        db.deletePageByPageNo(storybookID, widget.languageValue,
            int.parse(_insertPageNo[_pageContent.length - 1])); //delete page in local storage
      }
    }
  }

  Future _publish() async {//publish operation
    // bool duplicateStoryCheck = false;

    //String tempStorybookTitle;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');//get username

    // var allStorybook;

    // final readStoryResponse = await http.post(
    //   "http://i2hub.tarc.edu.my:8887/mmsr/readStorybookID.php", //Select * From storybook
    // );

    // allStorybook = json.decode(readStoryResponse.body);

    String base64PassImage = base64Encode(widget.passImage.readAsBytesSync());//convert storybook cover from File to String

    //if (allStorybook.length != 0) {
    //Storybook gt data
    //  for (int i = 0; i < allStorybook.length; i++) {
    //tempStorybookTitle = allStorybook[i]['storybookTitle'];

    // if (tempStorybookTitle == widget.titlePassText &&
    //     duplicateStoryCheck == false) {
    http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php", body: {
      //Insert storybook
      'storybookID': storybookID,
      'storybookTitle': widget.titlePassText,
      'storybookCover': base64PassImage,
      'storybookDesc': widget.descPassText,
      'storybookGenre': widget.genreValue,
      'ReadabilityLevel': widget.readabilityLevel, 
      'status': "Submitted",//status of the book
      'ContributorID': username,
      'rating': (0.0)
          .toString(), //initial value of rating
      'languageCode': widget.languageValue,
    });
    Storybook s = Storybook(
        storybookID,
        widget.titlePassText,
        base64PassImage,
        widget.descPassText,
        widget.genreValue,
        widget.readabilityLevel,
        "Submitted",
        dateFormat.format(DateTime.now()),
        username,
        widget.languageValue,
       );

    db.saveStorybook(s); //No matter publish or not, save in local storage

    //   duplicateStoryCheck = true;
    // }
    // else if (tempStorybookTitle != widget.titlePassText &&
    //     duplicateStoryCheck == false) {
    //   http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //       body: {
    //         //Insert storybook
    //         'storybookID': widget.passStorybookID,
    //         'storybookTitle': widget.titlePassText,
    //         'storybookCover': base64PassImage,
    //         'storybookDesc': widget.descPassText,
    //         'storybookGenre': widget.genreValue,
    //         'status': "Submitted",
    //         'ContributorID': username,
    //         'rating': (0.0).toString(),
    //         'languageCode': widget.languageValue,
    //       });
    //   Storybook s = Storybook(
    //       widget.passStorybookID,
    //       widget.titlePassText,
    //       base64PassImage,
    //       widget.descPassText,
    //       widget.genreValue,
    //       "Submitted",
    //       dateFormat.format(DateTime.now()),
    //       username,
    //       widget.languageValue);

    //   db.saveStorybook(s);
    //   duplicateStoryCheck = true;
    // }
    // }
    //}
    // else {
    //   //1st Storybook Data
    //   http.post("http://i2hub.tarc.edu.my:8887/mmsr/updateStorybook.php",
    //       body: {
    //         //Insert storybook
    //         'storybookID': widget.passStorybookID,
    //         'storybookTitle': widget.titlePassText,
    //         'storybookCover': base64PassImage,
    //         'storybookDesc': widget.descPassText,
    //         'storybookGenre': widget.genreValue,
    //         'status': "Submitted",
    //         'ContributorID': username,
    //         'rating': (0.0).toString(),
    //         'languageCode': widget.languageValue,
    //       });
    //   Storybook s = Storybook(
    //       widget.passStorybookID,
    //       widget.titlePassText,
    //       base64PassImage,
    //       widget.descPassText,
    //       widget.genreValue,
    //       "Submitted",
    //       dateFormat.format(DateTime.now()),
    //       username,
    //       widget.languageValue);

    //   db.saveStorybook(s);
    // }
    // duplicateStoryCheck = true;

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
        "storybookID": storybookID,
        'languageCode': widget.languageValue,
      });
      Page p = Page(_insertPageID[i], _insertPageNo[i], _insertImage[i],
          _pageContent[i], storybookID, widget.languageValue);
      db.savePage(p);//save page in local storage
    }
    
    
    //Below is the solution to solve deleting issue (page number and content confuse and mix up,only happen when deleting page)
    //The concept of solution is like no matter what user delete, the system also delete the last page and move the content forward
    //Of course also delete what user want to delete
    //Here is some sort like a logic solution to solve the issue
    final pageResponse = await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/pageByPageNo.php", body: {
      'storybookID': storybookID,
      'languageCode': widget.languageValue,
    });
    allPages = json.decode(pageResponse.body);
    if (allPages.length > 0) {
      if (allPages.length != _pageContent.length) {
        //delete the page in server
        await http.post(
            "http://i2hub.tarc.edu.my:8887/mmsr/deletePageByPageNo.php",
            body: {
              'storybookID': storybookID,
              'languageCode': widget.languageValue,
              'pageNo': _insertPageNo[_pageContent.length - 1],
            });

        //delete the page in local storage
        db.deletePageByPageNo(storybookID, widget.languageValue,
            int.parse(_insertPageNo[_pageContent.length - 1]));
      }
    }
  }

  void _confirmDelete(//confirmation dialog to delete
      String title, String id, String code, int index, String storybookID) {
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
                  //remove every thing of the page
                  _pageContent.removeAt(index);
                  _insertImage.removeAt(index);
                  _pageImage.removeAt(index);
                  _insertPageID.removeAt(index);
                  //_insertPageNo.removeAt(index);
                  _deletePage(id, code, index, storybookID);
                  setState(() {
                    _scaffoldKey.currentState.showSnackBar( //snackbar
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
                    Navigator.of(context).pop(); //Should refresh
                  });
                },
              ),
            ],
          );
        });
  }

  Future _deletePage(//delete operation
      String id, String code, int index, String storybookID) async {
    //delete the page based on its page ID and language Code
    await http
        .post("http://i2hub.tarc.edu.my:8887/mmsr/deleteByPageID.php", body: {
      "pageID": id,
      "languageCode": code,
    });
  }
}
