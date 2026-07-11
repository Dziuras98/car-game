# Stock 370Z procedural engine-audio model

The 370Z uses a self-contained real-time synthesizer. It does not load samples,
rendered recordings or external simulation output. Every audible component is
generated inside Godot from current engine RPM, engine load and throttle input.

## Character target

The target is the standard naturally aspirated 3.7-litre 370Z rather than the
Nismo exhaust calibration. The model therefore keeps the low-frequency exhaust
body controlled, makes induction noise strongly load-dependent, introduces the
recognisable upper-rev rasp progressively and keeps lift-off crackle sparse.

The six-cylinder firing rate is calculated as three combustion events per crank
revolution. A repeating six-event gain pattern and a small alternating-bank
imbalance prevent a perfectly sterile oscillator sound without creating an
uneven-fire rhythm.

## Signal path

1. RPM, load and throttle are sanitized and smoothed.
2. The firing phase creates a sharp pressure pulse with a decaying exhaust tail.
3. Cylinder and bank variation changes successive pulse amplitudes subtly.
4. Two state-variable resonators form the exhaust body and midrange shell.
5. A separate load-driven resonator creates the intake growl.
6. A derivative/noise path creates the characteristic high-RPM rasp.
7. A narrow valve-event pulse adds restrained mechanical texture.
8. A procedural starter motor and combustion-catch envelope reproduce startup;
   a callable shutdown envelope removes combustion and lets resonances decay.
9. Abrupt throttle lift above the midrange can trigger sparse, quickly decaying
   overrun events.
10. Near the rev limit, a periodic ignition gate removes combustion energy while
    leaving mechanical and resonant components active.
11. A DC blocker and soft saturator keep the stream stable and bounded.

## Runtime behavior

The model retains distance culling and the shared procedural voice budget. It
runs at 32 kHz by default, which preserves the useful rasp and mechanical band
while keeping the per-voice GDScript cost bounded. The normal 370Z scene keeps
its existing tuning values for exhaust, intake, mechanical noise and overrun.

Startup is optional through `play_startup_on_ready` or `trigger_engine_start()`.
Shutdown is available through `trigger_engine_shutdown()` for future engine-state
integration without requiring an audio asset or a separate event player.

## Tuning priorities

For a stock exhaust, adjust in this order:

1. `exhaust_resonance` for low and low-mid body;
2. `intake_presence` for throttle-dependent induction;
3. `high_rpm_rasp` for the 5000-7600 RPM character;
4. `exhaust_roughness` for midrange texture;
5. `mechanical_noise` for valvetrain presence;
6. `overrun_crackle` only after the steady-state sound is correct.

The interactive scene `scenes/tools/engine_audio_lab.tscn` allows continuous RPM
and load sweeps, startup playback and a direct idle/limiter toggle. The
standalone model test checks operating-point safety, V6 firing frequency,
limiter behavior, finite bounded output and the expected increase in signal
energy under load.
