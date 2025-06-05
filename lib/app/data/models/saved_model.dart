class Saved {
  int uid;
  int postId;

  Saved({
    required this.uid,
    required this.postId,
  });

  factory Saved.fromMap(Map<String, dynamic> map) {
    return Saved(
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
