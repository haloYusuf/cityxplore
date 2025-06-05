import 'package:cityxplore/app/routes/route_name.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cityxplore/app/data/services/auth_service.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:cityxplore/app/data/models/like_model.dart';
import 'package:cityxplore/app/data/models/saved_model.dart';
import 'package:shake/shake.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DbHelper _dbHelper = Get.find<DbHelper>();

  final RxList<Post> posts = <Post>[].obs;
  final RxList<Post> filteredPosts = <Post>[].obs;
  final RxMap<int, User> usersCache = <int, User>{}.obs;
  final RxMap<int, bool> likedPosts = <int, bool>{}.obs;
  final RxMap<int, bool> savedPosts = <int, bool>{}.obs;
  final isLoading = false.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  ShakeDetector? _shakeDetector;

  @override
  void onInit() {
    super.onInit();
    fetchPostsAndUsers();
    // ever(_authService.currentUser, (_) => fetchPostsAndUsers());
    ever(posts, (_) => filterPosts());
    ever(searchQuery, (_) => filterPosts());

    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (v) { 
        Get.snackbar('Informasi', 'Memuat ulang postingan...', snackPosition: SnackPosition.TOP);
        refreshPosts();
      },
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      minimumShakeCount: 1,
    );
  }

  Future<void> fetchPostsAndUsers() async {
    if (_authService.currentUser == null) {
      posts.clear();
      usersCache.clear();
      likedPosts.clear();
      savedPosts.clear();
      return;
    }

    isLoading.value = true;
    try {
      final allPosts = await _dbHelper.getAllPosts();
      posts.assignAll(allPosts);

      usersCache.clear();
      likedPosts.clear();
      savedPosts.clear();

      for (var post in allPosts) {
        if (!usersCache.containsKey(post.uid)) {
          final user = await _dbHelper.getUserById(post.uid);
          if (user != null) {
            usersCache[post.uid] = user;
          }
        }

        if (post.postId != null) {
          final isLiked = await _dbHelper.isPostLikedByUser(
              _authService.currentUser!.uid!, post.postId!);
          likedPosts[post.postId!] = isLiked;
          final isSaved = await _dbHelper.isPostSavedByUser(
              _authService.currentUser!.uid!, post.postId!);
          savedPosts[post.postId!] = isSaved;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    _shakeDetector?.stopListening();
    searchController.dispose();
    super.onClose();
  }

  void filterPosts() {
    if (searchQuery.value.isEmpty) {
      filteredPosts.assignAll(posts);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredPosts.assignAll(
        posts
            .where((post) => post.postTitle.toLowerCase().contains(query))
            .toList(),
      );
    }
  }

  Future<void> refreshPosts() async {
    await fetchPostsAndUsers();
  }

  User? getUserForPost(int uid) {
    return usersCache[uid];
  }

  bool isPostLiked(int postId) {
    return likedPosts[postId] ?? false;
  }

  bool isPostSaved(int postId) {
    return savedPosts[postId] ?? false;
  }

  Future<void> toggleLike(Post post) async {
    if (_authService.currentUser == null || post.postId == null) {
      Get.snackbar('Perhatian', 'Anda harus login untuk menyukai postingan.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final currentUid = _authService.currentUser!.uid!;
    final postId = post.postId!;

    if (isPostLiked(postId)) {
      await _dbHelper.removeLike(currentUid, postId);
      likedPosts[postId] = false;
    } else {
      await _dbHelper.addLike(
        Like(uid: currentUid, postId: postId),
      );
      likedPosts[postId] = true;

      likedPosts.refresh();
    }
  }

  Future<void> toggleSave(Post post) async {
    if (_authService.currentUser == null || post.postId == null) {
      Get.snackbar(
        'Perhatian',
        'Anda harus login untuk menyimpan postingan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final currentUid = _authService.currentUser!.uid!;
    final postId = post.postId!;

    if (isPostSaved(postId)) {
      await _dbHelper.removeSaved(currentUid, postId);
      savedPosts[postId] = false;
    } else {
      await _dbHelper.addSaved(
        Saved(
          uid: currentUid,
          postId: postId,
        ),
      );
      savedPosts[postId] = true;
    }

    savedPosts.refresh();
  }

  Future<void> launchGoogleMaps(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://maps.google.com/?q=$latitude,$longitude',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      Get.snackbar(
        'Error',
        'Tidak dapat membuka Google Maps. Pastikan aplikasi Google Maps terinstal atau browser dapat diakses.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchController.clear();
      searchQuery.value = '';
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void goToPostDetail(Post post) {
    Get.toNamed(RouteName.detailPost, arguments: post);
  }

  void logout() {
    _authService.logout();
    Get.offAllNamed(RouteName.login);
  }
}
