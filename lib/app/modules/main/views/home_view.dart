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
              ? TextField(
                  controller: controller.searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari nama tempat...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                  cursorColor: Colors.grey,
                )
              : const Text(
                  'CityXplore',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        actions: [
          Obx(
            () => controller.isSearching.value
                ? IconButton(
                    onPressed: controller.toggleSearch,
                    icon: const Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.grey,
                    ),
                  )
                : IconButton(
                    onPressed: controller.toggleSearch,
                    icon: const Icon(
                      Icons.search,
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
              return const Center(
                child: Text(
                  'Silakan login untuk melihat postingan.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                if (controller.filteredPosts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.refreshPosts,
                    child: const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 500,
                        child: Center(
                          child: Text(
                            'Postingan masih kosong!',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
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
                            onItemTap: () => controller.goToPostDetail(
                              post,
                            ),
                            onLocationTap: () => controller.launchGoogleMaps(
                              post.latitude,
                              post.longitude,
                            ),
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
            }
          },
        ),
      ),
    );
  }
}
