# Stock 370Z procedural engine-audio model

The 370Z uses a self-contained real-time synthesizer. It does not load samples,
rendered recordings or external simulation output. Every audible component is
generated inside Godot from current engine RPM, engine load and throttle input.

## Character target

The target is the standard naturally aspirated 3.7-litre 370Z rather than the
Nismo exhaust calibration. The model keeps the low-frequency exhaust body
controlled, makes induction noise strongly load-dependent, introduces the
recognisable upper-rev rasp progressively and keeps lift-off crackle sparse.

The six-cylinder firing rate is calculated as three combustion events per crank
revolution. A repeating six-event gain pattern and a small alternating-bank
imbalance prevent a perfectly sterile oscillator sound without creating an
uneven-fire rhythm.

## Detailed signal path

1. RPM, load and throttle are sanitized and smoothed.
2. The firing phase creates a pressure spike, exhaust tail, rarefaction and a
   short combustion-chamber ring.
3. Cylinder variation changes successive pulse amplitudes subtly.
4. Alternating pulses feed independent left- and right-bank exhaust resonators
   with slightly different tuning.
5. A common collector/body resonator supplies the low-frequency exhaust mass.
6. Midrange and reflection resonators model pipe, catalyst and muffler-return
   coloration without turning the result into an aftermarket exhaust.
7. Primary and secondary intake/plenum resonators provide load-sensitive growl
   and upper-mid induction detail.
8. Filtered airflow noise grows with throttle, engine load and RPM.
9. Pulse derivatives, differentiated noise and a high-frequency resonator create
   the characteristic VQ37VHR rasp above the midrange.
10. Valve-event pulses, cam-chain harmonics and a mechanical resonator add
    restrained rotating-assembly and valvetrain texture.
11. A procedural starter motor and combustion-catch envelope reproduce startup;
    a callable shutdown envelope removes combustion and lets resonances decay.
12. Abrupt throttle lift above the midrange can trigger sparse, quickly decaying
    overrun events.
13. Near the rev limit, a periodic ignition gate removes combustion energy while
    leaving mechanical and resonant components active.
14. A DC blocker and smooth hyperbolic saturator keep the stream stable and
    bounded while preserving more transient detail than hard clipping.

## Loudness structure

Loudness is controlled at two independent stages:

- `synthesis_gain_db` raises the generated waveform before smooth saturation;
- `output_volume_boost_db` raises the `AudioStreamPlayer3D` level after the
  existing idle/load interpolation.

The detailed profile uses 3.5 dB of synthesis gain and a 4 dB player boost. This
is intentionally much more audible than the original model while retaining
headroom through smooth saturation. Per-car scene overrides for
`idle_volume_db` and `load_volume_db` remain valid.

## Runtime behavior

The model retains distance culling and the shared procedural voice budget. It
runs at 32 kHz by default, preserving the useful rasp and mechanical band while
keeping per-voice GDScript cost bounded. New detail layers use fixed state
variables and do not allocate arrays or dictionaries per generated sample.

Startup is optional through `play_startup_on_ready` or `trigger_engine_start()`.
Shutdown is available through `trigger_engine_shutdown()` without requiring an
audio asset or separate event player.

## Tuning priorities

For a stock exhaust, adjust in this order:

1. `output_volume_boost_db` and `synthesis_gain_db` for loudness;
2. `exhaust_resonance` for low and low-mid body;
3. `exhaust_bank_separation` and `exhaust_reflection` for pipe detail;
4. `intake_presence` and `intake_plenum_detail` for induction;
5. `high_rpm_rasp` for the 5000-7600 RPM character;
6. `exhaust_roughness` and `airflow_noise` for texture;
7. `mechanical_noise` and `rotating_assembly_detail` for valvetrain presence;
8. `overrun_crackle` only after steady-state sound is correct.

The interactive scene `scenes/tools/engine_audio_lab.tscn` allows continuous RPM
and load sweeps, startup playback and a direct idle/limiter toggle. The
standalone model test checks operating-point safety, V6 firing frequency,
limiter behavior, finite bounded output, load-dependent energy, gain behavior
and a material waveform contribution from the additional detail layers.
