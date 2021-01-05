import 'package:flutter/material.dart';
import 'package:mmsr/Controller/db.dart';

class LanguageLoad extends StatefulWidget {
  @override
  LanguageLoad({Key key}) : super(key: key);
  _LanguageLoadState createState() => new _LanguageLoadState();
}

class _LanguageLoadState extends State<LanguageLoad> {
  var db;

  @override
  void initState() {
    super.initState();
    db = DBHelper();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new FutureBuilder<List>(
        future: db.getLanguageModel(), //get all language from local storage
        builder: (context, snapshot) {
          return snapshot.hasData
              ? new Language(
                  data: snapshot.data,//language data
                )
              : new Center(
                  child: new CircularProgressIndicator(),//loading indicator
                );
        },
      ),
    );
  }
}

class Language extends StatefulWidget {
  final List data;//language data
  Language({Key key, this.data}) : super(key: key);
  @override
  _LanguageState createState() => new _LanguageState();
}

class _LanguageState extends State<Language> {
  int selected;
  int radioValue = 0;
  @override
  void initState() {
    super.initState();
  }

  Widget _buildPageList() {
    return new ListView.separated(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: widget.data == null ? 0 : widget.data.length,//count of language
      itemBuilder: (context, index) {
        return new RadioListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          value: 1,
          groupValue: selected,
          title: new Text(widget.data[index].languageDesc), //language description
          onChanged: (value) {
            setState(() {
              selected = value;
            });
            Navigator.pop(context, widget.data[index].languageDesc);//pop language description to previous page (addstoryinfo.dart)
          },
        );
      },
      separatorBuilder: (context, index) {
        return new Divider(
          height: 1.0,
          color: Colors.grey,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Language'),
        centerTitle: true,
      ),
      body: new SingleChildScrollView(
          child: new Column(
        children: <Widget>[
          _buildPageList(),
          new Divider(
            height: 1.0,
            color: Colors.grey,
          ),
        ],
      )),
    );
  }
}
