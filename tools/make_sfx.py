#!/usr/bin/env python3
"""Generates the sound effects for Grey Fortress: short synthesized
cues for combat, items, magic, trading and dying.

Like the rest of the audio, everything is synthesized from scratch
and dedicated to the public domain (CC0).

Run:  python3 make_sfx.py   (writes audio/sfx_*.ogg)
"""
import os
import numpy as np
import soundfile as sf

SR = 32000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.default_rng(11)


def t_of(dur):
    return np.arange(int(dur * SR)) / SR


def env(t, attack=0.004, decay=0.08):
    return np.minimum(t / attack, 1.0) * np.exp(-t / decay)


def tone(f, dur, decay=0.08, harmonics=((1, 1.0),)):
    t = t_of(dur)
    y = sum(a * np.sin(2 * np.pi * f * k * t) for k, a in harmonics)
    return y * env(t, decay=decay)


def sweep(f0, f1, dur, decay=0.10):
    t = t_of(dur)
    f = np.linspace(f0, f1, len(t))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(t, decay=decay)


def noise_hit(dur, kernel, decay):
    t = t_of(dur)
    n = np.convolve(rng.standard_normal(len(t)), np.ones(kernel) / kernel, "same")
    return n * env(t, decay=decay)


def mix(*parts):
    """Overlay (part, start_sec) tuples into one buffer."""
    total = max(int((s + len(p) / SR) * SR) for p, s in parts) + 256
    out = np.zeros(total)
    for p, s in parts:
        i = int(s * SR)
        out[i:i + len(p)] += p
    return out


def save(name, data, peak=0.7):
    data = (data / np.max(np.abs(data)) * peak).astype(np.float32)
    path = os.path.join(OUT, "sfx_%s.ogg" % name)
    with sf.SoundFile(path, "w", SR, 1, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), SR):
            f.write(data[i:i + SR])
    print("wrote", path, f"{len(data)/SR:.2f}s")


# melee hit: a dull thump with a bite of noise
save("hit", mix((sweep(180, 90, 0.10, 0.035), 0.0),
                (noise_hit(0.06, 5, 0.018) * 0.7, 0.0)))

# kill: the hit, then a falling squeal and a coin-like glint
save("kill", mix((noise_hit(0.06, 4, 0.02), 0.0),
                 (sweep(700, 160, 0.22, 0.09) * 0.8, 0.02),
                 (tone(1568, 0.10, 0.05), 0.16),
                 (tone(2093, 0.14, 0.06) * 0.8, 0.22)))

# coin: two bright pings (used for every shop transaction)
save("coin", mix((tone(1568, 0.08, 0.045), 0.0),
                 (tone(2093, 0.14, 0.07), 0.06)))

# pickup: a quick rising arpeggio
save("pickup", mix((tone(523, 0.09, 0.05), 0.00),
                   (tone(659, 0.09, 0.05), 0.07),
                   (tone(784, 0.16, 0.09), 0.14)))

# level up: a small bright fanfare
save("levelup", mix((tone(523, 0.15, 0.10, ((1, 1), (2, .4))), 0.00),
                    (tone(659, 0.15, 0.10, ((1, 1), (2, .4))), 0.12),
                    (tone(784, 0.15, 0.10, ((1, 1), (2, .4))), 0.24),
                    (tone(1047, 0.40, 0.22, ((1, 1), (2, .3))), 0.36)))

# spell cast: a soft whoosh with a rising shimmer
save("cast", mix((noise_hit(0.24, 14, 0.10), 0.0),
                 (sweep(300, 900, 0.20, 0.10) * 0.5, 0.02)))

# player hurt: a low knock and a short groaning drop
save("hurt", mix((sweep(220, 110, 0.14, 0.05), 0.0),
                 (noise_hit(0.05, 8, 0.02) * 0.6, 0.0)))

# death: a slow minor descent over a fading drone
save("death", mix((tone(440, 0.40, 0.25, ((1, 1), (2, .3))), 0.00),
                  (tone(349, 0.40, 0.25, ((1, 1), (2, .3))), 0.35),
                  (tone(262, 0.80, 0.45, ((1, 1), (2, .3))), 0.70),
                  (tone(65, 1.40, 0.70), 0.0)))

# quest / prayer: two temple-bell notes
save("quest", mix((tone(784, 0.5, 0.30, ((1, 1), (3.76, .35))), 0.0),
                  (tone(1047, 0.7, 0.40, ((1, 1), (3.76, .35))), 0.22)))

# drink: two low glugs
save("drink", mix((sweep(200, 90, 0.09, 0.04), 0.00),
                  (sweep(170, 80, 0.11, 0.05), 0.11)))

# stairs: three stone footfalls, fading
save("stairs", mix((noise_hit(0.07, 18, 0.03), 0.00),
                   (noise_hit(0.07, 18, 0.03) * 0.7, 0.14),
                   (noise_hit(0.07, 18, 0.03) * 0.45, 0.28)))
