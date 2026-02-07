# Dokumentasi Teknis Bloxquarium (v2 - Arsitektur yang Direvisi)

Dokumen ini menguraikan arsitektur teknis yang direvisi dari proyek Bloxquarium. Sistem ini telah difaktorkan ulang untuk meningkatkan modularitas, mengurangi ketergantungan, dan menyederhanakan alur kerja pengembangan melalui pengenalan pemuat layanan terpusat.

## Tinjauan Arsitektur

Arsitektur server yang baru berpusat pada direktori `Services` dan `ServiceLoader` terpusat. Setiap fungsionalitas inti (misalnya, data, admin, tindakan game) dienkapsulasi dalam modul Layanannya sendiri. Pemuat menangani penemuan, inisialisasi, dan injeksi dependensi, menciptakan sistem yang sangat dapat dipelihara.

- **Penyimpanan Data**: Tidak berubah. Sistem ini masih menggunakan pendekatan hibrida di mana **Firebase Realtime Database** berfungsi sebagai penyimpanan data utama, dan **Roblox DataStore** berfungsi sebagai cadangan yang kuat.
- **Struktur Layanan**: Semua layanan server sekarang berada di `game/ServerScriptService/Services`. Titik masuk server utama (`ServerInit.server.luau`) mendelegasikan semua inisialisasi ke `ServiceLoader`.
- **Manajemen Dependensi**: Ketergantungan antar layanan (seperti `RemoteService` yang dibutuhkan oleh layanan lain) dikelola melalui **Dependency Injection**. `ServiceLoader` bertanggung jawab untuk meneruskan instance layanan yang diperlukan selama inisialisasi.

---

## Komponen Inti

### 1. `ServiceLoader` (Baru)

- **Tanggung Jawab**: Merupakan inti dari arsitektur server. Ia bertanggung jawab untuk:
    1.  **Memuat Modul**: Memuat (`require`) semua modul Layanan yang ditentukan dalam urutan yang telah ditentukan sebelumnya.
    2.  **Menginisialisasi Layanan**: Memanggil metode `:Init()` pada setiap layanan dalam urutan yang benar.
    3.  **Menyuntikkan Dependensi**: Meneruskan instance layanan penting (seperti `RemoteService`) ke layanan yang bergantung padanya.
- **Alur Kerja**: `ServerInit.server.luau` memanggil `ServiceLoader:Init()` satu kali saat startup, yang memulai seluruh urutan inisialisasi server.

### 2. `ServerInit.server.luau` (Disederhanakan)

- **Tanggung Jawab**: Sekarang hanya bertindak sebagai titik masuk utama untuk server.
- **Fungsi**: Tugas utamanya adalah memuat `ServiceLoader` dan memulai proses inisialisasi. Ia juga terus menangani logika `PlayerAdded` untuk memberi tahu klien ketika dunia siap.

### 3. Modul Layanan (misalnya, `DataService`, `GameActions`, `AdminService`)

- **Tanggung Jawab**: Setiap layanan sekarang sepenuhnya mandiri dan menerima dependensinya melalui metode `Init(dependensi)`. Misalnya, `GameActions` tidak lagi memuat `RemoteService` secara langsung; sebaliknya, `ServiceLoader` meneruskannya.
- **Contoh: Pendaftaran Mandiri**:
    - `GameActions:Init(RemoteService)` menerima `RemoteService` dan menggunakannya untuk mendaftarkan *remote invokes* seperti `GameAction_BuyItem`.
    - `AdminService:Init(RemoteService)` menerima `RemoteService` dan menggunakannya untuk mendaftarkan *remote event* `RequestAdminCheck`.
    - Ini memastikan bahwa modul yang mendefinisikan suatu perilaku juga bertanggung jawab untuk mengeksposnya, bukan logika eksternal.

---

## Alur Inisialisasi Server

1.  `ServerInit.server.luau` dieksekusi saat server dimulai.
2.  Ia memuat dan memanggil `ServiceLoader:Init()`.
3.  `ServiceLoader` melintasi daftar `INIT_ORDER` yang telah ditentukan sebelumnya:
    a. Ia memuat (`require`) setiap modul Layanan.
    b. Ia memanggil metode `:Init()` pada setiap layanan, menyuntikkan `RemoteService` ke dalam `GameActions` dan `AdminService`.
4.  Setiap layanan menginisialisasi logikanya sendiri. Layanan seperti `GameActions` dan `AdminService` menggunakan instance `RemoteService` yang disediakan untuk mendaftarkan *remote events* dan *invokes* mereka.
5.  Setelah `ServiceLoader` selesai, `ServerInit` melanjutkan untuk memberi tahu pemain yang ada dan yang baru bahwa dunia siap.

## Keuntungan dari Arsitektur Baru

- **Ketergantungan Rendah**: Layanan tidak lagi terikat erat satu sama lain atau ke skrip inisialisasi pusat.
- **Pemeliharaan yang Ditingkatkan**: Menambah, menghapus, atau mengonfigurasi ulang layanan sekarang sebagian besar dilakukan di `ServiceLoader`, sehingga lebih mudah untuk mengelola proyek.
- **Dependensi yang Jelas**: Pola *dependency injection* membuat sangat jelas layanan mana yang dibutuhkan oleh yang lain.
- **Testabilitas yang Lebih Baik**: Layanan dapat diuji secara terpisah dengan lebih mudah dengan menyediakan versi tiruan dari dependensinya selama pengujian.
