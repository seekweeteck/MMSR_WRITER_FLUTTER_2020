class StorybookStatus { //status class to store storybook status
  String storybookID;
  String status;
  String languageCode;

  StorybookStatus(
      this.storybookID,
      this.status,
      this.languageCode);

  Map<String, dynamic> toMap(){
    var map=<String, dynamic>{
      'storybookID':storybookID,
      'status':status,
      'languageCode':languageCode,
    };
    return map;
  }

  StorybookStatus.fromMap(Map<String, dynamic> map){
    storybookID=map['storybookID'];
    status=map['status'];
    languageCode=map['languageCode'];
  }
}
