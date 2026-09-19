# corex-zones

> Safe zones — no damage, no weapons, no PvP.

Part of the [COREX Framework](https://github.com/ABUGIZA/COREX-Framework).

## Install

Drop the `corex-zones` folder into:
```
server-file/resources/[corex]/corex-zones/
```

Zones are now defined as **polygons** (via [PolyZone](https://github.com/mkafrin/PolyZone)) instead of circles/radius, so PolyZone is a hard dependency. Make sure it loads before `corex-zones`, after `corex-core`:
```cfg
ensure corex-core
ensure PolyZone
ensure ox_lib
ensure corex-zones
```

## Membuat polyzone dengan freecam

Editor mengikuti alur pembuat zona `ps-realtor` yang dipakai `ps-housing`.
Tambahkan urutan resource dan izin admin berikut di `server.cfg`:

```cfg
ensure ox_lib
ensure fivem-freecam
ensure corex-zones
add_ace group.admin command.czcreate allow
```

`corex-core` dan `PolyZone` tetap harus berjalan sebelum `corex-zones`.
Pastikan akun admin sudah tergabung dalam `group.admin` (atau ganti dengan grup ACE server).
`fivem-freecam` hanya diperlukan saat memakai editor. Salinan lokalnya memuat
`@garuda-ac/modules/init.lua`, sehingga dependency tersebut juga harus tersedia.

1. Pergi ke lokasi zona, lalu jalankan `/czcreate Nama Safe Zone`.
2. Gerakkan freecam dan arahkan penunjuk ke permukaan bangunan/tanah.
3. Tekan **C** untuk menambahkan sudut secara berurutan mengelilingi area.
   Arahkan ke titik yang sudah ada (penunjuk merah) dan tekan **C** untuk menghapusnya.
4. Arahkan ke titik, tekan **K**, arahkan ke posisi baru, lalu tekan **K** lagi.
   **N** membatalkan pemilihan edit.
5. Gunakan **scroll** untuk mengubah tinggi zona (minimal 0,5 meter).
   Preview menampilkan batas bawah dari titik terendah dan batas atas dari titik tertinggi + tinggi.
6. Tekan **H** untuk menyelesaikan. Minimal tiga titik, area tidak boleh nol,
   dan garis tidak boleh saling berpotongan. Hasil Lua disalin ke clipboard dan dicetak di F8.
7. Tempel blok hasil ke tabel `Config.SafeZones` di `config.lua`, lalu `restart corex-zones`.

**Backspace** atau `/czcancel` membatalkan editor. Hasil belum menjadi safe zone aktif
sebelum dimasukkan ke konfigurasi dan resource direstart. Shortcut C/K dapat diubah
melalui pengaturan key bindings FiveM dengan label COREX Zones.

Client exports: `IsCoordsInSafeZone(coords)` returns membership and the matching zone config. `GetSafeZoneDistance(coords)` returns the shortest distance in meters to any safe-zone polygon volume: `0` inside or on its boundary, polygon-edge distance outside its footprint, and height distance beyond `minZ`/`maxZ` (combined geometrically when outside both). Missing height bounds are unbounded on that side. Invalid coordinates or no usable zones return `math.huge`. This keeps zombie spawn buffers and population distance thresholds working with polygon zones.

## Update

Download the latest release ZIP from the **Releases** tab and replace the folder.

## Docs
📖 <https://corex-zombies.gitbook.io/corex-docs/resources/world/corex-zones>

## Community
💬 <https://discord.gg/G95rtnb9sg>

## License
Released under the [MIT License](LICENSE).
