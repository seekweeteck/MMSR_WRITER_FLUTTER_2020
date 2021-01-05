import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mmsr/style/theme.dart' as Theme;
import 'package:mmsr/Miscellaneous/editPersonalInfo.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);
  @override
  _SettingsState createState() => new _SettingsState();
}

class _SettingsState extends State<Settings> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final String feedBackFormUrl =
      "https://forms.gle/nfhkSWUCWw76Ghea6"; //feedback form URL
  final String aboutUsUrl = "http://i2hub.tarc.edu.my:8887/mmsr/aboutus.php";
  final String contactUsUrl =
      "http://i2hub.tarc.edu.my:8887/mmsr/contactus.html"; //contact us page URL
  final String privacyUrl =
      "http://i2hub.tarc.edu.my:8887/mmsr/privacypolicy.php"; //privacy statement page URL
  bool switchVal = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: new Container( //this container is the background color
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
        child: new ListView(
          children: <Widget>[
            new ListTile(
              leading: new Icon(Icons.edit),
              title: new Text('Edit Personal Info'),
              trailing: new Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPersonalInfo(), //click to edit personal info
                  ),
                );
              },
            ),
            new Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            // new ListTile(
            //   leading: new Icon(Icons.fiber_smart_record),
            //   title: new Text('Night Mode'), //night mode UI (no function yet)
            //   trailing: Switch(
            //     value: switchVal,
            //     onChanged: (bool e) => changeMode(e),
            //   ),
            // ),
            // new Divider(
            //   height: 1.0,
            //   color: Colors.grey,
            // ),
            new ListTile(
              leading: new Icon(Icons.account_circle),
              title: new Text('About Us'),
              onTap: () async {
                _launchAboutus();
              },
            ),
            new Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            new ListTile(
              leading: new Icon(Icons.call),
              title: new Text('Contact Us'),
              onTap: () async {
                _launchContactus();
              },
            ),
            new Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            new ListTile(
              leading: new Icon(Icons.info_outline),
              title: new Text('Terms and Privacy Policy'),
              onTap: () async {
                _launchPrivacy(); 
              },
            ),
            new Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            new ListTile(
              leading: new Icon(Icons.feedback),
              title: new Text('Feedback'),
              onTap: () async {
                _launchFeedback();
              },
            ),
            new Divider(
              height: 1.0,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  _launchFeedback() async {
    if (await canLaunch(feedBackFormUrl)) {
      await launch(feedBackFormUrl);  //direct to feedback page
    } else {
      throw 'Could not launch $feedBackFormUrl'; //print error on console
    }
  }

  _launchAboutus() async {
    if (await canLaunch(aboutUsUrl)) {
      await launch(aboutUsUrl);  //direct to about us page
    } else {
      throw 'Could not launch $aboutUsUrl';
    }
  }

  _launchContactus() async {
    if (await canLaunch(contactUsUrl)) {
      await launch(contactUsUrl); //direct to contact us page
    } else {
      throw 'Could not launch $contactUsUrl';
    }
  }

  _launchPrivacy() async {
    if (await canLaunch(privacyUrl)) {
      await launch(privacyUrl); //direct to privacy statement page
    } else {
      throw 'Could not launch $privacyUrl';
    }
  }

  void changeMode(bool e) { //for night mode switching (enhance feature)
    //final appStyleMode = Provider.of<AppStyleModeNotifier>(context);
    setState(() {
      if (e == true) {
        //  appStyleMode.switchMode();
        switchVal = e;
      } else {
        //appStyleMode.switchMode();
        switchVal = e;
      }
    });
  }
}
