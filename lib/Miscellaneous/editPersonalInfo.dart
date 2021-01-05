import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';

class EditPersonalInfo extends StatefulWidget {
  EditPersonalInfo({Key key}) : super(key: key);
  @override
  _EditPersonalInfoState createState() => new _EditPersonalInfoState();
}

class _EditPersonalInfoState extends State<EditPersonalInfo> {
  ProgressDialog pr;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final FocusNode myFocusNodeEmailLogin = FocusNode();
  final FocusNode myFocusNodePasswordLogin = FocusNode();

  final FocusNode myFocusNodePassword = FocusNode();
  final FocusNode myFocusNodeEmail = FocusNode();
  final FocusNode myFocusNodeName = FocusNode();

  TextEditingController passwordController = new TextEditingController();

  bool _obscureTextSignup = true;
  bool _obscureTextSignupConfirm = true;

  TextEditingController signupEmailController = new TextEditingController();
  TextEditingController signupNameController = new TextEditingController();
  TextEditingController signupPasswordController = new TextEditingController();
  TextEditingController signupUsernameController = new TextEditingController();
  TextEditingController signupConfirmPasswordController =
      new TextEditingController();
  TextEditingController monthController = new TextEditingController();

  String DOB_text = "Birthdate";
  DateTime _dateTime;
  String _format = 'yyyy-MM-dd';
  static DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  static const String MIN_DATETIME = '1950-01-01';
  static String MAX_DATETIME = dateFormat.format(DateTime.now()).toString();
  static const String INIT_DATETIME = '1950-01-01'; //useless

  int groupValue;

  var contributorInfo;
  var updateInfo;

  String insertGender;

  int radioOnchange(int e) { //gender radio button
    setState(() {
      if (e == 1) {
        groupValue = 1;
        insertGender = 'M';
      } else if (e == 2) {
        groupValue = 2;
        insertGender = 'F';
      }
    });
    return groupValue;
  }

  void _togglePassword() { //function for user to click and disable the password from obscure text
    setState(() {
      _obscureTextSignup = !_obscureTextSignup;
    });
  }

  void _togglePasswordConfirm() { //function for user to click and disable the password confirmation from obscure text
    setState(() {
      _obscureTextSignupConfirm = !_obscureTextSignupConfirm;
    });
  }

  void _showDatePicker() { //date picker function
    DatePicker.showDatePicker(
      context,
      pickerTheme: DateTimePickerTheme(
        cancel: Text('custom cancel', style: TextStyle(color: Colors.white)),
      ),
      minDateTime: DateTime.parse(MIN_DATETIME),
      maxDateTime: DateTime.parse(MAX_DATETIME),
      initialDateTime: _dateTime,
      dateFormat: _format,
      onChange: (dateTime, List<int> index) {
        setState(() {
          _dateTime = dateTime;
        });
      },
      onConfirm: (dateTime, List<int> index) {
        setState(() {
          _dateTime = dateTime;
          DOB_text = _dateTime.year.toString() +
              '-' +
              _dateTime.month.toString().padLeft(2, '0') +
              '-' +
              _dateTime.day.toString().padLeft(2, '0');
        });
      },
    );
  }

  Color setColor(String text) {
    Color color;
    setState(() {
      if (text == 'Birthdate') {
        color = Colors.black54;
      } else {
        color = Colors.black;
      }
    });
    return color;
  }

  Future setInfo() async { //initialize all data into the field
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.get('loginID');

    try {
      final contributorResponse = await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/checkExistContributor.php",
          body: {
            "ContributorID": username.toString(),
          });
      contributorInfo = json.decode(contributorResponse.body);
      if (contributorInfo.length > 0) { 
        signupUsernameController.text = contributorInfo[0]['ContributorID'];
        signupPasswordController.text = contributorInfo[0]['password'];
        signupConfirmPasswordController.text = contributorInfo[0]['password'];
        signupNameController.text = contributorInfo[0]['Name'];
        signupEmailController.text = contributorInfo[0]['email'];
        DOB_text = contributorInfo[0]['DOB'];
        if (contributorInfo[0]['Gender'] == 'M') {
          radioOnchange(1);
        } else {
          radioOnchange(2);
        }
      }
    } on SocketException {
      print("Connection error");
    }
  }

  Future _updateInfo() async { //update the user info in the server
    try {
      //final updateResponse =
      await http.post(
          "http://i2hub.tarc.edu.my:8887/mmsr/updateContributor.php",
          body: {
            'ContributorID': signupUsernameController.text,
            'Name': signupNameController.text,
            'password': signupPasswordController.text,
            'Gender': insertGender,
            'email': signupEmailController.text,
            'DOB': DOB_text,
          });
    } on SocketException {
      print("Connection error");
    }
  }

  void showInSnackBar(String value) { //Function of showing snackbar, the parameter is the message of the snackbar
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

  @override
  void initState() {
    setInfo();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Edit Personal Info'),
        centerTitle: true,
      ),
      body: new SingleChildScrollView(
        child: new Container(
          height: MediaQuery.of(context).size.height,
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
          child: _buildPageList(context),
        ),
      ),
    );
  }

  Widget _buildPageList(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              Card(
                margin: EdgeInsets.only(left: 5, right: 5),
                elevation: 2.0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width, //300
                  height: 375, //375
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5.0, bottom: 0, left: 25.0, right: 25.0),
                        child: TextField(
                          enabled: false,
                          focusNode: myFocusNodeName,
                          controller: signupUsernameController,
                          keyboardType: TextInputType.text,
                          //textCapitalization: TextCapitalization.words,
                          style: TextStyle(
                              fontFamily: "WorkSansSemiBold",
                              fontSize: 16.0,
                              color: Colors.grey),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.account_circle,
                              color: Colors.grey,
                            ),
                            hintText: "Username",
                            hintStyle: TextStyle(
                                fontFamily: "WorkSansSemiBold", fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5.0, bottom: 0, left: 25.0, right: 25.0),
                        child: TextField(
                          focusNode: myFocusNodePassword,
                          controller: signupPasswordController,
                          obscureText: _obscureTextSignup,
                          style: TextStyle(
                              fontFamily: "WorkSansSemiBold",
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.lock,
                              color: Colors.black,
                            ),
                            hintText: "New Password",
                            hintStyle: TextStyle(
                                fontFamily: "WorkSansSemiBold", fontSize: 16.0),
                            suffixIcon: GestureDetector(
                              onTap: _togglePassword,
                              child: Icon(
                                _obscureTextSignup
                                    ? FontAwesomeIcons.eye
                                    : FontAwesomeIcons.eyeSlash,
                                size: 15.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5.0, bottom: 0, left: 25.0, right: 25.0),
                        child: TextField(
                          controller: signupConfirmPasswordController,
                          obscureText: _obscureTextSignupConfirm,
                          style: TextStyle(
                              fontFamily: "WorkSansSemiBold",
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.lock,
                              color: Colors.black,
                            ),
                            hintText: "Confirmation",
                            hintStyle: TextStyle(
                                fontFamily: "WorkSansSemiBold", fontSize: 16.0),
                            suffixIcon: GestureDetector(
                              onTap: _togglePasswordConfirm,
                              child: Icon(
                                _obscureTextSignupConfirm
                                    ? FontAwesomeIcons.eye
                                    : FontAwesomeIcons.eyeSlash,
                                size: 15.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 0.0, bottom: 0, left: 25.0, right: 25.0),
                        child: TextField(
                          controller: signupNameController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(
                              fontFamily: "WorkSansSemiBold",
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.user,
                              color: Colors.black,
                            ),
                            hintText: "Full Name",
                            hintStyle: TextStyle(
                                fontFamily: "WorkSansSemiBold", fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                          padding: EdgeInsets.only(
                              top: 0.0, bottom: 0, left: 25.0, right: 0),
                          child: Container(
                            height: 45,
                            child: Row(
                              children: <Widget>[
                                Icon(FontAwesomeIcons.transgender),
                                ButtonBar(
                                  children: <Widget>[
                                    new Radio(
                                      onChanged: (e) => radioOnchange(e),
                                      activeColor: Colors.blue,
                                      value: 1,
                                      groupValue: groupValue,
                                            ),
                                    new Text(
                                      'Male',
                                      style: TextStyle(
                                          fontFamily: "WorkSansSemiBold",
                                          fontSize: 16.0,
                                          height:1,
                                          color: Colors.black),
                                    ),
                                    new Radio(
                                      onChanged: (e) => radioOnchange(e),
                                      activeColor: Colors.red,
                                      value: 2,
                                      groupValue: groupValue,
                                    ),
                                    new Text(
                                      'Female',
                                      style: TextStyle(
                                          fontFamily: "WorkSansSemiBold",
                                          fontSize: 16.0,
                                          height:1,
                                          color: Colors.black),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          )),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 3.0, bottom: 0, left: 25.0, right: 25.0),
                        child: GestureDetector(
                          onTap: _showDatePicker,
                          child: Container(
                            color: Colors.white,
                            height: 50,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: <Widget>[
                                Icon(FontAwesomeIcons.birthdayCake),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: 5.0,
                                      bottom: 5.0,
                                      left: 17.0,
                                      right: 25.0),
                                  child: Text(
                                    '$DOB_text',
                                    style: TextStyle(
                                        fontFamily: "WorkSansSemiBold",
                                        fontSize: 17.0,
                                        color: setColor(DOB_text)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5.0, bottom: 0, left: 25.0, right: 25.0),
                        child: TextField(
                          focusNode: myFocusNodeEmail,
                          controller: signupEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              fontFamily: "WorkSansSemiBold",
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.envelope,
                              color: Colors.black,
                            ),
                            hintText: "Email Address",
                            hintStyle: TextStyle(
                                fontFamily: "WorkSansSemiBold", fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 355.0, left: 48),
                decoration: new BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.ThemeColors.buttonGradientStart,
                      offset: Offset(1.0, 6.0),
                      blurRadius: 10.0,
                    ),
                    BoxShadow(
                      color: Theme.ThemeColors.buttonGradientEnd,
                      offset: Offset(1.0, 6.0),
                      blurRadius: 10.0,
                    ),
                  ],
                  gradient: new LinearGradient(
                      colors: [
                        Theme.ThemeColors.buttonGradientEnd,
                        Theme.ThemeColors.buttonGradientStart
                      ],
                      begin: const FractionalOffset(0.2, 0.2),
                      end: const FractionalOffset(1.0, 1.0),
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp),
                ),
              ),
            ],
          ),
          new Padding(
            padding: EdgeInsets.only(
                top: 15.0, bottom: 5.0, left: 25.0, right: 25.0),
            child: new GestureDetector(
              onTap: () {
                if (signupConfirmPasswordController.text !=
                    signupPasswordController.text) {
                  showInSnackBar("Wrong Confirm Password");
                } else {
                  _updateInfo();
                  pr = new ProgressDialog(context,
                      type: ProgressDialogType.Normal); 
                  pr.style(
                    message: 'Saving...',
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
                  pr.show(); //show progress dialog
                  Future.delayed(Duration(seconds: 1)).then((onValue) {
                    BlueSnackBar("Information saved");
                  });

                  Future.delayed(Duration(seconds: 3)).then((onValue) {
                    if (pr.isShowing()) {
                      pr.hide(); //dismiss progress dialog
                      Navigator.pop(context); //pop to previous page
                    }
                  });
                }
              },
              child: new Container(
                width: MediaQuery.of(context).size.width,
                height: 40.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.ThemeColors.customButtonEnd,
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
                child: Center(
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void BlueSnackBar(String value) { //blue color snackbar function
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
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 3),
    ));
  }
}


