import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Notifications extends StatefulWidget {
  Notifications({Key key}) : super(key: key);
  @override
  _NotificationsState createState() => new _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Settings'),
      //   centerTitle: true,
      // ),
      body: new Container(
        // decoration: new BoxDecoration(
        //   gradient: new LinearGradient(
        //       colors: [
        //         Theme.ThemeColors.loginGradientStart,
        //         Theme.ThemeColors.loginGradientEnd
        //       ],
        //       begin: const FractionalOffset(0.0, 0.0),
        //       end: const FractionalOffset(1.0, 1.0),
        //       stops: [0.0, 1.0],
        //       tileMode: TileMode.clamp),
        // ),
        child: new ListView(
          children: <Widget>[
            new Padding(
              padding: EdgeInsets.fromLTRB(1.0, 100.0, 1.0, 100.0),
              child: new Column(
                children: <Widget>[
                  new Image.asset(
                    "assets/img/notification.png",  //display image to show no notification
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    height: MediaQuery.of(context).size.height / 2.1,
                    width: MediaQuery.of(context).size.width,
                  ),
                  Text(
                    'No notification yet',
                    style: TextStyle(
                      fontFamily: 'WorkSansMedium',
                      fontSize: 30,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
