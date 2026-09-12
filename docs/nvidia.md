# NVIDIA (RTX 2060 SUPER 8GB)

- Driver: NVIDIA-SMI 610.57.04, CUDA UMD 13.3 (cek: `nvidia-smi`).
- Setelah fresh install: `sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils nvidia-settings`
  (atau `nvidia-open` bila kernel mendukung), lalu reboot dan verifikasi `nvidia-smi`.
- llama.cpp: offload GPU via `-ngl 99` (lihat `scripts/start-llama-servers.sh`).
  VRAM 8GB → model Q4_K_M ≤7B nyaman; konteks besar (≥8k) bisa OOM — kecilkan `-c`.
- Build llama.cpp: `cmake -B build -DGGML_CUDA=ON && cmake --build build -j` di `~/llama.cpp`
  (source tree tidak dibackup; hanya flags ini yang penting).
- Wayland/Hyprland: bila flicker, pastikan `nvidia_drm.modeset=1` + `fbdev=1` di kernel params
  dan `env.lua` memuat variabel NVIDIA yang benar.
