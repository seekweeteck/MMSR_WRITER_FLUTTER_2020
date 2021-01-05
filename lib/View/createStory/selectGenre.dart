import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SelectGenre extends StatefulWidget {
  SelectGenre({Key key}) : super(key: key);
  @override
  _SelectGenreState createState() => new _SelectGenreState();
}
//This page mostly is a list of hardcoding genre
class _SelectGenreState extends State<SelectGenre> {
  int selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Genre'),
        centerTitle: true,
      ),
      body: new SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 1,
              groupValue: selected,
              title: Text("Biography"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Biography");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 2,
              groupValue: selected,
              title: Text("Fables"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Fables");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 3,
              groupValue: selected,
              title: Text("Fairy Tales"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Fairy Tales");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 4,
              groupValue: selected,
              title: Text("Folktales"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Folktales");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 5,
              groupValue: selected,
              title: Text("Historical Fiction"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Historical Fiction");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 6,
              groupValue: selected,
              title: Text("Legends"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Legends");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 7,
              groupValue: selected,
              title: Text("Modern Fantasy"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Modern Fantasy");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 8,
              groupValue: selected,
              title: Text("Myth"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Myth");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 9,
              groupValue: selected,
              title: Text("Poetry & Drama"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Poetry & Drama");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 10,
              groupValue: selected,
              title: Text("Other"),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Other");
              },
            ),
            Divider(
              height: 1.0,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
