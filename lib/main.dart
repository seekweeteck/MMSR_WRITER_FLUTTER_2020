import 'package:flutter/material.dart';
import 'package:mmsr/View/login_page.dart';
import 'package:mmsr/utils/navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mmsr/style/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  var loginID = prefs.getString('loginID'); //Stored login username
  runApp(MaterialApp(home: loginID == null ? LoginPage() : NavigatorWriter())); //If the user login before, it will remember and direct to homepage else prompt user to enter username and password
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MMSR',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: new LoginPage(),
      ),
      create: (context) => AppStyleModeNotifier(), //For styling purpose (this code is an enhance feature)
    );
  }
}
