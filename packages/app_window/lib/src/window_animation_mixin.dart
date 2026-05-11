import 'package:flutter/material.dart';

mixin WindowAnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProvider {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> closeWithAnimation(VoidCallback onClose) async {
    await _animController.reverse();
    if (mounted) onClose();
  }

  Widget buildAnimatedWindow(Widget child) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(opacity: _fadeAnim, child: child),
    );
  }
}
