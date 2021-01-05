import 'dart:async';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mmsr/Model/storybook.dart';
import 'package:mmsr/Model/page.dart';
import 'package:mmsr/Model/languageModel.dart';
import 'package:mmsr/Model/status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class DBHelper {
  static Database _db;
  static const String db_name = 'ContributorDB';

  static const String storybookID = 'storybookID';
  static const String storybookTitle = 'storybookTitle';
  static const String storybookCover = 'storybookCover';
  static const String storybookDesc = 'storybookDesc';
  static const String storybookGenre = 'storybookGenre';
  static const String readabilityLevel = 'readabilityLevel'; //read
  static const String status = 'status';
  static const String dateOfCreation = 'dateOfCreation';
  static const String contributorID = 'ContributorID';
  static const String languageCode = 'languageCode';
  static const String storybookTable = 'Storybook';

  // static const String followerTable = 'Follower';
  // static const String reader_id = 'children_id';
 
  static const String pageID = 'pageID';
  static const String pageNo = 'pageNo';
  static const String pagePhoto = 'pagePhoto';
  static const String pageContent = 'pageContent';
  static const String pageTable = 'Page';

  static const String languageDesc = 'languageDesc';
  static const String languageTable = 'Language';

  static const String mediaTable = 'Media';

  static const String storyCollectionTable = 'StoryCollection';

  static const String downloadDate = 'downloadDate';
  static const String contributorName = 'contributorName';

  static const String pageTextTable = 'PageText';

  static const String speechID = 'speech_id';

  static const String pageImageTable = 'PageImage';

  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  initDb() async { //local database initialize
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, db_name);
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  _onCreate(Database db, int version) async { //create database 
    //storybook table
    await db.execute("CREATE TABLE $storybookTable("
        "$storybookID TEXT,"
        "$storybookTitle TEXT,"
        "$storybookCover BLOB,"
        "$storybookDesc TEXT,"
        "$storybookGenre TEXT,"
        "$readabilityLevel TEXT,"
        "$dateOfCreation DATE,"
        "$contributorID TEXT,"
        "$status TEXT,"
        "$languageCode TEXT,"
        "PRIMARY KEY ($storybookID,$languageCode));");



    //page table
    await db.execute("CREATE TABLE $pageTable("
        "$pageID TEXT,"
        "$pageNo TEXT,"
        "$pagePhoto BLOB,"
        "$pageContent TEXT,"
        "$storybookID TEXT,"
        "$languageCode TEXT,"
        "PRIMARY KEY ($pageID,$languageCode));");

    //language table
    await db.execute("CREATE TABLE $languageTable("
        "$languageCode TEXT PRIMARY KEY,"
        "$languageDesc TEXT)");

        
  }



//Storybook
  Future<int> saveStorybook(Storybook storybook) async {
    var dbClient = await db;
    try {
      int res = await dbClient.insert("Storybook", storybook.toMap()); //insert storybook
      return res;
    } on DatabaseException { //if the storybook exist, update the storybook
      return await dbClient.update("Storybook", storybook.toMap(),
          where: '$storybookID=? AND $languageCode=?',
          whereArgs: [storybook.storybookID, storybook.languageCode]);
    }
  }

  Future<List<Storybook>> getStorybook() async { //display all storybook belongs to the user and order by date in descending order
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');
    var dbClient = await db;
    List<Map> maps = await dbClient.rawQuery(
        "SELECT * FROM Storybook WHERE ContributorID = '$username' ORDER BY dateOfCreation DESC");

    List<Storybook> storybooks = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        storybooks.add(Storybook.fromMap(maps[i]));
      }
    }
    return storybooks;
  }

  Future<List<Storybook>> getStories(String id) async { //display all storybook belongs to the user and order by storybook ID
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery(
        "SELECT * FROM Storybook WHERE ContributorID = '$id' ORDER BY storybookID");
    List<Storybook> storyData = new List();
    for (int i = 0; i < list.length; i++) {
      var data = new Storybook(
          list[i]['storybookID'],
          list[i]['storybookTitle'],
          list[i]['storybookCover'],
          list[i]['storybookDesc'],
          list[i]['storybookGenre'],
          list[i]['readabilityLevel'],
          list[i]['status'],
          list[i]['dateOfCreation'],
          list[i]['contributorID'],
          list[i]['languageCode']);
      storyData.add(data);
    }
    return storyData;
  }


  Future<int> getStorybookCount() async { //count storybook belongs to the user
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');
    var dbClient = await db;
    var x = await dbClient.rawQuery(
        "SELECT COUNT(*) FROM Storybook WHERE ContributorID = '$username'");

    int count = Sqflite.firstIntValue(x);
    return count;
  }

  Future<int> getStorybookCountPublished() async { //count storybook belongs to the user and status = 'Published'
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.get('loginID');
    var dbClient = await db;
    var x = await dbClient.rawQuery(
        "SELECT COUNT(*) FROM Storybook WHERE ContributorID = '$username' AND status='Published'");

    int count = Sqflite.firstIntValue(x);
    return count;
  }

  Future<int> updateStorybook(Storybook storybook) async { //update all the storybook information
    var dbClient = await db;
    return await dbClient.update("Storybook", storybook.toMap(),
        where: '$storybookID=? AND $languageCode=?',
        whereArgs: [storybook.storybookID, storybook.languageCode]);
  }

  Future<int> updateStorybookStatus(StorybookStatus storybook) async { //update the storybook status
    var dbClient = await db;
    return await dbClient.update("Storybook", storybook.toMap(),
        where: '$storybookID=? AND $languageCode=?',
        whereArgs: [storybook.storybookID, storybook.languageCode]);
  }

  Future<int> deleteStorybook(String id, String languageCode) async { //delete the storybook
    var dbClient = await db;
    int res = await dbClient.rawDelete(
        "DELETE FROM Storybook WHERE storybookID=? AND languageCode=?",
        [id, languageCode]);
    return res;
  }

  Future<int> deleteAllStorybook(String user) async { //delete all the storybook belongs to the user
    var dbClient = await db;
    int res = await dbClient
        .rawDelete("DELETE FROM Storybook WHERE ContributorID=?", [user]);
    return res;
  }

//Page
  Future<int> savePage(Page page) async {
    var dbClient = await db;
    try {
      int res = await dbClient.insert("Page", page.toMap()); //insert new page
      return res;
    } on DatabaseException { //if the page exist, update it
      return await dbClient.update("Page", page.toMap(),
          where: '$pageID=? AND $languageCode=?',
          whereArgs: [page.storybookID, page.languageCode]);
    }
  }

  Future<List<Page>> getPage(String id, String code) async { //display page by matching storybook ID and language code
    var dbClient = await db;
    List<Map> maps = await dbClient.rawQuery(
        "SELECT * FROM Page WHERE storybookID=? AND languageCode=?",
        [id, code]);

    List<Page> pages = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        pages.add(Page.fromMap(maps[i]));
      }
    }
    return pages;
  }

  Future<int> updatePage(Page page) async { //update all the page information
    var dbClient = await db;
    return await dbClient.update("Page", page.toMap(),
        where: '$pageID=? AND $languageCode=?',
        whereArgs: [page.pageID, page.languageCode]);
  }

  Future<int> deletePage(String id, String languageCode) async { //delete page based on storybook ID and language code
    var dbClient = await db;
    int res = await dbClient.rawDelete(
        "DELETE FROM Page WHERE storybookID='$id' AND languageCode='$languageCode'");
    return res;
  }

  Future<int> deletePagebyPageID(String id, String languageCode) async { //delete page based on page ID and language code
    var dbClient = await db;
    int res = await dbClient.rawDelete(
        "DELETE FROM Page WHERE pageID='$id' AND languageCode='$languageCode'");
    return res;
  }

  Future<int> deletePageByPageNo(String id, String languageCode, int no) async { 
    //delete page where the page number more than the value (this is to solve some bug when deleting page)
    var dbClient = await db;
    int res = await dbClient.rawDelete(
        "DELETE FROM Page WHERE storybookID=? AND languageCode=? AND pageNo>?",
        [id, languageCode, no]);
    return res;
  }

  //Language
  Future<int> saveLanguage(LanguageModel language) async { //insert language
    var dbClient = await db;

    int res = await dbClient.insert("Language", language.toMap());
    return res;
  }

  Future<List<LanguageModel>> getLanguageModel() async { //display all language
    var dbClient = await db;
    List<Map> maps = await dbClient.rawQuery("SELECT * FROM Language");

    List<LanguageModel> language = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        language.add(LanguageModel.fromMap(maps[i]));
      }
    }
    return language;
  }

  Future close() async { //close the database
    var dbClient = await db;
    dbClient.close();
  }
}
