import 'dart:io';

class Post {
  int? postId;
  int uid;
  double latitude;
  double longitude;
  String detailLoc;
  String postTitle;
  String postDesc;
  double postPrice;
  String? postImage;
  DateTime createdAt;

  Post({
    this.postId,
    required this.uid,
    required this.latitude,
    required this.longitude,
    required this.detailLoc,
    required this.postTitle,
    required this.postDesc,
    required this.postPrice,
    this.postImage,
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      postId: map['postId'],
      uid: map['uid'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      detailLoc: map['detailLoc'],
      postTitle: map['postTitle'],
      postDesc: map['postDesc'],
      postPrice: map['postPrice'],
      postImage: map['postImage'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'uid': uid,
      'latitude': latitude,
      'longitude': longitude,
      'detailLoc': detailLoc,
      'postTitle': postTitle,
      'postDesc': postDesc,
      'postPrice': postPrice,
      'postImage': postImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  File? get postImageFile => postImage != null ? File(postImage!) : null;
}
