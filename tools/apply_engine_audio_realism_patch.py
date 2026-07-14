from pathlib import Path

engine = Path("scripts/car/engine_audio.gd")
text = engine.read_text(encoding="utf-8")
old_gate = ") * startup_combustion_gate * shutdown_gate * combustion_state_gate"
new_gate = ") * startup_combustion_gate * combustion_state_gate"
if text.count(old_gate) != 1:
    raise RuntimeError(f"Expected one stale shutdown gate, found {text.count(old_gate)}")
text = text.replace(old_gate, new_gate, 1)

alpha_old = "var safe_rate: float = maxf(sample_rate, 1.0)\n\treturn 1.0 - pow(1.0 - safe_alpha, REFERENCE_SAMPLE_RATE / safe_rate)"
alpha_new = "var safe_rate: float = maxf(sample_rate, 1.0)\n\tif is_equal_approx(safe_rate, REFERENCE_SAMPLE_RATE):\n\t\treturn safe_alpha\n\treturn 1.0 - pow(1.0 - safe_alpha, REFERENCE_SAMPLE_RATE / safe_rate)"
if alpha_old not in text:
    raise RuntimeError("Sample-rate alpha helper pattern was not found")
text = text.replace(alpha_old, alpha_new, 1)

decay_old = "var safe_decay: float = clampf(decay_at_32k, 0.0, 1.0)\n\treturn pow(safe_decay, REFERENCE_SAMPLE_RATE / maxf(sample_rate, 1.0))"
decay_new = "var safe_decay: float = clampf(decay_at_32k, 0.0, 1.0)\n\tvar safe_rate: float = maxf(sample_rate, 1.0)\n\tif is_equal_approx(safe_rate, REFERENCE_SAMPLE_RATE):\n\t\treturn safe_decay\n\treturn pow(safe_decay, REFERENCE_SAMPLE_RATE / safe_rate)"
if decay_old not in text:
    raise RuntimeError("Sample-rate decay helper pattern was not found")
text = text.replace(decay_old, decay_new, 1)
engine.write_text(text, encoding="utf-8", newline="\n")

bmw = Path("scripts/car/bmw_e46_engine_audio.gd")
bmw_text = bmw.read_text(encoding="utf-8")
firing_old = "\tvar firing_hz: float = maxf(\n\t\tEngineAudioSynthesizer.firing_frequency_hz(rpm, cylinders) * (1.0 + idle_wander),\n\t\t1.0\n\t)\n"
firing_new = firing_old.replace("\t\t1.0\n", "\t\t0.0\n")
if firing_old not in bmw_text:
    raise RuntimeError("BMW firing-frequency floor pattern was not found")
bmw.write_text(bmw_text.replace(firing_old, firing_new, 1), encoding="utf-8", newline="\n")

for helper in (
    Path("tools/apply_engine_audio_realism_patch.py"),
    Path(".github/workflows/apply-engine-audio-realism.yml"),
    Path(".github/workflows/fix-engine-audio-ci.yml"),
):
    if helper.exists():
        helper.unlink()

print("Engine audio compile hotfix applied.")
