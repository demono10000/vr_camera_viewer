import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])
      .then((_) {
    runApp(const VRCameraApp());
  });
}

class VRCameraApp extends StatelessWidget {
  const VRCameraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VR Camera Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const maxSliderValue = 100.0;

  List<CameraDescription>? cameras;
  CameraController? controller;
  CameraDescription? selectedCamera;
  double xOffset = 50.0;
  bool showInfoDialog = true;

  @override
  void initState() {
    super.initState();
    // enable fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras!.isNotEmpty) {
        setState(() {
          selectedCamera = cameras![0];
          _initCameraController(selectedCamera!);
        });
      }
    }).catchError((error) {
      print("Error initializing camera: $error");
    });
  }

  void _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((error) {
      print("Error initializing camera controller: $error");
    });
  }

  void _switchCamera() {
    if (cameras != null) {
      int currentIndex = cameras!.indexOf(selectedCamera!);
      CameraDescription nextCamera;
      if (currentIndex + 1 < cameras!.length) {
        nextCamera = cameras![currentIndex + 1];
      } else {
        nextCamera = cameras![0];
      }
      setState(() {
        selectedCamera = nextCamera;
      });
      _initCameraController(nextCamera);
    }
  }

  void _showCameraInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Information"),
          content: const Text("Tap the camera preview to switch between available cameras."),
          actions: [
            TextButton(
              child: const Text("Understood"),
              onPressed: () {
                setState(() {
                  showInfoDialog = false;
                });
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showInfoDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCameraInfoDialog(context));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // show middle of the screen
          Positioned(
            top: 0,
            bottom: 0,
            left: MediaQuery.of(context).size.width / 2 - 1,
            child: Container(
              width: 2,
              color: Colors.white,
            ),
          ),
          // Slider for camera offset
          Positioned(
            top: -5,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: xOffset,
                    activeColor: const Color.fromARGB(100, 115, 115, 115),
                    inactiveColor: const Color.fromARGB(100, 115, 115, 115),
                    onChanged: (newValue) {
                      setState(() {
                        xOffset = newValue;
                      });
                    },
                    min: 0,
                    max: maxSliderValue,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  xOffset.toStringAsFixed(2),
                  style: const TextStyle(color: Color.fromARGB(
                      216, 115, 115, 115), fontSize: 16),
                ),
              ],
            ),
          ),
          // Camera preview
          Center(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _switchCamera,
                    child: ClipRect(
                      child: Transform.translate(
                        offset: Offset(xOffset, 0),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: CameraPreview(controller!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _switchCamera,
                    child: ClipRect(
                      child: Transform.translate(
                        offset: Offset(-xOffset, 0),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: CameraPreview(controller!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
