# 370Z procedural engine-audio model

The standard 370Z and 370Z NISMO player scenes use a self-contained real-time synthesizer. It does not load samples, rendered recordings or external simulation output. Every audible component is generated inside Godot from current engine RPM, engine load and applied throttle.

Dedicated Nissan AI scenes do not run this live signal path. They use committed coast/load WAV banks through `BakedEngineAudioPlayer`; see `docs/baked_engine_audio.md`.

## Character targets

The common live signal model represents the naturally aspirated 3.7-litre VQ37VHR. Typed `EngineAudioProfile` resources provide the final standard and NISMO calibrations:

- the standard profile keeps the low-frequency exhaust body controlled, makes induction noise strongly load-dependent, introduces upper-rev rasp progressively and keeps lift-off crackle sparse;
- the NISMO profile increases induction presence, exhaust resonance, bank separation and residual limiter combustion without changing the shared firing model.

The six-cylinder firing rate is calculated as three combustion events per crank revolution. A repeating six-event gain pattern and a small alternating-bank imbalance prevent a perfectly sterile oscillator sound without creating an uneven-fire rhythm.

## Detailed signal path

1. RPM, load and throttle are sanitized and smoothed.
2. The firing phase creates a pressure spike, exhaust tail, rarefaction and a short combustion-chamber ring.
3. Cylinder variation changes successive pulse amplitudes subtly.
4. Alternating pulses feed independent left- and right-bank exhaust resonators with slightly different tuning.
5. A common collector/body resonator supplies the low-frequency exhaust mass.
6. Midrange and reflection resonators model pipe, catalyst and muffler-return coloration without turning the result into an aftermarket exhaust.
7. Primary and secondary intake/plenum resonators provide load-sensitive growl and upper-mid induction detail.
8. Filtered airflow noise grows with throttle, engine load and RPM.
9. Pulse derivatives, differentiated noise and a high-frequency resonator create the characteristic VQ37VHR rasp above the midrange.
10. Valve-event pulses, cam-chain harmonics and a mechanical resonator add restrained rotating-assembly and valvetrain texture.
11. A procedural starter motor and combustion-catch envelope reproduce startup; a callable shutdown envelope removes combustion and lets resonances decay.
12. Abrupt throttle lift above the midrange can trigger sparse, quickly decaying overrun events.
13. Near the rev limit, a periodic ignition gate removes combustion energy while leaving mechanical and resonant components active.
14. A DC blocker and smooth hyperbolic saturator keep the stream stable and bounded while preserving more transient detail than hard clipping.

## Loudness structure

Loudness is controlled at two independent stages:

- `synthesis_gain_db` raises the generated waveform before smooth saturation;
- `output_volume_boost_db` raises the `AudioStreamPlayer3D` level after idle/load interpolation.

The active player profiles are authoritative:

| Profile | Idle | Load | Synthesis gain | Player boost |
|---|---:|---:|---:|---:|
| Standard 370Z | -10.0 dB | 0.0 dB | 1.0 dB | 11.5 dB |
| 370Z NISMO | -9.0 dB | -0.5 dB | 0.5 dB | 11.0 dB |

`EngineAudioProfile` validates player boost in the 0–16 dB range and synthesis gain in the -6–12 dB range. These limits intentionally include the approved current profiles. The profile contract test verifies both resources, their application to the synthesizer and the editor range exposed by profiled audio players.

## Runtime behavior

Current Nissan player scenes set `force_full_runtime_generation = true`. While a display/audio output is available, the active player synthesizer therefore bypasses `ProceduralAudioPlayer3D` distance culling and the shared procedural voice budget. This protects continuous live response for the player car.

The synthesizer runs at 32 kHz by default, preserving the useful rasp and mechanical band while keeping per-voice GDScript cost bounded. Detail layers use fixed state variables and do not allocate arrays or dictionaries per generated sample.

Live `AudioStreamGenerator` playback is not initialized when Godot uses the headless display server. Profile application and deterministic offline frame generation remain available to tests, while CI avoids creating audio-server objects that cannot be usefully played.

Startup is optional through `play_startup_on_ready` or `trigger_engine_start()`. Shutdown is available through `trigger_engine_shutdown()` without requiring an audio asset or separate event player.

## AI bank relationship

The baked Nissan AI banks are generated offline from deterministic synthesizer output. Each RPM anchor stores separate coast and load layers. Runtime AI playback selects an anchor, adjusts pitch and crossfades between anchors/layers instead of evaluating the complete VQ signal sample by sample.

This means:

- the live model remains the source character for player audio and bank generation;
- AI playback is intentionally lower cost and does not allocate `AudioStreamGenerator`;
- changes to the live synthesizer/profile do not update committed AI WAVs automatically;
- material character changes require rebuilding and committing the affected banks;
- the Nissan fleet benchmark covers one live player voice and three baked AI voices.

## Tuning priorities

For either profile, adjust in this order:

1. `output_volume_boost_db` and `synthesis_gain_db` for loudness;
2. `exhaust_resonance` for low and low-mid body;
3. `exhaust_bank_separation` and `exhaust_reflection` for pipe detail;
4. `intake_presence` and `intake_plenum_detail` for induction;
5. `high_rpm_rasp` for the 5000–7600 RPM character;
6. `exhaust_roughness` and `airflow_noise` for texture;
7. `mechanical_noise` and `rotating_assembly_detail` for valvetrain presence;
8. `overrun_crackle` only after steady-state sound is correct.

After a material change, regenerate deterministic comparison frames and rebuild the relevant committed AI bank before treating player and AI character as synchronized.

## Tools and validation

The interactive scene:

```text
scenes/tools/engine_audio_lab.tscn
```

allows continuous RPM/load sweeps, startup playback and a direct idle/limiter toggle.

Standalone model and profile tests check:

- operating-point safety;
- V6 firing frequency;
- limiter behavior;
- finite bounded output;
- load-dependent energy;
- gain behavior;
- profile validity;
- material waveform contribution from additional detail layers;
- full live generation on player scenes;
- prepared baked banks and absence of `AudioStreamGenerator` on Nissan AI scenes.

The backend matrix, bake commands and benchmark interpretation are maintained in `docs/baked_engine_audio.md`.
