import 'dart:io'; // Untuk File
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:cityxplore/app/data/services/auth_service.dart';
import 'package:cityxplore/app/data/services/db_helper.dart';
import 'package:cityxplore/app/routes/route_name.dart';
import 'package:cityxplore/core/widgets/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AuthService _authService = Get.find<AuthService>();
  final DbHelper _dbHelper = Get.find<DbHelper>();

  final RxInt _selectedTabIndex = 0.obs;
  int get selectedTabIndex => _selectedTabIndex.value;

  late TabController tabController;

  final RxString userName = 'Guest'.obs;
  final RxString userHandle = '@guest'.obs;
  final Rx<File?> profilePhotoFile = Rx<File?>(null);

  final RxList<Post> posts = <Post>[].obs;
  final RxList<Post> savedItems = <Post>[].obs;

  final TextEditingController editUsernameController = TextEditingController();
  final Rx<File?> newProfilePhoto = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    tabController.addListener(() {
      _selectedTabIndex.value = tabController.index;
    });
    ever(_authService.currentUserRx, (User? user) {
      _updateProfileData(user);
      fetchPosts();
      fetchSavedItems();
    });
    _updateProfileData(_authService.currentUser);
    fetchPosts();
    fetchSavedItems();
  }

  @override
  void onClose() {
    tabController.dispose();
    editUsernameController.dispose();
    newProfilePhoto.value = null;
    super.onClose();
  }

  void _updateProfileData(User? user) {
    if (user != null) {
      userName.value = user.username;
      userHandle.value = '@${user.username.replaceAll(' ', '').toLowerCase()}';
      profilePhotoFile.value = user.photoFile;
    } else {
      userName.value = 'Guest';
      userHandle.value = '@guest';
      profilePhotoFile.value = null;
      posts.clear();
      savedItems.clear();
    }
    update();
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
      return;
    }

    try {
      final userPosts = await _dbHelper.getPostsByUserId(currentUserUid);
      posts.assignAll(userPosts);
    } catch (e) {
      showErrorMessage(
        'Gagal memuat postingan: $e',
        title: 'Error Memuat Postingan',
      );
    }
  }

  Future<void> fetchSavedItems() async {
    final currentUserUid = _authService.currentUser?.uid;
    if (currentUserUid == null) {
      savedItems.clear();
      return;
    }

    try {
      final userSavedItems =
          await _dbHelper.getSavedPostsByUserId(currentUserUid);
      savedItems.assignAll(userSavedItems);
    } catch (e) {
      showErrorMessage(
        'Gagal memuat item tersimpan: $e',
        title: 'Error Item Tersimpan',
      );
    }
  }

  Future<void> deletePost(Post post) async {
    if (post.postId == null) {
      showErrorMessage('Post ID tidak valid.', title: 'Error Hapus');
      return;
    }

    final bool? confirm = await Get.defaultDialog<bool>(
      title: 'Hapus Postingan',
      middleText:
          'Apakah Anda yakin ingin menghapus postingan "${post.postTitle}" ini?',
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
          Get.snackbar(
            'Sukses',
            'Postingan berhasil dihapus!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          fetchPosts();
        } else {
          showErrorMessage('Gagal menghapus postingan.', title: 'Gagal Hapus');
        }
      } catch (e) {
        showErrorMessage(
          'Terjadi kesalahan saat menghapus: $e',
          title: 'Error Hapus',
        );
      }
    }
  }

  Future<void> pickNewProfilePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      newProfilePhoto.value = File(pickedFile.path);
    }
  }

  void showEditProfileDialog() {
    editUsernameController.text = userName.value;
    newProfilePhoto.value = profilePhotoFile.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profil'),
        content: Obx(
          () => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: pickNewProfilePhoto,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: newProfilePhoto.value != null
                        ? FileImage(newProfilePhoto.value!)
                        : null,
                    child: newProfilePhoto.value == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey[700],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await updateProfile();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> updateProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.uid == null) {
      showErrorMessage('Anda tidak login.', title: 'Autentikasi Diperlukan');
      return;
    }

    final String newUsername = editUsernameController.text.trim();
    if (newUsername.isEmpty) {
      showErrorMessage('Username tidak boleh kosong.', title: 'Validasi Input');
      return;
    }

    if (newUsername != currentUser.username) {
      final existingUser = await _dbHelper.getUserByUsername(newUsername);
      if (existingUser != null && existingUser.uid != currentUser.uid) {
        showErrorMessage(
          'Username sudah digunakan oleh pengguna lain.',
          title: 'Username Tidak Tersedia',
        );
        return;
      }
    }

    String? photoPathToSave = currentUser.photoPath;

    if (newProfilePhoto.value != null &&
        newProfilePhoto.value!.path != (currentUser.photoFile?.path ?? '')) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final String fileName = p.basename(newProfilePhoto.value!.path);
        final String newPath = p.join(appDir.path, fileName);
        final File savedFile = await newProfilePhoto.value!.copy(newPath);
        photoPathToSave = savedFile.path;

        if (currentUser.photoPath != null &&
            currentUser.photoPath != photoPathToSave) {
          final oldFile = File(currentUser.photoPath!);
          if (oldFile.existsSync()) {
            await oldFile.delete();
          }
        }
      } catch (e) {
        showErrorMessage(
          'Gagal menyimpan foto profil baru: $e',
          title: 'Error Foto Profil',
        );
        return;
      }
    } else if (newProfilePhoto.value == null && currentUser.photoPath != null) {
      photoPathToSave = null;
      final oldFile = File(currentUser.photoPath!);
      if (oldFile.existsSync()) {
        await oldFile.delete();
      }
    }

    final updatedUser = User(
      uid: currentUser.uid,
      username: newUsername,
      email: currentUser.email,
      password: currentUser.password,
      photoPath: photoPathToSave,
      createdAt: currentUser.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      final int rowsAffected = await _dbHelper.updateUser(updatedUser);
      if (rowsAffected > 0) {
        _authService.updateCurrentUser(updatedUser);
        Get.snackbar(
          'Sukses',
          'Profil berhasil diperbarui!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        showErrorMessage(
          'Gagal memperbarui profil. Tidak ada perubahan yang disimpan.',
          title: 'Gagal Perbarui',
        );
      }
    } catch (e) {
      showErrorMessage(
        'Terjadi kesalahan saat memperbarui profil: $e',
        title: 'Error Perbarui Profil',
      );
    }
  }

  void onEditProfileTap() {
    showEditProfileDialog();
  }

  void logout() {
    _authService.logout();
    Get.offAllNamed(RouteName.login);
  }
}
