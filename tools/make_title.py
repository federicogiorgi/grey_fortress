#!/usr/bin/env python3
"""Generates the title-screen music for Grey Fortress: an epic
fantasy theme in E minor - deep drone, big slow chords, a heroic
horn melody and taiko-like drums.

Like the rest of the audio, it is synthesized from scratch and
dedicated to the public domain (CC0).

Run:  python3 make_title.py   (writes audio/title.ogg)
"""
import os
import numpy as np
import soundfile as sf

SR = 32000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")


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
def pad(f, t, dur):
    y = (np.sin(2 * np.pi * f * t) + np.sin(2 * np.pi * f * 1.005 * t)
         + 0.5 * np.sin(4 * np.pi * f * t)) / 2.5
    a = np.minimum(t / 1.2, 1.0)
    r = np.clip((dur - t) / 1.2, 0, 1)
    return y * a * r


def horn(f, t, dur):
    """Brassy lead: strong low harmonics, slow attack, held body."""
    y = sum(np.sin(2 * np.pi * f * k * t) / k for k in (1, 2, 3, 4, 5))
    vib = 1.0 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(t / 0.8, 1.0)
    y = sum(np.sin(2 * np.pi * f * k * vib * t) / k for k in (1, 2, 3)) + 0.18 * y
    a = np.minimum(t / 0.07, 1.0)
    r = np.clip((dur - t) / 0.20, 0, 1)
    return y * a * r * np.exp(-t / (2.5 * max(dur, 0.5)))


def taiko(out, at, amp):
    """Deep drum boom."""
    i = int(at * SR)
    length = int(0.35 * SR)
    t = np.arange(length) / SR
    f = 82 * np.exp(-t * 16) + 46
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.16)
    rng = np.random.default_rng(int(at * 1000) % 99991)
    y += np.convolve(rng.standard_normal(length), np.ones(24) / 24, "same") * np.exp(-t / 0.03) * 0.8
    out[i:i + length] += y * amp


def save(name, data, peak):
    data = (data / np.max(np.abs(data)) * peak).astype(np.float32)
    path = os.path.join(OUT, name)
    with sf.SoundFile(path, "w", SR, 1, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), SR):
            f.write(data[i:i + SR])
    print("wrote", path, f"{len(data)/SR:.1f}s")


# =========================================================
#  TITLE - "The Grey Fortress", E minor, 84 bpm, 16 bars
# =========================================================
def make_title():
    bpm = 84
    beat = 60 / bpm
    bars = 16
    total = bars * 4 * beat

    # chords, one per bar: Em Em C G / D Em C D | repeat with Am B
    E, C, G, D, A, B = "Em", "C", "G", "D", "Am", "B"
    prog = [E, E, C, G, D, E, C, D, E, G, A, E, C, G, B, E]
    voicing = {
        "Em": (40, 52, 55, 59), "C": (36, 48, 52, 55), "G": (43, 55, 59, 62),
        "D": (38, 50, 54, 57), "Am": (33, 45, 48, 52), "B": (35, 47, 51, 54),
    }
    notes = [(28, 0.0, total, 0.10)]                      # deep E1 drone
    for bar, ch in enumerate(prog):
        t0 = bar * 4 * beat
        for n in voicing[ch]:
            notes.append((n, t0, 4 * beat, 0.12))
    pads = render(notes, total, pad)

    # heroic melody, entering at bar 4 (E4=64  F#4=66  G4=67  A4=69
    # B4=71  C5=72  D5=74  E5=76)
    theme = [
        # (midi, start_beat, dur_beats) relative to bar 4
        (64, 0.0, 2.0), (67, 2.0, 1.0), (69, 3.0, 1.0),
        (71, 4.0, 3.0), (69, 7.0, 0.5), (67, 7.5, 0.5),
        (69, 8.0, 2.0), (67, 10.0, 1.0), (64, 11.0, 1.0),
        (66, 12.0, 3.0), (62, 15.0, 1.0),
        (64, 16.0, 2.0), (67, 18.0, 1.0), (71, 19.0, 1.0),
        (74, 20.0, 2.5), (71, 22.5, 1.5),
        (72, 24.0, 2.0), (71, 26.0, 1.0), (69, 27.0, 1.0),
        (71, 28.0, 4.0),
        # second, higher pass
        (76, 32.0, 2.0), (74, 34.0, 1.0), (71, 35.0, 1.0),
        (72, 36.0, 2.0), (71, 38.0, 1.0), (67, 39.0, 1.0),
        (69, 40.0, 2.0), (71, 42.0, 1.0), (72, 43.0, 1.0),
        (71, 44.0, 4.0),
    ]
    mel = render([(n, (16 + s) * beat, d * beat, 0.24) for n, s, d in theme],
            total, horn)

    music = pads + mel

    # drums: a boom on every bar, a lighter answer on beat 3,
    # doubling up in the final four bars
    for bar in range(bars):
        t0 = bar * 4 * beat
        taiko(music, t0, 0.55 if bar >= 4 else 0.35)
        taiko(music, t0 + 2 * beat, 0.22)
        if bar >= 12:
            taiko(music, t0 + 3 * beat, 0.30)

    save("title.ogg", music[: int(total * SR)], 0.82)


make_title()
