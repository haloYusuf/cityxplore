class Like {
  int uid;
  int postId;

  Like({
    required this.uid,
    required this.postId,
  });

  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      uid: map['uid'],
      postId: map['postId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'postId': postId,
    };
  }
}
