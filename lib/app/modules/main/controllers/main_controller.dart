import 'package:cityxplore/app/modules/main/views/home_view.dart';
import 'package:cityxplore/app/modules/main/views/info_view.dart';
import 'package:cityxplore/app/modules/main/views/post_view.dart';
import 'package:cityxplore/app/modules/main/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainController extends GetxController {
  final _currentIndex = 0.obs;

  final List<Widget Function({Key? key})> _pageFactories = [
    ({Key? key}) => HomeView(key: key),
    ({Key? key}) => PostView(key: key),
    ({Key? key}) => InfoView(key: key),
    ({Key? key}) => ProfileView(key: key),
  ];

  final Map<int, int> _viewKeys = {
    0: 0,
    1: 0,
    2: 0,
    3: 0,
  }.obs;

  int getCurrentIndex() {
    return _currentIndex.value;
  }

  Widget getCurrentPage() {
    final int index = _currentIndex.value;
    return _pageFactories[index](key: ValueKey(_viewKeys[index]));
  }

  void setCurrentIndex(int index) {
    if (_currentIndex.value != index) {
      _currentIndex.value = index;
      _viewKeys[index] = (_viewKeys[index] ?? 0) + 1;
    }
  }
}
