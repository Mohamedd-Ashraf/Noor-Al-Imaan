"""
Re-generate notification sounds using Microsoft Edge TTS:
  Voice: ar-SA-HamedNeural  (Saudi Arabic, male, neural — clear & authoritative)
  Rate:  -20%  (slower = more solemn, matches Quran/Adhan cadence)
  Volume: +10%

Also re-extracts iqama_sound from the real Makkah recording
(keeps the real human recitation for the iqama).

Outputs (mono 22 kHz PCM WAV):
  prayer_reminder_fajr.wav    "اقتربت صلاة الفجر"
  prayer_reminder_dhuhr.wav   "اقتربت صلاة الظهر"
  prayer_reminder_asr.wav     "اقتربت صلاة العصر"
  prayer_reminder_maghrib.wav "اقتربت صلاة المغرب"
  prayer_reminder_isha.wav    "اقتربت صلاة العشاء"
  salawat_sound.wav           "اللهم صلِّ على محمد وعلى آل محمد"
  iqama_sound.wav             "قد قامت الصلاة" (real Makkah recording)
"""
import asyncio, io, pathlib
import numpy as np
import soundfile as sf
import librosa
import edge_tts

CACHE   = pathlib.Path('tool/_adhan_cache')
RAW_DIR = pathlib.Path('android/app/src/main/res/raw')
RAW_DIR.mkdir(parents=True, exist_ok=True)

SR    = 22050
VOICE = 'ar-AE-HamdanNeural'  # UAE Arabic male neural voice (most natural)
RATE  = '-15%'                 # Slightly slower → more solemn
VOL   = '+5%'

TTS_SOUNDS = [
    ('prayer_reminder_fajr',    'اقتربت صلاة الفجر'),
    ('prayer_reminder_dhuhr',   'اقتربت صلاة الظهر'),
    ('prayer_reminder_asr',     'اقتربت صلاة العصر'),
    ('prayer_reminder_maghrib', 'اقتربت صلاة المغرب'),
    ('prayer_reminder_isha',    'اقتربت صلاة العشاء'),
    ('salawat_sound',           'اللهم صلِّ على محمد وعلى آل محمد'),
]

# ─────────────────────────────────────────────────────────────────────────────
def mp3_bytes_to_array(mp3_bytes: bytes, sr=SR) -> np.ndarray:
    buf = io.BytesIO(mp3_bytes)
    y, _ = librosa.load(buf, sr=sr, mono=True)
    return y

def save_wav(y: np.ndarray, sr: int, dest: pathlib.Path, fade_s=0.18):
    y = y / (np.max(np.abs(y)) + 1e-7) * 0.92
    fade_n = int(sr * fade_s)
    if len(y) > fade_n:
        y = y.copy()
        y[-fade_n:] *= np.linspace(1.0, 0.0, fade_n)
    sf.write(str(dest), y, sr, subtype='PCM_16')
    dur = len(y) / sr
    kb  = dest.stat().st_size // 1024
    print(f'  ✓ {dest.name}  ({dur:.1f}s  {kb}KB)')

async def synthesise(text: str) -> bytes:
    comm = edge_tts.Communicate(text, VOICE, rate=RATE, volume=VOL)
    chunks = []
    async for chunk in comm.stream():
        if chunk['type'] == 'audio':
            chunks.append(chunk['data'])
    return b''.join(chunks)

# ─────────────────────────────────────────────────────────────────────────────
async def main():
    print(f'Voice: {VOICE}   rate={RATE}   vol={VOL}\n')

    # ── TTS sounds ────────────────────────────────────────────────────────────
    for fname, text in TTS_SOUNDS:
        print(f'[{fname}]  "{text}"')
        mp3 = await synthesise(text)
        y   = mp3_bytes_to_array(mp3)
        y, _ = librosa.effects.trim(y, top_db=28, frame_length=512, hop_length=128)
        save_wav(y, SR, RAW_DIR / f'{fname}.wav')

    # ── Real iqama recording ─────────────────────────────────────────────────
    iqama_src = CACHE / 'iqama_makkah_fajr.ogg'
    if iqama_src.exists():
        print(f'\n[iqama_sound]  "قد قامت الصلاة" — real Makkah recording')
        y, _ = librosa.load(str(iqama_src), sr=SR, mono=True)
        # "قد قامت الصلاة  قد قامت الصلاة" portion is ~24.8 – 35.5 s
        segment = y[int(24.8 * SR): int(35.5 * SR)]
        segment = segment / (np.max(np.abs(segment)) + 1e-7) * 0.92
        segment, _ = librosa.effects.trim(segment, top_db=20,
                                          frame_length=512, hop_length=128)
        save_wav(segment, SR, RAW_DIR / 'iqama_sound.wav')
    else:
        print(f'\n[iqama_sound]  source not found: {iqama_src}')

    print('\nAll done!  Files in:', RAW_DIR)

asyncio.run(main())
