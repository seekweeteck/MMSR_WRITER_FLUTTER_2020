class Page { //page class to store page data
  String pageID;
  String pageNo;
  String pagePhoto;
  String pageContent;
  String storybookID;
  String languageCode;

  Page(this.pageID, this.pageNo, this.pagePhoto, this.pageContent,
      this.storybookID, this.languageCode);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'pageID': pageID,
      'pageNo': pageNo,
      'pagePhoto': pagePhoto,
      'pageContent': pageContent,
      'storybookID': storybookID,
      'languageCode': languageCode,
    };
    return map;
  }

  Page.fromMap(Map<String, dynamic> map) {
    pageID = map['pageID'];
    pageNo = map['pageNo'];
    pagePhoto = map['pagePhoto'];
    pageContent = map['pageContent'];
    storybookID = map['storybookID'];
    languageCode = map['languageCode'];
  }
}
