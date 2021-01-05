class Storybook { //storybook class to store storybook data
  String storybookID;
  String storybookTitle;
  String storybookCover;
  String storybookDesc;
  String storybookGenre;
  String readabilityLevel;
  String status;
  String dateOfCreation;
  String contributorID;
  String languageCode;

  Storybook(
      this.storybookID,
      this.storybookTitle,
      this.storybookCover,
      this.storybookDesc,
      this.storybookGenre,
      this.readabilityLevel,
      this.status,
      this.dateOfCreation,
      this.contributorID,
      this.languageCode,
);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'storybookID': storybookID,
      'storybookTitle': storybookTitle,
      'storybookCover': storybookCover,
      'storybookDesc': storybookDesc,
      'storybookGenre': storybookGenre,
      'readabilityLevel': readabilityLevel,
      'status': status,
      'dateOfCreation': dateOfCreation,
      'contributorID': contributorID,
      'languageCode': languageCode,
    };
    return map;
  }

  Storybook.fromMap(Map<String, dynamic> map) {
    storybookID = map['storybookID'];
    storybookTitle = map['storybookTitle'];
    storybookCover = map['storybookCover'];
    storybookDesc = map['storybookDesc'];
    storybookGenre = map['storybookGenre'];
    readabilityLevel = map['readabilityLevel'];
    status = map['status'];
    dateOfCreation = map['dateOfCreation'];
    contributorID = map['contributorID'];
    languageCode = map['languageCode'];
  }
}
