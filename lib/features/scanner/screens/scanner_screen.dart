import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  bool _isProcessing = false;
  bool _isModelLoaded = false;

  String _result = 'Menganalisis...';
  double _confidence = 0.0;

  // Labels for the 12 categories
  final List<String> _labels = [
    'battery', 'biological', 'brown-glass', 'cardboard',
    'clothes', 'green-glass', 'metal', 'paper',
    'plastic', 'shoes', 'trash', 'white-glass'
  ];

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    await _loadModel();
    await _initCamera();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/model.tflite');
      debugPrint('✅ Model loaded successfully');
      debugPrint('Input tensors: ${_interpreter!.getInputTensors()}');
      debugPrint('Output tensors: ${_interpreter!.getOutputTensors()}');
      setState(() {
        _isModelLoaded = true;
        _result = 'Arahkan kamera ke sampah';
      });
    } catch (e) {
      debugPrint('❌ Failed to load model: $e');
      setState(() {
        _result = 'Model gagal dimuat';
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS 
            ? ImageFormatGroup.bgra8888 
            : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {});

      // Always start image stream — inference only runs if model is loaded
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isProcessing && _isModelLoaded) {
          _processCameraImage(image);
        }
      });
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _processCameraImage(CameraImage image) async {
    _isProcessing = true;
    try {
      if (_interpreter == null) return;

      img.Image? convertedImage = _convertCameraImage(image);
      if (convertedImage == null) return;

      // Resize image to 640x640 (standard YOLOv8 / Classification size)
      img.Image resizedImage = img.copyResize(convertedImage, width: 640, height: 640);

      // Convert image to Float32 array [1, 640, 640, 3]
      var input = _imageToByteListFloat32(resizedImage, 640, 0, 255.0);

      // Setup output tensor [1, 12]
      var output = List.filled(1 * 12, 0.0).reshape([1, 12]);

      // Run Inference
      _interpreter!.run(input, output);

      List<double> probabilities = (output[0] as List).cast<double>();
      
      double maxConf = 0;
      int maxIndex = -1;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxConf) {
          maxConf = probabilities[i];
          maxIndex = i;
        }
      }

      if (mounted && maxIndex != -1) {
        setState(() {
          if (maxConf > 0.4) {
            _result = _formatLabel(_labels[maxIndex]);
            _confidence = maxConf;
          } else {
            _result = 'Mencari objek...';
            _confidence = 0.0;
          }
        });
      }
    } catch (e) {
      debugPrint('Inference error: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _isProcessing = false;
    }
  }

  String _formatLabel(String raw) {
    final map = {
      'battery': 'Baterai (B3)',
      'biological': 'Biologis / Organik',
      'brown-glass': 'Kaca Cokelat',
      'cardboard': 'Kardus',
      'clothes': 'Pakaian',
      'green-glass': 'Kaca Hijau',
      'metal': 'Logam / Kaleng',
      'paper': 'Kertas',
      'plastic': 'Plastik',
      'shoes': 'Sepatu',
      'trash': 'Sampah Residu',
      'white-glass': 'Kaca Putih'
    };
    return map[raw] ?? raw;
  }

  // --- Image Processing Utilities ---

  img.Image? _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToImage(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToImage(image);
    }
    return null;
  }

  img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final img.Image finalImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      int pY = y * image.planes[0].bytesPerRow;
      int pUV = (y >> 1) * uvRowStride;

      for (int x = 0; x < width; x++) {
        int uvOffset = pUV + (x >> 1) * uvPixelStride;

        final yp = image.planes[0].bytes[pY + x];
        final up = image.planes[1].bytes[uvOffset];
        final vp = image.planes[2].bytes[uvOffset];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        finalImage.setPixelRgb(x, y, r, g, b);
      }
    }
    return finalImage;
  }

  List<double> _imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.toList();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Background
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // Dimmer
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // Scanner Frame
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),
                  ],
                ),
              ),
            ),
          ),

          // App Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Deteksi Sampah',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Warning if model not found
          if (!_isModelLoaded)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Model ML belum diatur. Masukkan model.tflite ke folder assets/ml/',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Bottom Info Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Objek Terdeteksi:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: _confidence > 0 ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_confidence > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Akurasi: ${(_confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight) 
                ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight) 
                ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) 
                ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight) 
                ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
