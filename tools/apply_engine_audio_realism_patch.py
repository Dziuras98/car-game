from pathlib import Path

path = Path("scripts/car/bmw_e46_engine_audio.gd")
text = path.read_text(encoding="utf-8")
update_line = "\t_punto_fast_noise = lerpf(_punto_fast_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.42, sample_rate))\n"
if text.count(update_line) != 1:
    raise RuntimeError(f"Expected one obsolete BMW fast-noise update, found {text.count(update_line)}")
text = text.replace(update_line, "", 1)
text = text.replace("\t_punto_fast_noise = 0.0\n", "")
path.write_text(text, encoding="utf-8", newline="\n")

Path("tools/apply_engine_audio_realism_patch.py").unlink()
print("Removed obsolete BMW fast-noise state references.")
