import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mmsr/View/createStory/selectGenre.dart';
import 'package:mmsr/View/createStory/language.dart';
import 'package:mmsr/View/createStory/difficulty.dart';
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
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:mmsr/utils/navigator.dart';

//profile picture page
class ProfilePicture extends StatefulWidget {
  final String contributorID;

  ProfilePicture({
    Key key,
    this.contributorID,
  }) : super(key: key);

  @override
  _ProfilePictureState createState() => new _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  File galleryFile; //image from gallery
  File cameraFile; //image from camera
  File passImage;
  var random = new Random(); //random value for some exception case

  bool cancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Picture'),
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
                //next page
                if (galleryFile == null && cameraFile == null) {
                  //ensure storybook cover cannot be empty
                  _showBookCoverDialog();
                } else {
                  //store the image into passImage variable
                  if (galleryFile != null) {
                    passImage = galleryFile;
                  } else if (cameraFile != null) {
                    passImage = cameraFile;
                  } else {
                    passImage = null;
                  }

                  http.post("http://i2hub.tarc.edu.my:8887/mmsr/updatePicture.php", body: {
                    //Insert storybook
                    'ContributorID': widget.contributorID,
                    'picture': base64Encode(passImage.readAsBytesSync()),
                  });

                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => NavigatorWriter(page: "two")),
                      (Route<dynamic> route) => false);
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
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, //make floating action button in the center
    );
  }

  void imageSelectorGallery() async {
    var result;
    File croppedFile;

    try {
      galleryFile = await ImagePicker.pickImage(
        source: ImageSource.gallery, //pick image from gallery
      );

      try {
        //crop image
        croppedFile = await ImageCropper.cropImage(
          sourcePath: galleryFile.path,
          //define the height and width of the cropped image
          maxHeight: 512,
          maxWidth: 512,
        );

        result = await FlutterImageCompress.compressAndGetFile(
          croppedFile.path,
          croppedFile.path + "temp.jpeg",
          quality: 88, //image quality, the higher the larger size of the image
        );
      } on NoSuchMethodError {
        //when user click on cancel selecting image
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
    } on PlatformException {
      //When user deny the permission to gallery
      print("Deny to gallery");
    }
  }

  void imageSelectorCamera() async {
    var result;
    File croppedFile;
    try {
      cameraFile = await ImagePicker.pickImage(
        source: ImageSource.camera, //camera
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
      } on NoSuchMethodError {
        //cancel the result after entering the camera section
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
    } on PlatformException {
      //Deny permission to camera
      print("Deny to camera");
    }
  }

  Widget displaySelectedFile(File file) {
    //function to display the storybook cover
    return new Container(
      alignment: Alignment.center,
      //the height and width just for displaying purpose, not the actual height and width of the image
      height: 450.0, //height of the storybook cover to display
      width: 550.0, //width of the storybook cover to display
      child: file == null || cancel == true
          ? new Text(
              "Add image", //default text when no image selected
              style: TextStyle(color: Colors.grey, fontSize: 20.0),
              textAlign: TextAlign.center,
            )
          : new Image.file(
              //the image selected, either in gallery/camera
              file,
              height: 450.0,
              width: 550.0,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
    );
  }

  void _showBookCoverDialog() {
    //when not picking storybook cover and click on next page, a dialog will show
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Incomplete Information"),
            content: new Text("Please select an image for profile picture"),
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
