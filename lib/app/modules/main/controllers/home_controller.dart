import 'package:cityxplore/app/routes/route_name.dart';
import 'package:cityxplore/core/widgets/custom_toast.dart';
import 'package:cityxplore/core/widgets/error_dialog.dart';
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
    
    debounce(searchQuery, (_) => filterPosts(), time: const Duration(milliseconds: 300));
    ever(posts, (_) => filterPosts());

    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });

    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (v) {
        showCustomSuccessToast('Memuat Ulang Postingan');
        refreshPosts();
      },
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      minimumShakeCount: 1,
    );
  }

  @override
  void onClose() {
    _shakeDetector?.stopListening();
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchPostsAndUsers() async {
    final currentUserUid = _authService.currentUser?.uid;
    if (currentUserUid == null) {
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
      
      final Map<int, User> tempUsersCache = {};
      final Set<int> uniqueUserIds = allPosts.map((post) => post.uid).toSet();
      for (var uid in uniqueUserIds) {
        final user = await _dbHelper.getUserById(uid);
        if (user != null) {
          tempUsersCache[uid] = user;
        }
      }
      usersCache.assignAll(tempUsersCache);

      final Map<int, bool> tempLikedPosts = {};
      final Map<int, bool> tempSavedPosts = {};
      final List<Future<void>> futures = [];

      for (var post in allPosts) {
        if (post.postId != null) {
          futures.add(_dbHelper.isPostLikedByUser(currentUserUid, post.postId!)
              .then((isLiked) => tempLikedPosts[post.postId!] = isLiked));
          futures.add(_dbHelper.isPostSavedByUser(currentUserUid, post.postId!)
              .then((isSaved) => tempSavedPosts[post.postId!] = isSaved));
        }
      }
      await Future.wait(futures);

      likedPosts.assignAll(tempLikedPosts);
      savedPosts.assignAll(tempSavedPosts);

    } catch (e) {
      showErrorMessage(
        'Gagal memuat data postingan dan pengguna: $e',
        title: 'Error Data',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterPosts() {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) {
      filteredPosts.assignAll(posts);
    } else {
      filteredPosts.assignAll(
        posts.where((post) {
          return post.postTitle.toLowerCase().contains(query) ||
                 post.postDesc.toLowerCase().contains(query) ||
                 post.detailLoc.toLowerCase().contains(query);
        }).toList(),
      );
    }
  }

  Future<void> refreshPosts() async {
    isLoading.value = true;
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
    final currentUserUid = _authService.currentUser?.uid;
    if (currentUserUid == null || post.postId == null) {
      showErrorMessage(
        'Anda harus login untuk menyukai postingan.',
        title: 'Autentikasi Diperlukan',
      );
      return;
    }

    final postId = post.postId!;

    final bool currentlyLiked = isPostLiked(postId);
    likedPosts[postId] = !currentlyLiked;
    likedPosts.refresh();

    try {
      if (currentlyLiked) {
        await _dbHelper.removeLike(currentUserUid, postId);
      } else {
        await _dbHelper.addLike(
          Like(uid: currentUserUid, postId: postId),
        );
      }
    } catch (e) {
      likedPosts[postId] = currentlyLiked;
      likedPosts.refresh();
      showErrorMessage(
        'Gagal mengubah status suka: $e',
        title: 'Error Suka',
      );
    }
  }

  Future<void> toggleSave(Post post) async {
    final currentUserUid = _authService.currentUser?.uid;
    if (currentUserUid == null || post.postId == null) {
      showErrorMessage(
        'Anda harus login untuk menyimpan postingan.',
        title: 'Autentikasi Diperlukan',
      );
      return;
    }

    final postId = post.postId!;
    
    final bool currentlySaved = isPostSaved(postId);
    savedPosts[postId] = !currentlySaved;
    savedPosts.refresh();

    try {
      if (currentlySaved) {
        await _dbHelper.removeSaved(currentUserUid, postId);
      } else {
        await _dbHelper.addSaved(
          Saved(uid: currentUserUid, postId: postId),
        );
      }
    } catch (e) {
      savedPosts[postId] = currentlySaved;
      savedPosts.refresh();
      showErrorMessage(
        'Gagal mengubah status simpan: $e',
        title: 'Error Simpan',
      );
    }
  }

  Future<void> launchGoogleMaps(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      showErrorMessage(
        'Tidak dapat membuka Google Maps. Pastikan aplikasi Google Maps terinstal atau browser dapat diakses.',
        title: 'Error Google Maps',
      );
    }
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchController.clear();
      searchQuery.value = ''; 
      filterPosts();
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    filterPosts();
  }

  void goToPostDetail(Post post) {
    Get.toNamed(RouteName.detailPost, arguments: post);
  }

  void logout() {
    _authService.logout();
    Get.offAllNamed(RouteName.login);
  }
}