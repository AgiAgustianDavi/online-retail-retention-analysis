# Log Cleaning: Online Retail UK

**Sumber:** `Online Retail.xlsx` (tabel mentah `online_retail`, tidak diubah)
**Tabel kerja:** `data_kerja` (salinan, PostgreSQL)

## 1. Perubahan jumlah baris

| Langkah | Sebelum | Dihapus | Sesudah | Nilai baris dihapus (Quantity × UnitPrice) | Alasan |
|---|---:|---:|---:|---:|---|
| Data mentah | - | - | 541.909 | - | - |
| Hapus InvoiceNo berawalan C | 541.909 | 9.288 | 532.621 | -896.813,48 | Pembatalan atau pengembalian barang. Barisnya dibuang, jadi pembelian aslinya tetap terhitung penuh. |
| Hapus Quantity ≤ 0 atau UnitPrice ≤ 0 | 532.621 | 2.517 | 530.104 | -22.124,12 | Penyesuaian stok (damaged, found, adjustment, dll.), bukan transaksi pelanggan. |
| Hapus baris duplikat | 530.104 | 5.226 | 524.878 | ≈ 24.575* | Identik di 8 kolom, diasumsikan salah catat. |

\* Dihitung dari selisih total sebelum dan sesudah, karena nilainya tidak sempat dicatat sebelum penghapusan.

**Total dihapus:** 17.031 baris (3,1%). **Data akhir:** 524.878 baris.

## 2. Perubahan tipe data dan kolom turunan

| Kolom | Perlakuan |
|---|---|
| InvoiceDate | varchar → timestamp (format YYYY-MM-DD HH:MM:SS, semua baris valid) |
| GrossRevenue | ROUND(Quantity × UnitPrice, 2). Nilai pembelian, tidak dikurangi pembatalan. |
| MonthStart | Tanggal awal bulan dari InvoiceDate |
| CustomerOrderType | **New**: bulan baris = bulan pertama pelanggan belanja di data. **Existing**: bulan setelahnya. **Unknown**: CustomerID kosong. |

## 3. Hasil CustomerOrderType

| Tipe | Baris | Order unik | Gross revenue | Pelanggan |
|---|---:|---:|---:|---:|
| Existing | 275.835 | 13.208 | 6.642.378,29 | 2.704 |
| New | 116.857 | 5.324 | 2.244.830,59 | 4.338 |
| Unknown | 132.186 | 1.428 | 1.754.901,91 | - |
| **Total** | **524.878** | **≈ 19.960** | **10.642.110,79** | |

Unknown = 25,2% dari baris dan 16,5% dari gross revenue.

## 4. Sanity check (semua lolos)

- [x] Jumlah baris tiga tipe = 524.878
- [x] Baris Unknown = 132.186 (sesuai jumlah CustomerID kosong)
- [x] Total GrossRevenue = 10.642.110,79 = jumlah 13 bulan (selisih 4 sen dari 10.642.110,75 karena pembulatan per baris)
- [x] Pelanggan New = 4.338 = jumlah pelanggan unik
- [x] Tabel bulanan mencakup 13 bulan (Des 2010 sampai Des 2011)

## 5. Batasan dari proses cleaning

- **Revenue dihitung saat pembelian.** Pembatalan atau pengembalian barang (senilai ±897 ribu, sekitar 8% dari penjualan) tidak dikurangkan, jadi angkanya sedikit lebih tinggi dari uang yang benar-benar tersisa.
- **Duplikat diasumsikan salah catat.** Jika sebagian ternyata pembelian sah, revenue sedikit terlalu rendah (dampak ±0,2%).
- **25,2% baris tanpa CustomerID** tidak bisa diklasifikasikan new/existing (16,5% dari revenue). Kesimpulan retensi vs akuisisi hanya berlaku untuk data yang teridentifikasi.
- **Des 2010** dipakai sebagai periode pemanasan untuk menentukan New/Existing. **Des 2011** hanya 9 hari. Keduanya dikeluarkan dari perbandingan bulanan, jendela analisis Jan-Nov 2011.
- **New di awal 2011 bisa terlalu tinggi**, karena riwayat pembelian sebelum Des 2010 tidak ada di data.
- **Tidak ada data biaya atau profit.** Dampak rekomendasi hanya bisa dinyatakan dalam revenue.
