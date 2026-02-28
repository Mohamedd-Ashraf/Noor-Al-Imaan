"""
Auto-detect the short-cutoff timestamp for every adhan MP3.

Algorithm
---------
1. Load audio with librosa (native sample rate, mono)
2. Compute onset envelope
3. Pick onset peaks → these are the Takbeer boundaries
4. The cutoff = start of the 3rd Takbeer onset – 0.3 s
   (cuts in the silence BETWEEN 2nd and 3rd Takbeer)
5. If fewer than 3 onsets detected, fall back to a safe default

Usage
-----
  python tool/detect_cutoffs.py          # all local files
  python tool/detect_cutoffs.py adhan_1  # single file
"""

import sys
import pathlib
import numpy as np

try:
    import librosa
    import scipy.signal
except ImportError:
    print("Run: pip install librosa scipy numpy")
    sys.exit(1)

REPO_ROOT = pathlib.Path(__file__).parent.parent
RAW_DIR   = REPO_ROOT / "android" / "app" / "src" / "main" / "res" / "raw"

# Default safe fallback if algorithm can't find 3 peaks
DEFAULT_CUTOFF = 20

# Known ground-truth override (from visual inspection)
GROUND_TRUTH = {
    "adhan_1": 20.5,   # confirmed by user from spectrogram
}


def detect_cutoff(mp3_path: pathlib.Path, verbose: bool = True) -> float:
    """Return the recommended shortDurationSeconds cutoff for this file."""
    y, sr = librosa.load(str(mp3_path), sr=None, mono=True)
    duration = len(y) / sr

    if verbose:
        print(f"  duration: {duration:.1f} s")

    # ── Onset detection ────────────────────────────────────────────────────────
    hop = 512
    onset_env = librosa.onset.onset_strength(y=y, sr=sr, hop_length=hop)

    # peak_pick params tuned for adhan: peaks ~3-6 s apart, high amplitude
    peaks = librosa.util.peak_pick(
        onset_env,
        pre_max=3,
        post_max=3,
        pre_avg=5,
        post_avg=5,
        delta=0.1,
        wait=int(sr / hop * 2.0),  # min 2 s between peaks
    )

    peak_times = librosa.frames_to_time(peaks, sr=sr, hop_length=hop)

    if verbose:
        print(f"  detected onsets: {[f'{t:.2f}' for t in peak_times]}")

    if len(peak_times) >= 3:
        # Cut just before the 3rd Takbeer
        cutoff_raw = float(peak_times[2]) - 0.3
        # Round UP to nearest integer (safer — gives a bit of silence breathing room)
        cutoff = int(np.ceil(cutoff_raw))
    elif len(peak_times) == 2:
        # Fallback: use midpoint after 2nd peak + 3 s
        cutoff = int(np.ceil(float(peak_times[1]) + 3.0))
    else:
        cutoff = DEFAULT_CUTOFF

    # Sanity bounds: 6 s minimum, duration-2 s maximum
    cutoff = max(6, min(cutoff, int(duration) - 2))

    return float(cutoff)


def process_file(name: str, verbose: bool = True) -> dict:
    mp3 = RAW_DIR / f"{name}.mp3"
    if not mp3.exists():
        print(f"  ✗ not found: {mp3}")
        return {}

    if name in GROUND_TRUTH:
        cutoff = GROUND_TRUTH[name]
        if verbose:
            print(f"  → using ground-truth cutoff: {cutoff} s")
    else:
        cutoff = detect_cutoff(mp3, verbose=verbose)
        if verbose:
            print(f"  → recommended cutoff: {cutoff} s")

    return {"name": name, "cutoff": cutoff}


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else None

    if target:
        names = [target]
    else:
        names = sorted(
            p.stem for p in RAW_DIR.glob("adhan_*.mp3")
            if not p.stem.startswith("adhan_sample")
        )

    results = []
    for name in names:
        print(f"\n[{name}]")
        r = process_file(name, verbose=True)
        if r:
            results.append(r)

    if not results:
        return

    print("\n" + "═" * 60)
    print("SUMMARY — paste these into adhan_sounds.dart")
    print("═" * 60)
    for r in results:
        print(f"  {r['name']:<15}  shortDurationSeconds: {int(r['cutoff'])},")

    print()
    # Also print as a Dart map for easy copy-paste
    print("// Dart map (copy into code if needed):")
    print("const cutoffs = {")
    for r in results:
        print(f"  '{r['name']}': {int(r['cutoff'])},")
    print("};")


if __name__ == "__main__":
    main()
