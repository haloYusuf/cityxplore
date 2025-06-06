import 'package:cityxplore/app/modules/main/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/post_card.dart';
import '../../../data/services/auth_service.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});
  final HomeController controller = Get.put(HomeController());
  final AuthService authService = Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => controller.isSearching.value
              ? _buildSearchBar()
              : _buildAppTitle(),
        ),
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.toggleSearch,
              icon: Icon(
                controller.isSearching.value ? Icons.close : Icons.search,
                size: 24,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () {
            if (authService.currentUser == null) {
              return _buildLoginPrompt();
            } else if (controller.isLoading.value) {
              return _buildLoadingIndicator();
            } else if (controller.filteredPosts.isEmpty) {
              return _buildNoPostsMessage();
            } else {
              return _buildPostList();
            }
          },
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return const Text(
      'CityXplore',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: controller.searchController,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Cari nama tempat...',
        border: InputBorder.none,
        prefixIcon: Icon(
          Icons.search,
          color: Colors.grey,
        ),
      ),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 18,
      ),
      cursorColor: Colors.grey,
    );
  }

  Widget _buildLoginPrompt() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Silakan login untuk melihat postingan dan berinteraksi.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildNoPostsMessage() {
    return RefreshIndicator(
      onRefresh: controller.refreshPosts,
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 500,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada postingan yang tersedia.\nJadilah yang pertama berbagi!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostList() {
    return RefreshIndicator(
      onRefresh: controller.refreshPosts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.filteredPosts.length,
        itemBuilder: (context, index) {
          final post = controller.filteredPosts[index];
          final poster = controller.getUserForPost(post.uid);

          if (poster == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            child: PostCard(
              post: post,
              poster: poster,
              onItemTap: () => controller.goToPostDetail(post),
              onLocationTap: () =>
                  controller.launchGoogleMaps(post.latitude, post.longitude),
              isLiked: controller.isPostLiked(post.postId!),
              isSaved: controller.isPostSaved(post.postId!),
              onLike: () => controller.toggleLike(post),
              onSave: () => controller.toggleSave(post),
            ),
          );
        },
      ),
    );
  }
}
