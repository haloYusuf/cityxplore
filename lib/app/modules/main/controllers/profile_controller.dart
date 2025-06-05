import 'dart:io'; // Untuk File
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/services/auth_service.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'package:cityxplore/app/routes/route_name.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Dependencies
  final AuthService _authService = Get.find<AuthService>();
  final DbHelper _dbHelper = Get.find<DbHelper>();

  final RxInt _selectedTabIndex = 0.obs;
  int get selectedTabIndex => _selectedTabIndex.value;

  late TabController tabController;

  final RxString userName = 'Guest'.obs;
  final RxString userHandle = '@guest'.obs;
  final Rx<File?> profilePhotoFile = Rx<File?>(null);
  final RxInt postsCount = 0.obs;

  final RxList<Post> posts = <Post>[].obs;
  final RxList<Post> savedItems = <Post>[].obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    tabController.addListener(() {
      _selectedTabIndex.value = tabController.index;
    });

    // ever(_authService.currentUser!, (_) {
    //   _updateProfileData();
    //   fetchPosts();
    //   fetchSavedItems();
    // });

    _updateProfileData();
    fetchPosts();
    fetchSavedItems();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _updateProfileData() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      userName.value = currentUser.username;
      userHandle.value =
          '@${currentUser.username.replaceAll(' ', '').toLowerCase()}';
      profilePhotoFile.value = currentUser.photoFile;
    } else {
      userName.value = 'Guest';
      userHandle.value = '@guest';
      profilePhotoFile.value = null;
      posts.clear();
      savedItems.clear();
    }
  }

  File? getProfileImagePath() {
    return profilePhotoFile.value;
  }

  String getDisplayName() {
    return userName.value;
  }

  String getDisplayHandle() {
    return userHandle.value;
  }

  Future<void> fetchPosts() async {
    final currentUserUid = _authService.currentUser?.uid;
    if (currentUserUid == null) {
      posts.clear();
      postsCount.value = 0;
      return;
    }

    try {
      final userPosts = await _dbHelper.getPostsByUserId(currentUserUid);
      posts.assignAll(userPosts);
      postsCount.value = userPosts.length;
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat postingan: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> fetchSavedItems() async {
    final currentUserUid = _authService.currentUser?.uid;
    if (currentUserUid == null) {
      savedItems.clear();
      return;
    }

    print('Fetching saved items for current user: $currentUserUid...');
    try {
      final userSavedItems =
          await _dbHelper.getSavedPostsByUserId(currentUserUid);
      savedItems.assignAll(userSavedItems);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat item tersimpan: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void onEditProfileTap() {
    Get.snackbar('Info', 'Tombol Edit Profil ditekan!');
    // Get.toNamed(Routes.EDIT);
  }

  Future<void> deletePost(Post post) async {
    if (post.postId == null) {
      Get.snackbar('Error', 'Post ID tidak valid.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final bool? confirm = await Get.defaultDialog<bool>(
      title: 'Hapus Postingan',
      middleText: 'Apakah Anda yakin ingin menghapus postingan "${post.postTitle}" ini?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.black,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back(result: true);
      },
      onCancel: () {
        Get.back(result: false);
      },
    );

    if (confirm == true) {
      try {
        final int deletedRows = await _dbHelper.deletePost(post.postId!);
        if (deletedRows > 0) {
          Get.snackbar('Sukses', 'Postingan berhasil dihapus!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
          fetchPosts();
          fetchSavedItems();
        } else {
          Get.snackbar('Error', 'Gagal menghapus postingan.', snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        Get.snackbar('Error', 'Terjadi kesalahan saat menghapus: $e', snackPosition: SnackPosition.BOTTOM);
        print('Error deleting post: $e');
      }
    }
  }

  void logout() {
    _authService.logout();
    Get.offAllNamed(RouteName.login);
  }
}
