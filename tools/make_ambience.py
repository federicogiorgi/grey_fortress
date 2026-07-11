#!/usr/bin/env python3
"""Generates the weather ambience for Grey Fortress: a seamless, cozy
rain loop and a distant thunder rumble.

Like the music (make_music.py), everything is synthesized from scratch
and dedicated to the public domain (CC0).

Run:  python3 make_ambience.py   (writes .ogg files into ../audio)
"""
import os
import numpy as np
import soundfile as sf

SR = 32000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")


def save(name, data, peak):
    data = (data / np.max(np.abs(data)) * peak).astype(np.float32)
    path = os.path.join(OUT, name)
    # write in small blocks: one huge buffer can overflow the encoder stack
    with sf.SoundFile(path, "w", SR, 1, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), SR):
            f.write(data[i:i + SR])
    print("wrote", path, f"{len(data)/SR:.1f}s")


# =========================================================
#  RAIN - a soft, steady 18 s loop.
#  Layers: softened hiss (drops on leaves), a warmer low-mid
#  wash (rain on the roof), and sparse bright droplets.
#  The loop is made seamless by crossfading the tail into
#  the head; all slow modulation is periodic in the loop.
# =========================================================
def make_rain():
    dur = 18.0
    n = int(dur * SR)
    rng = np.random.default_rng(42)
    white = rng.standard_normal(n + SR)

    # gentle mix: the bright hiss is filtered harder and kept quiet,
    # most of the body comes from the warm low-mid wash
    hiss = np.convolve(white, np.ones(14) / 14, mode="same")
    wash = np.convolve(white, np.ones(120) / 120, mode="same") * 5.0
    t = np.arange(len(white)) / SR
    # two gentle swells, periods dividing the loop length
    swell = (0.92 + 0.08 * np.sin(2 * np.pi * t / (dur / 2))
                  + 0.04 * np.sin(2 * np.pi * t / (dur / 3) + 1.7))
    rain = (hiss * 0.18 + wash) * swell

    # occasional individual droplets ("plip") for coziness, soft and low
    for _ in range(150):
        at = rng.uniform(0.0, dur)
        f = rng.uniform(700, 1700)
        length = int(0.018 * SR)
        tt = np.arange(length) / SR
        plip = np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.0035)
        i = int(at * SR)
        rain[i:i + length] += plip * rng.uniform(0.05, 0.13)

    # seamless loop: crossfade the second of audio past the loop point
    # back into the beginning
    xf = SR
    out = rain[:n].copy()
    fade = np.linspace(0.0, 1.0, xf)
    out[:xf] = rain[:xf] * fade + rain[n:n + xf] * (1.0 - fade)
    save("rain.ogg", out, 0.42)


# =========================================================
#  THUNDER - distant rolling rumble, ~6 s: a muffled crack,
#  then deep brown-noise thunder with a couple of swells.
# =========================================================
def make_thunder():
    dur = 6.0
    n = int(dur * SR)
    rng = np.random.default_rng(7)
    t = np.arange(n) / SR

    brown = np.cumsum(rng.standard_normal(n))
    brown -= np.linspace(brown[0], brown[-1], n)  # remove drift
    brown /= np.max(np.abs(brown))
    rumble = np.convolve(brown, np.ones(40) / 40, mode="same")
    swells = 1.0 + 0.55 * np.sin(2 * np.pi * t / 1.3 + 0.6) * np.exp(-t / 2.2)
    env = np.minimum(t / 0.10, 1.0) * np.exp(-t / 1.9) * swells
    y = rumble * env

    # the initial (distant, muffled) crack
    crack_len = int(0.35 * SR)
    tt = np.arange(crack_len) / SR
    crack = np.convolve(rng.standard_normal(crack_len), np.ones(12) / 12, mode="same")
    y[:crack_len] += crack * np.exp(-tt / 0.09) * 0.55

    # a weaker echo of the roll a couple of seconds in
    echo_at = int(2.3 * SR)
    echo_len = n - echo_at
    y[echo_at:] += rumble[:echo_len] * np.exp(-t[:echo_len] / 1.2) * 0.35

    save("thunder.ogg", y, 0.80)


make_rain()
make_thunder()
