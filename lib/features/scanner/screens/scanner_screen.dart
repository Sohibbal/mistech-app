import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

// Top-level function untuk dijalankan di dalam Isolate (Compute)
List<double> _processImage(Uint8List imageBytes) {
  // 1. Decode gambar
  img.Image? originalImage = img.decodeImage(imageBytes);
  if (originalImage == null) throw Exception("Gagal decode gambar");

  // 2. Resize ke 224x224 sesuai dengan input model
  img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

  // 3. Konversi ke Float32List
  int inputSize = 224;
  double mean = 127.5; // Keras/Teachable Machine defaults
  double std = 127.5;

  var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (int i = 0; i < inputSize; i++) {
    for (int j = 0; j < inputSize; j++) {
      var pixel = resizedImage.getPixel(j, i);
      buffer[pixelIndex++] = (pixel.r - mean) / std;
      buffer[pixelIndex++] = (pixel.g - mean) / std;
      buffer[pixelIndex++] = (pixel.b - mean) / std;
    }
  }
  return convertedBytes.toList();
}

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
  File? _capturedImage;

  String _result = 'Arahkan kamera ke sampah';
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
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _takePictureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing || !_isModelLoaded) return;

    setState(() {
      _isProcessing = true;
      _result = 'Memproses...';
    });

    try {
      // 1. Ambil foto
      final XFile file = await _cameraController!.takePicture();
      final File imageFile = File(file.path);

      setState(() {
        _capturedImage = imageFile;
      });

      // 2. Decode, resize, dan konversi gambar di Isolate terpisah agar UI tidak freeze
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Jalankan proses berat di background thread (Isolate)
      final List<double> inputList = await compute(_processImage, imageBytes);
      var input = inputList.reshape([1, 224, 224, 3]);

      // 3. Setup output tensor
      var output = List.filled(1 * 12, 0.0).reshape([1, 12]);

      // 4. Jalankan inferensi
      _interpreter!.run(input, output);

      // 6. Ambil hasil probabilitas tertinggi
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
            _result = 'Objek tidak dikenali';
            _confidence = 0.0;
          }
        });
      }
    } catch (e) {
      debugPrint('Inference error: $e');
      if (mounted) {
        setState(() {
          _result = 'Terjadi kesalahan';
          _confidence = 0.0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatLabel(String raw) {
    final map = {
      'battery': 'Anorganik',
      'biological': 'Organik',
      'brown-glass': 'Anorganik',
      'cardboard': 'Organik',
      'clothes': 'Organik',
      'green-glass': 'Anorganik',
      'metal': 'Anorganik',
      'paper': 'Organik',
      'plastic': 'Anorganik',
      'shoes': 'Anorganik',
      'trash': 'Organik',
      'white-glass': 'Anorganik'
    };
    return map[raw] ?? raw;
  }



  void _resetScanner() {
    setState(() {
      _capturedImage = null;
      _result = 'Arahkan kamera ke sampah';
      _confidence = 0.0;
    });
  }

  @override
  void dispose() {
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
          // 1. Background (Camera or Captured Image)
          if (_capturedImage != null)
            Positioned.fill(
              child: Image.file(_capturedImage!, fit: BoxFit.cover),
            )
          else if (_cameraController != null && _cameraController!.value.isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // 2. Dimmer
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // 3. Scanner Frame (only if not captured yet)
          if (_capturedImage == null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85, // Diperbesar jadi 85% lebar layar
                  height: MediaQuery.of(context).size.width * 0.85,
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

          // 4. App Bar
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

          // 5. Warning if model not found
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
                  'Model ML belum dimuat. Periksa file model.tflite',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // 6. Processing Indicator
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Memproses gambar...',
                        style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 7. Bottom Controls (Capture button OR Result Card)
          if (_capturedImage == null) ...[
            // Capture Button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: (_isProcessing || !_isModelLoaded) ? null : _takePictureAndProcess,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: (_isProcessing || !_isModelLoaded) ? Colors.grey : AppColors.primary,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            // Text hint
            Positioned(
              bottom: 130,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Posisikan sampah di dalam bingkai',
                    style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Result Card
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetScanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Scan Ulang',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
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

