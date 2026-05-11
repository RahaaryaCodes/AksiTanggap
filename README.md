# 🏥 AksiTanggap (SurviveNet)
**AI-Powered Offline First Aid Assistant**

AksiTanggap adalah aplikasi *mobile* berbasis Flutter yang dirancang untuk memberikan panduan pertolongan pertama (P3K) secara cepat dan akurat menggunakan kecerdasan buatan. Aplikasi ini mampu mendeteksi jenis luka melalui kamera secara **100% offline**, menjadikannya sangat berguna di daerah bencana atau lokasi dengan akses internet terbatas.

## 🚀 Fitur Utama
* **Real-time Wound Scanning**: Mendeteksi jenis luka (Luka Bakar, Pendarahan, Memar) secara instan melalui kamera.
* **Offline AI Inference**: Menggunakan model TensorFlow Lite (CNN) yang berjalan langsung di perangkat tanpa butuh koneksi internet (Privacy-focused).
* **Smart Thresholding**: Sistem hanya akan memberikan diagnosa jika tingkat keyakinan AI di atas 70% untuk meminimalisir *false positive*.
* **First Aid Guidance**: Memberikan instruksi penanganan medis darurat berdasarkan jenis luka yang terdeteksi.
* **Cross-Platform Ready**: Dibangun menggunakan Flutter, siap untuk dideploy di Android (dan iOS dengan penyesuaian build).

## 🧠 Detail Model AI
Model ini dibangun menggunakan arsitektur **Convolutional Neural Network (CNN)** yang dilatih untuk mengenali 4 klasifikasi utama:
1.  **Luka Bakar**
2.  **Luka Terbuka (Pendarahan)**
3.  **Memar**
4.  **Normal (Kulit Sehat)**

### Performa Model (Metrics)
Berdasarkan pengujian pada *test set*, model mencapai hasil sebagai berikut:
* **Akurasi Keseluruhan**: 89%
* **Recall (Pendarahan)**: 98% (Sangat krusial untuk deteksi luka berbahaya)
* **F1-Score**: 0.89

| Kategori | Precision | Recall | F1-Score |
| :--- | :---: | :---: | :---: |
| Luka Bakar | 0.96 | 0.86 | 0.91 |
| Pendarahan | 0.81 | 0.98 | 0.89 |
| Memar | 0.93 | 0.76 | 0.84 |
| Normal | 0.92 | 0.94 | 0.93 |

## 🛠️ Tech Stack
* **Framework**: [Flutter](https://flutter.dev/)
* **Bahasa Pemrograman**: [Dart](https://dart.dev/)
* **Machine Learning**: [TensorFlow Lite](https://www.tensorflow.org/lite)
* **Image Processing**: `camera`, `tflite_flutter`

## 📦 Instalasi
1.  **Clone Repositori**
    ```bash
    git clone https://github.com/username/aksi_tanggap.git
    cd aksi_tanggap
    ```
2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```
3.  **Setup Assets**
    Pastikan file model `model.tflite` dan `labels.txt` sudah ada di folder `assets/`.
4.  **Jalankan Aplikasi**
    ```bash
    flutter run
    ```

## ⚠️ Disclaimer
Aplikasi ini ditujukan sebagai alat bantu edukasi dan pertolongan pertama awal. Hasil deteksi AI sangat dipengaruhi oleh kualitas kamera dan pencahayaan. Selalu hubungi layanan medis darurat atau dokter untuk penanganan luka yang serius.

---
Dikembangkan oleh **Arya Budi Raharja** sebagai bagian dari Capstone Project / Hackathon 2026.
