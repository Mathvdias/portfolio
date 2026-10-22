import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class Showcase3D extends StatefulWidget {
  const Showcase3D({super.key});

  @override
  State<Showcase3D> createState() => _Showcase3DState();
}

class _Showcase3DState extends State<Showcase3D> {
  String _currentModel = 'assets/models/sennamp4.glb';

  void _changeModel(String newModel) {
    if (_currentModel != newModel) {
      setState(() {
        _currentModel = newModel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Galeria 3D', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _changeModel('assets/models/sennamp4.glb'),
                  style: ElevatedButton.styleFrom(backgroundColor: _currentModel.contains('senna') ? Colors.red : Colors.grey[800]),
                  child: const Text('McLaren MP4/5 (106MB)', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _changeModel('assets/models/dash.glb'),
                  style: ElevatedButton.styleFrom(backgroundColor: _currentModel.contains('dash') ? Colors.blue : Colors.grey[800]),
                  child: const Text('Flutter Dash (4MB)', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A2A35), Color(0xFF101015)],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: _SceneViewer(key: ValueKey(_currentModel), modelPath: _currentModel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneViewer extends StatefulWidget {
  final String modelPath;
  const _SceneViewer({super.key, required this.modelPath});

  @override
  State<_SceneViewer> createState() => _SceneViewerState();
}

class _SceneViewerState extends State<_SceneViewer> {
  late final OrbitCameraController _orbit;
  bool _isLoading = true;
  EnvironmentMap? _hdri;

  final _shadowCatcher = ShadowCatcherMaterial(
    mode: ShadowCatcherMode.baked,
    softness: 0.5,
    aoStrength: 0.3,
    fadeStart: 1.0,
    fadeEnd: 3.5,
  );

  @override
  void initState() {
    super.initState();
    _orbit = OrbitCameraController(
      azimuth: -0.5,
      minDistance: 1.5,
      maxDistance: 8,
    )..frame(
        vm.Aabb3.minMax(
          vm.Vector3(-0.9, 0.01, -2.11),
          vm.Vector3(0.9, 1.19, 2.11),
        ),
        margin: 1.1,
      );

    // Carrega o HDRI realista de estúdio
    EnvironmentMap.fromEquirectImageAsset(assetPath: 'assets/models/studio.hdr').then((env) {
      if (mounted) {
        setState(() {
          _hdri = env;
        });
      }
    });
  }

  void _onModelLoaded(Node modelRoot) {
    for (final node in modelRoot.meshNodes) {
      node.shadowStatic = true;
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camada 3D nativa
        CameraControls(
          controller: _orbit,
          autofocus: false,
          child: SceneView.declarative(
            autoTick: true,
            pixelRatio: 2.0,
            environment: _hdri ?? EnvironmentMap.studio(),
            environmentIntensity: 1.5,
            toneMapping: ToneMappingMode.aces,
            children: [
              SceneNode(components: [CameraComponent(), _orbit]),
              SceneNode(
                components: [
                  DirectionalLightComponent.aimed(
                    DirectionalLight(
                      intensity: 2.5,
                      castsShadow: true,
                      shadowCascadeCount: 2,
                      shadowMaxDistance: 15,
                      shadowFilter: DirectionalShadowFilter.bilinearPcf,
                    ),
                    vm.Vector3(-0.8, -1.0, 0.2),
                  ),
                ],
              ),
              SceneMesh(
                position: vm.Vector3(0, 0, 0),
                geometry: PlaneGeometry(width: 10.0, depth: 10.0),
                material: _shadowCatcher,
              ),
              SceneModel(widget.modelPath, onLoaded: _onModelLoaded),
            ],
          ),
        ),

        // Camada 2D Animada de Carregamento (Glassmorphism)
        IgnorePointer(
          ignoring: !_isLoading,
          child: AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.redAccent,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.modelPath.contains('senna')
                            ? 'INJETANDO 106MB NA GPU...'
                            : 'MONTANDO DASH...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Renderizando PBR e reflexos (HDRI)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
