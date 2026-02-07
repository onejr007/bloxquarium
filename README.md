# Dokumentasi Teknis Bloxquarium

Dokumen ini menguraikan arsitektur teknis proyek Bloxquarium. Sistem ini dirancang untuk ketahanan dan skalabilitas, menampilkan model penyimpanan data hibrida dan alur manajemen aset yang kuat.

## Tinjauan Arsitektur

Arsitektur server dibangun di sekitar serangkaian layanan modular yang masing-masing menangani tanggung jawab tertentu. Logika inti berkisar pada pemuatan, pengelolaan, dan penyimpanan data pemain dan aset game.

- **Penyimpanan Data**: Sistem menggunakan pendekatan hibrida. **Firebase Realtime Database** adalah penyimpanan data utama, sedangkan **Roblox DataStore** berfungsi sebagai cadangan yang andal.
- **Manajemen Aset**: Aset game dikelola melalui alur sinkronisasi klien-server untuk memastikan bahwa pemain hanya memuat apa yang mereka butuhkan, saat mereka membutuhkannya.
- **Komunikasi**: Klien dan server berkomunikasi melalui `RemoteClient` dan `RemoteServer` (tidak dianalisis secara langsung tetapi diinferensikan), yang memfasilitasi pengambilan data dan aset.

---

## Layanan & Modul Utama

### 1. `DataService` (v3.3)

- **Tanggung Jawab**: Merupakan pusat utama untuk semua data pemain. Layanan ini mengelola cache data sesi pemain, menangani logika pemuatan/penyimpanan, dan menyediakan API untuk layanan lain untuk berinteraksi dengan data pemain.
- **Fitur Utama**:
    - **Pemuatan Hibrida**: Mencoba memuat data dari `FirebaseService` terlebih dahulu, dan jika gagal, beralih ke `DatabaseService` (DataStore).
    - **Cache Sesi**: Menyimpan data semua pemain yang sedang online dalam tabel Lua untuk akses cepat.
    - **Perbaikan Panel Admin (v3.3)**: Menyertakan fungsi `UpdatePlayerData` yang penting untuk memungkinkan admin mengedit data pemain tanpa menimpa seluruh catatan mereka, memperbaiki kerusakan server sebelumnya.

### 2. `FirebaseService` (v2.1)

- **Tanggung Jawab**: Pembungkus tingkat rendah untuk panggilan API REST Firebase Realtime Database. Ini mengabstraksi permintaan HTTP `GET` (mengambil) dan `PUT` (menyimpan).
- **Konteks Historis (v2.1)**: Versi ini berisi penambahan *debugging* yang signifikan, yang menunjukkan bahwa masalah pemuatan data dari Firebase adalah masalah kritis di masa lalu. Layanan ini sekarang stabil tetapi mempertahankan log ini untuk diagnostik.

### 3. `DatabaseService` (v1.2)

- **Tanggung Jawab**: Pembungkus yang stabil dan andal untuk `DataStoreService` Roblox.
- **Fitur Utama**:
    - **API CRUD Dasar**: Menyediakan fungsi `Create`, `Read`, `Update`, dan `Delete`.
    - **Penanganan Error yang Benar**: Komentar menekankan bahwa layanan ini dengan benar mengembalikan pasangan `success, result`, menjadikannya fondasi yang dapat diandalkan untuk `DataService`.

### 4. `AssetManagerV3` (v3.2 - Klien)

- **Tanggung Jawab**: Mengelola, mem-preload, dan menyediakan akses ke semua aset game di sisi klien.
- **Fitur Utama**:
    - **Sinkronisasi Server**: Saat memulai, ia meminta daftar aset lengkap dari server.
    - **Preloading Kritis**: Secara khusus mem-preload aset yang terdaftar di `CriticalAssetNames` (dari `asset_config`) sebelum mengizinkan game untuk melanjutkan, memastikan aset UI/suara penting tersedia segera.
    - **Perbaikan Struktur (v3.2)**: Memperbaiki bug kritis di mana manajer salah membaca tabel aset, yang menyebabkan kegagalan preloading.

### 5. `asset_config.luau` (v2 - Server)

- **Tanggung Jawab**: Sumber kebenaran tunggal untuk semua definisi aset di server.
- **Fitur Utama**:
    - **Daftar Aset Terpusat**: Mendefinisikan ID untuk semua gambar, suara, model, dll.
    - **Daftar Preload Eksplisit**: Berisi tabel `CriticalAssetNames` yang secara eksplisit memberitahu `AssetManagerV3` aset mana yang harus dimuat saat startup.
    - **Perbaikan Struktur (v2)**: Direstrukturisasi untuk menghindari penimpaan kunci Lua, yang sebelumnya menyebabkan daftar aset yang tidak lengkap dikirim ke klien.

---

## Alur Data

### Alur Pemuatan Data Pemain (Saat Bergabung)

1.  Pemain bergabung dengan game.
2.  `DataService` dipicu.
3.  `DataService` memanggil `FirebaseService.GetPlayerDataAsync`.
    - **Jika Berhasil**: Data dimuat ke dalam `sessionCache`. Cadangan di `DataStore` diperbarui.
    - **Jika Gagal**: `DataService` memanggil `DatabaseService.Read` untuk mencoba memuat dari cadangan DataStore.
        - **Jika Berhasil (Cadangan)**: Data dimuat ke dalam `sessionCache`.
        - **Jika Gagal (Cadangan)**: `DataService` membuat data pemain default baru (`getDefaultPlayerData`) dan menyimpannya di `sessionCache`. Cadangan awal dibuat di `DataStore`.
4.  Acara `StateUpdated` diaktifkan, memberi sinyal kepada bagian lain dari game (seperti UI) bahwa data pemain siap.

### Alur Pemuatan Aset (Saat Klien Memulai)

1.  Klien memulai dan menginisialisasi `AssetManagerV3`.
2.  `AssetManagerV3` memanggil `RemoteClient:InvokeServer("GetAssetRegistry")`.
3.  Server merespons dengan seluruh tabel konfigurasi dari `asset_config.luau`.
4.  `AssetManagerV3` mengurai tabel ini, mendaftarkan semua aset, dan mengidentifikasi aset penting dari daftar `CriticalAssetNames`.
5.  Fungsi `preloadInitialAsync` dipanggil, menggunakan `ContentProvider:PreloadAsync` pada semua aset penting.
6.  `AssetManager.PreloadComplete` diaktifkan, memberi sinyal pada layar pemuatan untuk selesai.
