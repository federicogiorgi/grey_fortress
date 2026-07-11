#!/usr/bin/env python3
"""Generates the three music tracks for Grey Fortress.

All melodies were composed for this project and the audio is
synthesized from scratch (no samples). The resulting tracks are
dedicated to the public domain (CC0).

Run:  python3 make_music.py   (writes .wav files next to the script)
"""
import numpy as np
import wave

SR = 32000


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def render(notes, total, timbre):
    """notes: list of (midi_note, start_sec, dur_sec, amp)."""
    out = np.zeros(int(total * SR) + SR, dtype=np.float64)
    for n, start, dur, amp in notes:
        f = midi(n)
        length = int(dur * SR)
        t = np.arange(length) / SR
        y = timbre(f, t, dur)
        i = int(start * SR)
        room = len(out) - i
        out[i:i + length] += amp * y[:room]
    return out


# ---------------- timbres ----------------
def pluck(f, t, dur):
    y = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(4 * np.pi * f * t) + 0.15 * np.sin(6 * np.pi * f * t)
    env = np.minimum(t / 0.005, 1.0) * np.exp(-t / (0.22 * max(dur, 0.3)))
    return y * env


def bass_pluck(f, t, dur):
    y = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)
    env = np.minimum(t / 0.004, 1.0) * np.exp(-t / 0.16)
    return y * env


def pad(f, t, dur):
    y = (np.sin(2 * np.pi * f * t) + np.sin(2 * np.pi * f * 1.004 * t)
         + 0.5 * np.sin(4 * np.pi * f * t)) / 2.5
    a = np.minimum(t / 0.9, 1.0)
    r = np.minimum((dur - t) / 0.9, 1.0)
    return y * a * np.clip(r, 0, 1)


def bell(f, t, dur):
    y = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 3.76 * t)
    env = np.minimum(t / 0.003, 1.0) * np.exp(-t / 0.9)
    return y * env


def grit(f, t, dur):
    y = sum(np.sin(2 * np.pi * f * k * t) / k for k in range(1, 7))
    env = np.minimum(t / 0.004, 1.0) * np.exp(-t / 0.10)
    return y * env


# ---------------- percussion ----------------
def drum_hit(out, at, kind):
    i = int(at * SR)
    rng = np.random.default_rng(int(at * 1000) % 99991)
    if kind == "kick":
        length = int(0.11 * SR)
        t = np.arange(length) / SR
        f = 60 * np.exp(-t * 22) + 38
        y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.05) * 0.9
    elif kind == "snare":
        length = int(0.12 * SR)
        t = np.arange(length) / SR
        y = (rng.standard_normal(length) * 0.6 + np.sin(2 * np.pi * 190 * t) * 0.4)
        y *= np.exp(-t / 0.045) * 0.55
    else:  # hat
        length = int(0.03 * SR)
        n = rng.standard_normal(length)
        y = np.diff(n, prepend=0) * np.exp(-np.arange(length) / SR / 0.008) * 0.35
    out[i:i + len(y)] += y


def save(name, data):
    peak = np.max(np.abs(data))
    data = data / peak * 0.85
    pcm = (data * 32767).astype(np.int16)
    with wave.open(name, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("wrote", name, f"{len(pcm)/SR:.1f}s")


# =====================================================
#  1. TOWN - a gentle waltz in G major, 108 bpm, 16 bars
# =====================================================
def make_town():
    bpm = 108
    beat = 60 / bpm
    G, A, B, C, D, E, FS = 67, 69, 71, 72, 74, 76, 78
    G5 = 79
    mel_bars = [
        [(B, 1), (G, 1), (A, 1)],
        [(B, 1), (C, .5), (B, .5), (A, 1)],
        [(C, 1), (E, 1), (D, 1)],
        [(B, 2), (G, 1)],
        [(A, 1), (D, 1), (FS - 5, .5), (D, .5)],
        [(E, 1), (D, 1), (B, 1)],
        [(G, 1), (B, 1), (D, 1)],
        [(B, 3)],
        [(E, 1), (D, .5), (C, .5), (D, 1)],
        [(C, 1), (D, 1), (E, 1)],
        [(G5, 1), (D, 1), (B, 1)],
        [(E, 2), (D, 1)],
        [(C, 1), (A, 1), (C, 1)],
        [(D, 1), (FS - 5, 1), (A, 1)],
        [(G, 1), (B, 1), (D, 1)],
        [(G, 3)],
    ]
    bass_roots = [43, 43, 48, 43, 50, 50, 43, 43, 48, 48, 43, 52, 45, 50, 43, 43]
    notes = []
    for bar, (mnotes, root) in enumerate(zip(mel_bars, bass_roots)):
        t0 = bar * 3 * beat
        # melody
        pos = 0.0
        for n, d in mnotes:
            notes.append((n, t0 + pos * beat, d * beat, 0.30))
            pos += d
        # oom-pah-pah bass
        notes.append((root, t0, beat * 0.95, 0.30))
        for b in (1, 2):
            notes.append((root + 7, t0 + b * beat, beat * 0.5, 0.14))
            notes.append((root + 12, t0 + b * beat, beat * 0.5, 0.10))
    total = 16 * 3 * beat
    mel = render([n for n in notes if n[3] > 0.2 and n[0] > 60], total, pluck)
    bas = render([n for n in notes if n[0] <= 60 or n[3] <= 0.2], total, bass_pluck)
    save("town.wav", (mel + bas)[: int(total * SR)])


# ==============================================================
#  2. WILDS - slow pads with sparse bells, D dorian, 78 bpm
# ==============================================================
def make_wilds():
    bpm = 78
    beat = 60 / bpm
    bars = 8
    chords = [
        (50, 53, 57), (53, 57, 60), (55, 59, 62), (48, 52, 55),
        (50, 53, 57), (46, 50, 53), (55, 59, 62), (50, 53, 57),
    ]
    notes = []
    for bar, ch in enumerate(chords):
        t0 = bar * 4 * beat
        for n in ch:
            notes.append((n, t0, 4 * beat, 0.16))
            notes.append((n + 12, t0, 4 * beat, 0.07))
    pads = render(notes, bars * 4 * beat, pad)

    penta = [74, 77, 79, 81, 84, 81, 79, 77]
    bell_pattern = [0, 3, 6, 9.5, 12, 15, 18, 21.5, 24, 27, 29, 30.5]
    bells = []
    for i, when in enumerate(bell_pattern):
        bells.append((penta[i % len(penta)], when * beat, 2.2, 0.12))
    bel = render(bells, bars * 4 * beat, bell)
    total = bars * 4 * beat
    save("wilds.wav", (pads + bel)[: int(total * SR)])


# =========================================================
#  3. COMBAT - driving A minor riff with drums, 145 bpm
# =========================================================
def make_combat():
    bpm = 145
    beat = 60 / bpm
    bars = 8
    total = bars * 4 * beat
    A2, C3, D3, E3, G2 = 45, 48, 50, 52, 43
    bass_bar = [
        [A2, A2, C3, A2, A2, G2, A2, D3],
        [A2, A2, C3, A2, E3, D3, C3, G2],
    ]
    notes = []
    for bar in range(bars):
        pat = bass_bar[bar % 2]
        t0 = bar * 4 * beat
        for i, n in enumerate(pat):
            notes.append((n, t0 + i * 0.5 * beat, 0.5 * beat, 0.34))
    riff_bars = [
        [(69, 0, 1), (72, 1, .5), (74, 1.5, .5), (76, 2, 1), (74, 3, 1)],
        [(76, 0, .5), (77, .5, .5), (76, 1, 1), (72, 2, 1), (69, 3, 1)],
        [(74, 0, 1), (76, 1, 1), (77, 2, .5), (76, 2.5, .5), (74, 3, 1)],
        [(72, 0, 1.5), (69, 1.5, .5), (67, 2, 2)],
    ]
    for bar in range(bars):
        if bar < 2:
            continue  # bass-and-drums intro
        phrase = riff_bars[(bar - 2) % 4]
        t0 = bar * 4 * beat
        for n, at, d in phrase:
            notes.append((n, t0 + at * beat, d * beat, 0.22))
    music = render(notes, total, grit)

    for bar in range(bars):
        t0 = bar * 4 * beat
        for b in range(4):
            drum_hit(music, t0 + b * beat, "kick" if b % 2 == 0 else "snare")
        for e in range(8):
            drum_hit(music, t0 + e * 0.5 * beat, "hat")
    save("combat.wav", music[: int(total * SR)])



# =========================================================
#  4. FOREST - darker pads over a low drone, E minor, 66 bpm
# =========================================================
def make_forest():
    bpm = 66
    beat = 60 / bpm
    bars = 8
    total = bars * 4 * beat
    chords = [
        (52, 55, 59), (48, 52, 55), (45, 48, 52), (47, 51, 54),
        (52, 55, 59), (50, 53, 57), (48, 52, 55), (52, 55, 59),
    ]
    notes = [(40, 0.0, total, 0.10), (52, 0.0, total, 0.04)]  # deep drone
    for bar, ch in enumerate(chords):
        t0 = bar * 4 * beat
        for n in ch:
            notes.append((n, t0, 4 * beat, 0.13))
    pads = render(notes, total, pad)
    penta = [76, 79, 74, 81, 79, 76, 83, 74]
    times = [2.5, 7, 11, 14.5, 18, 22, 26, 29.5]
    bel = render([(penta[i], times[i] * beat, 2.5, 0.09) for i in range(8)], total, bell)
    save("forest.wav", (pads + bel)[: int(total * SR)])


# =========================================================
#  5. RUINS - eerie drones, sparse dissonant bells, wind
# =========================================================
def make_ruins():
    total = 26.0
    notes = [(38, 0.0, total, 0.10), (45, 0.0, total, 0.05)]
    drone = render(notes, total, pad)
    bell_notes = [62, 65, 68, 62, 60, 65, 56, 63]
    bell_times = [1.5, 5.0, 8.5, 12.0, 15.5, 18.5, 21.5, 24.0]
    bel = render([(bell_notes[i], bell_times[i], 3.0, 0.13) for i in range(8)], total, bell)
    # wind: low-passed noise swelling in and out
    rng = np.random.default_rng(7)
    n = rng.standard_normal(int(total * SR) + SR)
    wind = np.convolve(n, np.ones(96) / 96, mode="same")
    t = np.arange(len(wind)) / SR
    wind *= 0.028 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 9.0 - 1.2))
    save("ruins.wav", (drone + bel + wind)[: int(total * SR)])


make_town()
make_wilds()
make_forest()
make_ruins()
make_combat()
