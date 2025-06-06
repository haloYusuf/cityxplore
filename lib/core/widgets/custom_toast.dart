import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomToast extends StatefulWidget {
  final String message;
  final Duration duration;

  const CustomToast({
    super.key,
    required this.message,
    this.duration = const Duration(milliseconds: 500),
  });
  @override
  State<StatefulWidget> createState() {
    return _CustomToastState();
  }
}

class _CustomToastState extends State<CustomToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _showToast();
  }

  Future<void> _showToast() async {
    await _controller.forward();
    await Future.delayed(widget.duration);
    await _controller.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.7 * 255).round()),
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomSuccessToast(String message) {
  OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => CustomToast(message: message),
  );
  
  if (Get.overlayContext != null) {
    Navigator.of(Get.overlayContext!).push(
      _ToastRoute(overlayEntry),
    );
  }
}

class _ToastRoute extends PageRouteBuilder {
  final OverlayEntry overlayEntry;

  _ToastRoute(this.overlayEntry)
      : super(
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return overlayEntry.builder(context);
          },
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            return child;
          },
        );

  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
}
