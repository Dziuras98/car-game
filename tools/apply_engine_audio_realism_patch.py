from pathlib import Path

path = Path("scripts/car/bmw_e46_engine_audio.gd")
text = path.read_text(encoding="utf-8")
for line in (
    "\t_punto_fast_noise = lerpf(_punto_fast_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.42, sample_rate))\n",
    "\t_punto_fast_noise = 0.0\n",
):
    if text.count(line) != 1:
        raise RuntimeError(f"Expected one obsolete BMW fast-noise line, found {text.count(line)}: {line!r}")
    text = text.replace(line, "", 1)
path.write_text(text, encoding="utf-8", newline="\n")

Path("tools/apply_engine_audio_realism_patch.py").unlink()
print("Removed obsolete BMW fast-noise state references.")
