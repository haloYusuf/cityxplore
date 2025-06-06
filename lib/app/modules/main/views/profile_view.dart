import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/modules/main/controllers/profile_controller.dart';
import 'package:cityxplore/app/routes/route_name.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.logout,
            icon: const Icon(
              Icons.logout_rounded,
              size: 24,
              color: Colors.grey,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProfileInfoSection(),
          Divider(height: 1, color: Colors.grey[300]),
          _buildTabBarSection(),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                Obx(() => _buildPostsGrid(controller.posts, isUserPosts: true)),
                Obx(() =>
                    _buildPostsGrid(controller.savedItems, isUserPosts: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Obx(
        () => Column(
          children: [
            _buildProfileImage(),
            const SizedBox(height: 12),
            Text(
              controller.getDisplayName(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              controller.getDisplayHandle(),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.onEditProfileTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: controller.profilePhotoFile.value != null
          ? Image.file(
              controller.profilePhotoFile.value!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildProfileImagePlaceholder();
              },
            )
          : _buildProfileImagePlaceholder(),
    );
  }

  Widget _buildProfileImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.blue.withAlpha((0.2 * 255).round()),
      child: const Icon(
        Icons.person,
        size: 70,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildTabBarSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: controller.tabController,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                icon: Obx(
                  () => Icon(
                    Icons.grid_on,
                    color: controller.selectedTabIndex == 0
                        ? Colors.blue
                        : Colors.grey[700],
                  ),
                ),
                text: 'Posts',
              ),
              Tab(
                icon: Obx(
                  () => Icon(
                    Icons.bookmark_border,
                    color: controller.selectedTabIndex == 1
                        ? Colors.blue
                        : Colors.grey[700],
                  ),
                ),
                text: 'Saved',
              ),
            ],
          ),
          Divider(
            height: 1,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(RxList<Post> items, {required bool isUserPosts}) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh:
            isUserPosts ? controller.fetchPosts : controller.fetchSavedItems,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: Get.height * 0.5,
            child: Center(
              child: Text(
                isUserPosts
                    ? 'Belum ada postingan Anda.'
                    : 'Belum ada item tersimpan.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          isUserPosts ? controller.fetchPosts : controller.fetchSavedItems,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(1.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final post = items[index];
          return GestureDetector(
            onTap: () {
              Get.toNamed(RouteName.detailPost, arguments: post);
            },
            child: Stack(
              children: [
                Container(
                  color: Colors.grey[200],
                  child: post.postImageFile != null
                      ? Image.file(
                          post.postImageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              post.postTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
                if (isUserPosts)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => controller.deletePost(post),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
