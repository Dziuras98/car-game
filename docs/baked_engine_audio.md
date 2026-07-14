# Engine audio backends and baking pipeline

The runtime currently uses multiple engine-audio backends selected explicitly by car scenes. Backend choice is not inferred from catalog order, player/opponent status alone or transmission type.

## Current backend matrix

| Model family | Player scene backend | AI scene backend | Current AI eligibility |
|---|---|---|---|
| Nissan 370Z | live `ProfiledEngineAudioSynthesizer` | committed WAV bank through `BakedEngineAudioPlayer` | eligible |
| Nissan 370Z NISMO | live `ProfiledEngineAudioSynthesizer` | committed WAV bank through `BakedEngineAudioPlayer` | eligible |
| 1967 Shelby G.T. 500 | live `CrossPlaneV8EngineAudioSynthesizer` | no AI scene | not eligible |
| 1995 Fiat Punto Type 176 | live `FiatPuntoEngineAudioSynthesizer` | currently the same live variant scene | all nine variants eligible |

This matrix describes the current repository. It does not establish that every future AI car must use live synthesis or baked samples.

## Player-audio invariant

Every current player scene uses a live synthesizer driven by runtime RPM, engine load and applied throttle. Live player synthesis is a product requirement for the present implementation and must not be silently replaced by a baked AI bank or disabled through distance LOD.

Current player scenes enable `force_full_runtime_generation`, which bypasses the shared procedural-voice budget and listener-distance suspension. Headless runs retain the node/profile contract but suppress real-time playback before allocating an `AudioStreamGenerator`.

Performance work should therefore target implementation efficiency, opponent backends and unnecessary extra voices rather than silently degrading the active player car.

## Nissan live player path

The Nissan player scenes are:

```text
scenes/cars/370z.tscn
scenes/cars/370z_nismo.tscn
```

Their manual and automatic variants inherit from these model scenes. Each assigns its model-specific `EngineAudioProfile` to `ProfiledEngineAudioSynthesizer` and generates the complete VQ37VHR signal from current runtime telemetry.

Profiles:

```text
resources/audio/370z_stock_audio_profile.tres
resources/audio/370z_nismo_audio_profile.tres
```

The detailed synthesis model is documented in `docs/audio/vq37vhr_procedural_model.md`.

## Nissan baked AI path

The dedicated Nissan AI scenes are:

```text
scenes/cars/370z_ai.tscn
scenes/cars/370z_nismo_ai.tscn
```

They use `BakedEngineAudioPlayer` with the corresponding committed sample bank. Each bank contains two mono PCM16 layers for every RPM anchor:

- `coast`: closed or nearly closed throttle;
- `load`: high engine load and throttle.

`BakedEngineAudioPlayer` performs only low-cost runtime operations:

- loads committed `AudioStreamWAV` resources through `EngineAudioSampleBank`;
- selects the nearest RPM anchor;
- adjusts `pitch_scale` between anchors;
- crossfades when the selected anchor changes;
- crossfades coast and load layers from current engine load and throttle.

The normal steady state uses one coast voice and one load voice. Two additional native players exist only for short anchor transitions.

Generated WAV files remain source-controlled. Nissan AI audio and bank validation must not depend on an untracked local bake cache.

## Shelby live cross-plane V8 path

The Shelby model scene is:

```text
scenes/cars/mustang_shelby_gt500_1967.tscn
```

It uses:

```text
scripts/car/cross_plane_v8_engine_audio.gd
resources/audio/ford_428_fe_audio_profile.tres
```

The synthesizer models the Ford FE cross-plane firing order, unequal bank cadence, separate exhaust-bank resonances, stereo pipe separation and low-order big-block rumble. Both player variants share this live model scene and differ through `CarSpecs` transmission resources.

Neither Shelby variant is currently AI-eligible. No baked Shelby bank or dedicated AI scene exists, so documentation and tests must not imply otherwise.

## Fiat Punto live petrol/diesel/turbo path

All Punto variant scenes inherit from:

```text
scenes/cars/fiat_punto_176_1995_base.tscn
```

The base scene uses:

```text
scripts/car/fiat_punto_engine_audio.gd
```

Each variant assigns a calibration-specific `EngineAudioProfile`. The synthesizer supports:

- spark-ignition four-cylinder combustion;
- separate FIRE SPI, FIRE MPI, 1.6 and GT character;
- compression-ignition pulse shape and diesel mechanical/injection layers;
- naturally aspirated diesel without turbo synthesis;
- petrol GT turbo spool, whistle, release and compressor-flutter character;
- restrained lower-pitched TD turbo behavior;
- starter, shutdown, load transient and limiter behavior.

The current Punto variant resources set `ai_car_scene` to the same live scene used by the player. Therefore Punto opponents currently run live procedural synthesis rather than `BakedEngineAudioPlayer`. This is intentional current configuration and is covered by model-specific content tests, but it does not receive the same fleet benchmark guarantee as the Nissan baked-opponent fixture.

A future optimization may add dedicated baked Punto AI scenes. Such a change must preserve variant-specific petrol/diesel/turbo identity and add explicit backend, bank and mixed-fleet performance coverage.

## Runtime performance benchmark

`scripts/tests/engine_audio_fleet_benchmark_test.gd` measures the current Nissan production race fixture:

```text
1 × ProfiledEngineAudioSynthesizer for the Nissan player
3 × BakedEngineAudioPlayer for Nissan AI opponents
```

The benchmark records separate player, AI and combined race costs for startup-buffer and steady-state windows. It uses median timings and fails CI when:

- the protected single Nissan player synthesizer exceeds its main-thread budget;
- the combined Nissan race fixture exceeds its main-thread budget;
- a Nissan AI fixture stops using a prepared baked bank or allocates `AudioStreamGenerator`.

The report is written to:

```text
build/test-logs/engine-audio-fleet-benchmark.json
```

This test is deliberately backend-specific. It is not evidence that a mixed Fiat/Nissan race or a future Shelby AI fleet has the same cost. When the default production opponent composition or backend matrix changes, the benchmark fixture and this document must change together.

## Repository layout

```text
scripts/car/engine_audio.gd
scripts/car/profiled_engine_audio.gd
scripts/car/engine_audio_profile.gd
scripts/car/cross_plane_v8_engine_audio.gd
scripts/car/fiat_punto_engine_audio.gd
resources/audio/*.tres
    Live player and current Fiat AI synthesizers/profiles.

scripts/tools/engine_audio_bake_preset.gd
scripts/tools/engine_audio_bank_baker.gd
scripts/tools/bake_engine_audio_banks.gd
resources/audio/bake_presets/
    Offline WAV-bank generation.

assets/audio/engine/<bank_id>/
scripts/car/engine_audio_sample_bank.gd
scripts/car/baked_engine_audio_player.gd
    Committed Nissan AI banks and runtime playback.
```

## Rebuilding registered banks locally

Run Godot 4.7 from the repository root:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --import
Godot_v4.7-stable_win64_console.exe --headless --path . --script scripts/tools/bake_engine_audio_banks.gd
```

To rebuild one bank:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --script scripts/tools/bake_engine_audio_banks.gd -- --preset=res://resources/audio/bake_presets/370z_stock_bake.tres
```

The CLI rewrites WAV files, `bank.tres` and `bank_manifest.json` under the preset output directory.

Only registered bake presets are rebuilt by the no-argument command. The current registration represents the committed baked-bank families, not every live synthesizer in the catalog.

## Rebuilding through GitHub Actions

Open **Actions → Bake engine audio banks → Run workflow** and select the target branch.

- Leave `preset_path` empty to rebuild every registered bank.
- Enter a complete `res://...tres` preset path to rebuild one bank.

The workflow downloads the pinned Godot binary, verifies its checksum, imports resources, runs the baker, uploads diagnostics and commits changed files under `assets/audio/engine/`.

## Adding audio for another car

1. Implement or adapt a deterministic live synthesizer with `generate_test_frames(frame_count, rpm, load, throttle)`.
2. Add a valid profile resource exposing `is_valid()`/`validate()` and `apply_to(target)` as required by that synthesizer family.
3. Assign the live synthesizer to every player scene and enable full runtime generation.
4. Decide explicitly whether the AI scene will:
   - use a committed baked bank; or
   - retain live synthesis with a justified performance budget.
5. For a baked AI backend, create an `EngineAudioBakePreset`, define increasing RPM anchors and coast/load operating points, bake/commit the bank and assign it to `BakedEngineAudioPlayer`.
6. For a live AI backend, provide model-specific cost coverage representative of the maximum simultaneous opponent count.
7. Add or update the variant's dedicated `ai_car_scene` when the AI backend differs from the player scene.
8. Extend backend contract tests with every new player and AI scene.
9. Extend the production fleet benchmark whenever the default or supported opponent composition materially changes.
10. Verify exported builds include every required script, profile, bank and WAV resource.

Baked playback is the preferred scalable backend for multiple AI opponents when it can preserve the required identity. It is not currently a mandatory catalog-wide rule because Punto variants intentionally share their live scenes and Shelby has no AI scene.

## Validation

Automated coverage currently verifies that:

- Nissan player scenes use valid profiled synthesizers with full runtime generation enabled;
- Nissan AI scenes use prepared baked banks and do not allocate `AudioStreamGenerator`;
- the Nissan production benchmark contains one procedural player and three baked AI voices;
- Nissan player and combined race main-thread costs remain below explicit regression budgets;
- every committed Nissan bank clip exists and imports as mono `AudioStreamWAV`;
- sample rate and duration match bank metadata;
- Fiat variants instantiate the dedicated Fiat synthesizer with valid engine-specific profiles;
- diesel/turbo profile distinctions are present for Punto D, TD and GT;
- Shelby scenes use the dedicated cross-plane V8 synthesizer/profile;
- the packaged player-car smoke test exposes live synthesis;
- production and test exports include the required current profiles, scripts and bank resources.

A green Nissan fleet benchmark does not replace profiling for live Fiat AI fleets or any future Shelby AI implementation.
