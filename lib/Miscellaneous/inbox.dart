import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mmsr/Miscellaneous/messages.dart';
import 'package:mmsr/Miscellaneous/notifications.dart';
import 'package:mmsr/utils/navigator.dart';

class Inbox extends StatefulWidget {
  Inbox({Key key}) : super(key: key);
  @override
  _InboxState createState() => new _InboxState();
}

class _InboxState extends State<Inbox> with SingleTickerProviderStateMixin { //this class contains 2 tab (messages and notifications)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                   Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => NavigatorWriter(page: "two",)), //back to profile page
                        (Route<dynamic> route) => false);
                  },
                );
              },
            ),
            bottom: new TabBar(
              unselectedLabelColor: Colors.white,
              labelColor: Colors.black,
              tabs: <Widget>[
                new Tab(
                  text: "Messages",
                ),
                new Tab(
                  text: "Notifications",
                ),
              ],
            ),
            title: Text('Inbox'),
            centerTitle: true,
          ),
          body: new TabBarView(
            children: <Widget>[
              new Messages(),
              new Notifications(),
            ],
          ),
          // new Container(
          //   decoration: new BoxDecoration(
          //     gradient: new LinearGradient(
          //         colors: [
          //           Theme.ThemeColors.loginGradientStart,
          //           Theme.ThemeColors.loginGradientEnd
          //         ],
          //         begin: const FractionalOffset(0.0, 0.0),
          //         end: const FractionalOffset(1.0, 1.0),
          //         stops: [0.0, 1.0],
          //         tileMode: TileMode.clamp),
          //   ),
          //   child: new ListView(
          //     children: <Widget>[],
          //   ),
          // ),
        ),
      ),
    );
  }
}
