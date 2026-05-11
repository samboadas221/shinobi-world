import 'dart:async';

import 'package:flutter/material.dart';

import '../config/models/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.brand,
    required this.onFinished,
  });

  final BrandConfig brand;
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      Duration(milliseconds: (widget.brand.splashDuration * 1000).round()),
      widget.onFinished,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(widget.brand.logoAsset, width: 280),
            const SizedBox(height: 16),
            Text(
              widget.brand.companyName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
