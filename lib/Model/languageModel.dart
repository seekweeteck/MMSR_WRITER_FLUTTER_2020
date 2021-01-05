class LanguageModel { //language class to store language data
  String languageCode;
  String languageDesc;

  LanguageModel(this.languageCode, this.languageDesc);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'languageCode': languageCode,
      'languageDesc': languageDesc,
    };
    return map;
  }

  LanguageModel.fromMap(Map<String, dynamic> map) {
    languageCode = map['languageCode'];
    languageDesc = map['languageDesc'];
  }
}
