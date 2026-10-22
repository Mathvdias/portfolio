import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'showcase_3d.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Scene.initializeStaticResources();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '3D Showcase',
      theme: ThemeData(useMaterial3: true),
      home: const Showcase3D(),
    );
  }
}
