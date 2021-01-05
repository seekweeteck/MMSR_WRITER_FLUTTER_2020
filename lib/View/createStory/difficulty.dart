import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SelectDifficulty extends StatefulWidget {
  @override
  SelectDifficulty({Key key}) : super(key: key);
  _SelectDifficultyState createState() => new _SelectDifficultyState();
}

//This page mostly is a list of hardcoding difficulty
class _SelectDifficultyState extends State<SelectDifficulty> {
  int selected;
  String beginnerText = "20-50 words";
  String intermediateText = "100-500 words";
  String hardText = "500-1000 words";
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Difficulty'),
        centerTitle: true,
      ),
      body: new SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: 1,
              groupValue: selected,
              title: Text("Beginner",style:
                            new TextStyle(fontSize: 20.0)),   
              subtitle: new TextField(
                 enabled: false,
                 decoration: new InputDecoration(
                        hintText: beginnerText, //display the genre
                        border: InputBorder.none,
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Beginner");
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
              title: Text("Intermediate",style:
                            new TextStyle(fontSize: 20.0)),
              subtitle: new TextField(
                 enabled: false,
                 decoration: new InputDecoration(
                        hintText: intermediateText, //display the genre
                        border: InputBorder.none,
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Intermediate");
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
              title: Text("Hard",style:
                            new TextStyle(fontSize: 20.0)),
              subtitle: new TextField(
                 enabled: false,
                 decoration: new InputDecoration(
                        hintText: hardText, //display the genre
                        border: InputBorder.none,
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  selected = value;
                });
                Navigator.pop(context, "Hard",);
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
