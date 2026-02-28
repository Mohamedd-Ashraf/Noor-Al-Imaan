"""
Adhan Cutoff Analyzer
=====================
Interactive waveform + spectrogram viewer for all adhan sounds.

Controls
--------
  Click on the waveform  → moves the green marker + prints the timestamp
  Spacebar               → plays audio from the green marker position
  P                      → plays audio from the beginning
  S                      → stops playback
  Left/Right arrows      → nudge marker ±0.1 s
  Ctrl + Left/Right      → nudge marker ±1 s

Usage
-----
  python tool/adhan_analyzer.py                    # menu to pick a sound
  python tool/adhan_analyzer.py adhan_1            # open specific sound directly
  python tool/adhan_analyzer.py online_afasy_fajr  # online sound (downloads once)

Requirements
------------
  pip install librosa matplotlib sounddevice requests numpy scipy
"""

import sys
import os
import pathlib
import urllib.request
import shutil
import threading

import numpy as np
import matplotlib
matplotlib.use("TkAgg")          # works on Windows without extra config
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.colors import LogNorm
import librosa
import librosa.display
import sounddevice as sd

# ─── Sound definitions ────────────────────────────────────────────────────────

SCRIPT_DIR   = pathlib.Path(__file__).parent
REPO_ROOT    = SCRIPT_DIR.parent
RAW_DIR      = REPO_ROOT / "android" / "app" / "src" / "main" / "res" / "raw"
DOWNLOAD_DIR = SCRIPT_DIR / "_adhan_cache"
DOWNLOAD_DIR.mkdir(exist_ok=True)

BASE_URL = "https://archive.org/download/adhan.notifications/"

SOUNDS = [
    # ── local ──────────────────────────────────────────────────────────────────
    {
        "id":          "adhan_1",
        "label":       "أذان المسجد الحرام (مكة) — محلي",
        "local":       RAW_DIR / "adhan_1.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_2",
        "label":       "أذان محلي 2",
        "local":       RAW_DIR / "adhan_2.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_3",
        "label":       "أذان محلي 3",
        "local":       RAW_DIR / "adhan_3.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_4",
        "label":       "أذان محلي 4",
        "local":       RAW_DIR / "adhan_4.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_5",
        "label":       "أذان محلي 5",
        "local":       RAW_DIR / "adhan_5.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_6",
        "label":       "أذان محلي 6",
        "local":       RAW_DIR / "adhan_6.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_7",
        "label":       "أذان محلي 7",
        "local":       RAW_DIR / "adhan_7.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_8",
        "label":       "أذان محلي 8",
        "local":       RAW_DIR / "adhan_8.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_9",
        "label":       "أذان محلي 9",
        "local":       RAW_DIR / "adhan_9.mp3",
        "cutoff":      13,
    },
    {
        "id":          "adhan_10",
        "label":       "أذان محلي 10",
        "local":       RAW_DIR / "adhan_10.mp3",
        "cutoff":      13,
    },
    # ── online ─────────────────────────────────────────────────────────────────
    {
        "id":          "online_ahmed_imadi",
        "label":       "Ahmed Al-Imadi — Qatar",
        "url":         BASE_URL + "Ahmed_al_Imadi_Adhan.mp3",
        "cutoff":      13,
    },
    {
        "id":          "online_majed_hamathani",
        "label":       "Majed Al-Hamathani — Saudi Arabia",
        "url":         BASE_URL + "Majed_al_Hamathani_Adhan.mp3",
        "cutoff":      12,
    },
    {
        "id":          "online_afasy_fajr",
        "label":       "Mishary Al-Afasy (Fajr) — Kuwait",
        "url":         BASE_URL + "Mishary_Rashid_al_Afasy_Fajr_Adhan.mp3",
        "cutoff":      15,
    },
    {
        "id":          "online_mokhtar_slimane",
        "label":       "Mokhtar Hadj Slimane — Algeria",
        "url":         BASE_URL + "Mokhtar_Hadj_Slimane_Adhan.mp3",
        "cutoff":      13,
    },
    {
        "id":          "online_nasser_qatami",
        "label":       "Nasser Al-Qatami Adhan",
        "url":         BASE_URL + "Nasser_al_Qatami_Adhan.mp3",
        "cutoff":      13,
    },
    {
        "id":          "online_ahmed_imadi_dua",
        "label":       "Ahmed Al-Imadi Adhan + Dua",
        "url":         BASE_URL + "Ahmed_al_Imadi_Adhan_with_Dua.mp3",
        "cutoff":      14,
    },
    {
        "id":          "online_majed_hamathani_dua",
        "label":       "Majed Al-Hamathani Adhan + Dua",
        "url":         BASE_URL + "Majed_al_Hamathani_Adhan_with_Dua.mp3",
        "cutoff":      13,
    },
    {
        "id":          "online_nasser_qatami_dua",
        "label":       "Nasser Al-Qatami Adhan + Dua",
        "url":         BASE_URL + "Nasser_al_Qatami_Adhan_with_Dua.mp3",
        "cutoff":      14,
    },
]

SOUND_BY_ID = {s["id"]: s for s in SOUNDS}

# ─── Audio helpers ────────────────────────────────────────────────────────────

def resolve_path(sound: dict) -> pathlib.Path:
    if "local" in sound:
        p = pathlib.Path(sound["local"])
        if not p.exists():
            raise FileNotFoundError(f"Local sound not found: {p}")
        return p
    # Online → download once to cache
    cache_path = DOWNLOAD_DIR / f"{sound['id']}.mp3"
    if not cache_path.exists():
        url = sound["url"]
        print(f"  Downloading {url}…")
        with urllib.request.urlopen(url, timeout=30) as r, open(cache_path, "wb") as f:
            shutil.copyfileobj(r, f)
        print(f"  Saved to {cache_path}")
    return cache_path


def load_audio(path: pathlib.Path):
    """Return (y, sr) — mono, native sample rate."""
    y, sr = librosa.load(str(path), sr=None, mono=True)
    return y, sr

# ─── Playback ────────────────────────────────────────────────────────────────

_play_thread: threading.Thread | None = None
_stop_flag = threading.Event()


def play_from(y: np.ndarray, sr: int, start_s: float):
    global _play_thread
    stop_audio()
    _stop_flag.clear()
    start_sample = int(start_s * sr)
    chunk = y[start_sample:]

    def _worker():
        sd.play(chunk, sr)
        while sd.get_stream().active:
            if _stop_flag.is_set():
                sd.stop()
                return
            sd.sleep(50)

    _play_thread = threading.Thread(target=_worker, daemon=True)
    _play_thread.start()


def stop_audio():
    _stop_flag.set()
    sd.stop()

# ─── Plotting ────────────────────────────────────────────────────────────────

MARKER_COLOR   = "#00e676"   # bright green
CUTOFF_COLOR   = "#ff5252"   # red
FAINT_GRID     = "#333333"
BG_COLOR       = "#1a1a2e"
AX_COLOR       = "#16213e"
TEXT_COLOR      = "#e0e0e0"
WAVE_COLOR     = "#82b1ff"

plt.rcParams.update({
    "figure.facecolor":  BG_COLOR,
    "axes.facecolor":    AX_COLOR,
    "axes.edgecolor":    "#444",
    "axes.labelcolor":   TEXT_COLOR,
    "axes.titlecolor":   TEXT_COLOR,
    "xtick.color":       TEXT_COLOR,
    "ytick.color":       TEXT_COLOR,
    "text.color":        TEXT_COLOR,
    "grid.color":        FAINT_GRID,
    "grid.linestyle":    "--",
    "grid.linewidth":    0.5,
})


def open_analyzer(sound: dict):
    path = resolve_path(sound)
    print(f"\nLoading {path.name}…  (may take a moment for long files)")
    y, sr = load_audio(path)
    duration = len(y) / sr

    fig = plt.figure(figsize=(16, 8), tight_layout=True)
    fig.patch.set_facecolor(BG_COLOR)
    fig.canvas.manager.set_window_title(f"Adhan Analyzer — {sound['id']}")

    gs = gridspec.GridSpec(3, 1, figure=fig, height_ratios=[2, 2, 1], hspace=0.35)
    ax_wave   = fig.add_subplot(gs[0])
    ax_spec   = fig.add_subplot(gs[1])
    ax_energy = fig.add_subplot(gs[2])

    # ── Waveform ──────────────────────────────────────────────────────────────
    times = np.linspace(0, duration, len(y))
    ax_wave.plot(times, y, color=WAVE_COLOR, linewidth=0.4, alpha=0.9)
    ax_wave.set_xlim(0, duration)
    ax_wave.set_ylabel("Amplitude")
    ax_wave.set_title(f"{sound['label']}  |  {duration:.1f} s total", fontsize=12)
    ax_wave.grid(True)
    ax_wave.axvline(sound["cutoff"], color=CUTOFF_COLOR,
                    linewidth=1.5, linestyle="--", label=f"Current cutoff ({sound['cutoff']} s)")
    wave_marker = ax_wave.axvline(sound["cutoff"], color=MARKER_COLOR,
                                  linewidth=2.0, linestyle="-", alpha=0.9, label="Your marker")
    wave_text   = ax_wave.text(sound["cutoff"] + 0.2, 0.85, f"{sound['cutoff']:.2f}s",
                               transform=ax_wave.get_xaxis_transform(),
                               color=MARKER_COLOR, fontsize=10, fontweight="bold")
    ax_wave.legend(loc="upper right", fontsize=9,
                   facecolor="#0d0d1a", edgecolor="#555", labelcolor=TEXT_COLOR)

    # ── Spectrogram ───────────────────────────────────────────────────────────
    # Use mel spectrogram for a perceptually meaningful view
    hop   = 512
    S     = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=128, hop_length=hop)
    S_db  = librosa.power_to_db(S, ref=np.max)
    img   = librosa.display.specshow(S_db, sr=sr, hop_length=hop,
                                     x_axis="time", y_axis="mel",
                                     ax=ax_spec, cmap="magma")
    ax_spec.set_title("Mel Spectrogram", fontsize=10)
    ax_spec.set_xlim(0, duration)
    spec_marker = ax_spec.axvline(sound["cutoff"], color=MARKER_COLOR,
                                  linewidth=2.0, linestyle="-", alpha=0.9)
    ax_spec.axvline(sound["cutoff"], color=CUTOFF_COLOR,
                    linewidth=1.5, linestyle="--", alpha=0.6)

    # ── RMS Energy (easier to spot takbeer boundaries) ─────────────────────────
    rms   = librosa.feature.rms(y=y, hop_length=hop)[0]
    rms_t = librosa.times_like(rms, sr=sr, hop_length=hop)
    ax_energy.fill_between(rms_t, rms, alpha=0.7, color="#ffab40")
    ax_energy.set_xlim(0, duration)
    ax_energy.set_xlabel("Time (seconds)")
    ax_energy.set_ylabel("RMS Energy", fontsize=9)
    ax_energy.set_title("RMS Energy — takbeer onsets appear as peaks", fontsize=9)
    ax_energy.grid(True)
    energy_marker = ax_energy.axvline(sound["cutoff"], color=MARKER_COLOR,
                                      linewidth=2.0, linestyle="-", alpha=0.9)

    # ── Second-by-second grid ─────────────────────────────────────────────────
    for ax in (ax_wave, ax_energy):
        for s in range(int(duration) + 1):
            ax.axvline(s, color="#2a2a4a", linewidth=0.5, zorder=0)

    # ── State ─────────────────────────────────────────────────────────────────
    state = {"marker": float(sound["cutoff"])}

    def _update_marker(t: float):
        t = max(0.0, min(t, duration))
        state["marker"] = round(t, 2)
        for line in (wave_marker, spec_marker, energy_marker):
            line.set_xdata([t, t])
        wave_text.set_x(t + 0.15)
        wave_text.set_text(f"{t:.2f} s")
        fig.canvas.draw_idle()
        print(f"\r  ► Marker: {t:.2f} s   (press S to stop, Space to play from here)", end="", flush=True)

    # ── Click handler ─────────────────────────────────────────────────────────
    def _on_click(event):
        if event.inaxes in (ax_wave, ax_spec, ax_energy) and event.xdata is not None:
            _update_marker(event.xdata)

    # ── Key handler ───────────────────────────────────────────────────────────
    def _on_key(event):
        if event.key == " ":
            play_from(y, sr, state["marker"])
        elif event.key == "p":
            play_from(y, sr, 0.0)
        elif event.key == "s":
            stop_audio()
        elif event.key == "right":
            _update_marker(state["marker"] + 0.1)
        elif event.key == "left":
            _update_marker(state["marker"] - 0.1)
        elif event.key == "ctrl+right":
            _update_marker(state["marker"] + 1.0)
        elif event.key == "ctrl+left":
            _update_marker(state["marker"] - 1.0)
        elif event.key == "q":
            plt.close(fig)

    fig.canvas.mpl_connect("button_press_event", _on_click)
    fig.canvas.mpl_connect("key_press_event",    _on_key)

    # ── Help text ─────────────────────────────────────────────────────────────
    help_lines = [
        "Click → move marker  |  Space → play from marker  |  P → play from start",
        "S → stop  |  ←/→ nudge ±0.1 s  |  Ctrl+←/→ nudge ±1 s  |  Q → close",
    ]
    fig.text(0.5, 0.005, "   ".join(help_lines),
             ha="center", va="bottom", fontsize=8.5, color="#888",
             transform=fig.transFigure)

    plt.colorbar(img, ax=ax_spec, format="%+2.0f dB", pad=0.01)
    plt.show()
    stop_audio()
    final = state["marker"]
    print(f"\n\n  Final marker for '{sound['id']}': {final:.2f} s")
    print(f"  → shortDurationSeconds: {int(np.ceil(final))}")
    return final

# ─── CLI ─────────────────────────────────────────────────────────────────────

def print_menu():
    print("\n╔══════════════════════════════════════════════════╗")
    print("║          Adhan Cutoff Analyzer                  ║")
    print("╚══════════════════════════════════════════════════╝\n")
    for i, s in enumerate(SOUNDS):
        marker = " ✓" if (pathlib.Path(s.get("local", DOWNLOAD_DIR / f"{s['id']}.mp3"))).exists() else ""
        print(f"  [{i+1:2d}] {s['id']:<35}  cutoff={s['cutoff']} s{marker}")
    print(f"\n  [ 0] Quit\n")


def main():
    if len(sys.argv) > 1:
        sid = sys.argv[1]
        if sid not in SOUND_BY_ID:
            print(f"Unknown sound id: {sid}")
            print("Available:", ", ".join(SOUND_BY_ID))
            sys.exit(1)
        open_analyzer(SOUND_BY_ID[sid])
        return

    while True:
        print_menu()
        try:
            choice = input("  Choose [1-{0}] or 0 to quit: ".format(len(SOUNDS))).strip()
        except (EOFError, KeyboardInterrupt):
            break
        if choice == "0" or choice.lower() == "q":
            break
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(SOUNDS):
                open_analyzer(SOUNDS[idx])
            else:
                print("  Invalid choice.")
        except ValueError:
            # Maybe they typed an id directly
            if choice in SOUND_BY_ID:
                open_analyzer(SOUND_BY_ID[choice])
            else:
                print("  Invalid choice.")


if __name__ == "__main__":
    main()
