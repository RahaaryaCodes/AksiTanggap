import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const SurviveNetApp());
}

class SurviveNetApp extends StatelessWidget {
  const SurviveNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AksiTanggap (SurviveNet)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false; // Mencegah user pencet tombol berkali-kali

  Interpreter? _interpreter;
  List<String>? _labels;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadAIModel();
  }

  // 1. Memuat Otak AI dan Label
  Future<void> _loadAIModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      String labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((e) => e.trim()).where((label) => label.isNotEmpty).toList();
      print("AI Model berhasil dimuat!");

      // Tambahan: Notifikasi Hijau kalau sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sistem AI Siap Digunakan!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      print("Gagal memuat AI: $e");

      // Tambahan: Alarm Merah kalau gagal muat file
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error Sistem AI: $e"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 10), // Tampil lebih lama agar bisa dibaca
            )
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras != null && cameras!.isNotEmpty) {
      _cameraController = CameraController(
        cameras![0],
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // 2. Fungsi Utama: Jepret -> Proses AI -> Tampilkan Hasil
  Future<void> _scanWound() async {
    if (_interpreter == null || _labels == null || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tunggu sebentar, AI atau Kamera belum siap!"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // a. Jepret Foto
      XFile file = await _cameraController!.takePicture();

      // b. Ubah ukuran gambar jadi 150x150 (Khusus Model CNN)
      img.Image? rawImage = img.decodeImage(File(file.path).readAsBytesSync());
      img.Image resizedImage = img.copyResize(rawImage!, width: 150, height: 150);

      // c. Konversi piksel (KODE BARU - CNN 1/255)
      var input = List.generate(1, (i) => List.generate(150, (y) => List.generate(150, (x) => List.generate(3, (c) => 0.0))));
      for (int y = 0; y < 150; y++) {
        for (int x = 0; x < 150; x++) {
          img.Pixel pixel = resizedImage.getPixel(x, y);
          // RUMUS CNN (Aman dari korslet NaN)
          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }
      // d. Jalankan AI (Inference)
      var output = List.generate(1, (i) => List.filled(_labels!.length, 0.0));
      _interpreter!.run(input, output);

      // e. Cari hasil persentase tertinggi
      List<double> probabilities = output[0];
      int highestIndex = 0;
      double highestProb = probabilities[0];

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > highestProb) {
          highestProb = probabilities[i];
          highestIndex = i;
        }
      }

      // f. Tampilkan Hasil (Dengan Filter Threshold 70%)
      String detectedWound = _labels![highestIndex];
      double confidencePercent = highestProb * 100;

      if (confidencePercent < 70.0) {
        // Jika AI ragu-ragu (di bawah 70%)
        _showResultDialog("Gambar Kurang Jelas", "0.0");
      } else {
        // Jika AI yakin (di atas 70%)
        String confidence = confidencePercent.toStringAsFixed(1);
        _showResultDialog(detectedWound, confidence);
      }

    } catch (e) {
      print("Error saat scan: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("AI Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultDialog(String woundType, String confidence) {
    showDialog(
      context: context,
      barrierDismissible: false, // User harus pilih tombol, tidak bisa klik sembarang tempat
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
              woundType == 'Normal' ? "Aman" : "Peringatan Medis!",
              style: TextStyle(
                color: woundType == 'Normal' ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.bold,
              )
          ),
          content: Text(
            "Hasil: $woundType\nKeyakinan AI: $confidence%",
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
            ),
            // Tombol ini HANYA MUNCUL jika AI mendeteksi Luka (bukan Normal)
            if (woundType != 'Normal')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup popup dulu
                  // Pindah ke halaman Panduan P3K
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FirstAidScreen(woundType: woundType),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.medical_services, color: Colors.white),
                label: const Text("PANDUAN DARURAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        title: const Text('AksiTanggap - Pindai Luka', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[800],
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: CameraPreview(_cameraController!),
              ),
            )
                : const Center(child: CircularProgressIndicator(color: Colors.red)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0, left: 20, right: 20),
            child: SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton.icon(
                // Tombol akan mati (null) jika AI sedang memproses agar tidak error
                onPressed: _isProcessing ? null : _scanWound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
                icon: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.document_scanner, size: 30, color: Colors.white),
                label: Text(
                  _isProcessing ? 'MEMPROSES...' : 'SCAN LUKA SEKARANG',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN PANDUAN PERTOLONGAN PERTAMA (P3K)
// ==========================================
class FirstAidScreen extends StatelessWidget {
  final String woundType;

  const FirstAidScreen({super.key, required this.woundType});

  @override
  Widget build(BuildContext context) {
    String title = "Panduan P3K";
    List<String> steps = [];

    // Logika Konten Offline Berdasarkan Jenis Luka
    if (woundType == 'Luka Terbuka_Pendarahan') {
      title = "Pendarahan & Luka Terbuka";
      steps = [
        "1. JANGAN PANIK. Cuci tangan Anda dengan air bersih jika memungkinkan.",
        "2. TEKAN KUAT area yang berdarah dengan kain bersih atau kasa steril selama 5-10 menit tanpa henti.",
        "3. TINGGIKAN bagian tubuh yang terluka hingga posisinya lebih tinggi dari jantung untuk mengurangi aliran darah.",
        "4. JANGAN LEPAS kain pertama meskipun darah merembes. Tumpuk saja dengan kain baru di atasnya agar gumpalan darah pembeku tidak rusak.",
        "5. Jika pendarahan tidak berhenti setelah 15 menit, segera cari bantuan medis evakuasi."
      ];
    } else if (woundType == 'Luka Bakar') {
      title = "Penanganan Luka Bakar";
      steps = [
        "1. JAUHKAN korban dari sumber panas atau api secepat mungkin.",
        "2. ALIRKAN AIR BIASA (bukan es) ke area luka bakar selama 10-20 menit untuk mendinginkan jaringan kulit.",
        "3. JANGAN OLESI odol, mentega, atau kecap! Ini bisa memicu infeksi parah.",
        "4. JANGAN PECAHKAN gelembung air yang muncul di kulit.",
        "5. Tutup perlahan dengan plastik wrap bersih atau kasa steril yang longgar."
      ];
    } else if (woundType == 'Memar') {
      title = "Penanganan Memar (Benturan)";
      steps = [
        "1. ISTIRAHATKAN area tubuh yang mengalami memar atau benturan.",
        "2. KOMPRES DINGIN menggunakan es yang dibalut handuk (jangan tempel es langsung ke kulit) selama 15-20 menit.",
        "3. Ulangi kompres dingin setiap 2-3 jam selama dua hari pertama.",
        "4. Posisikan area yang memar lebih tinggi dari dada untuk mengurangi pembengkakan.",
        "5. Jika memar disertai rasa sakit luar biasa atau bentuk tulang tidak wajar, curigai adanya patah tulang dan bidai (ikat dengan kayu kaku)."
      ];
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "TINDAKAN DARURAT OFFLINE",
                    style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Ikuti langkah berikut secara berurutan:",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(10),
                        border: Border(left: BorderSide(color: Colors.redAccent, width: 4)),
                  ),
                  child: Text(
                  steps[index],
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}