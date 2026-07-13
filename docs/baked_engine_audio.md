# Engine audio runtime and baking pipeline

The runtime uses two engine-audio backends with distinct performance targets:

- player cars use `ProfiledEngineAudioSynthesizer` and generate the complete VQ37VHR signal in real time through `AudioStreamGenerator`;
- AI cars use committed WAV banks through `BakedEngineAudioPlayer`.

This keeps the detailed, continuously reacting synthesis for the car the player hears most clearly while avoiding per-sample GDScript work for every opponent.

## Player-car runtime

The player scenes are:

```text
scenes/cars/370z.tscn
scenes/cars/370z_nismo.tscn
```

Their automatic variants inherit from these scenes, so both manual and automatic player cars use the same live backend.

Each player scene assigns its model-specific `EngineAudioProfile` to `ProfiledEngineAudioSynthesizer`. The scene also enables `force_full_runtime_generation`, which bypasses distance LOD and the shared procedural voice budget. While running with a display and audio output, every synthesis update therefore fills an `AudioStreamGenerator` from current RPM, engine load and throttle.

Headless runs keep the node and profile contract but disable processing before allocating the generator.

## AI runtime

The AI scenes are:

```text
scenes/cars/370z_ai.tscn
scenes/cars/370z_nismo_ai.tscn
```

They use `BakedEngineAudioPlayer` with the corresponding committed bank. Each bank contains two mono PCM16 layers for every RPM anchor:

- `coast`: closed or nearly closed throttle;
- `load`: high engine load and throttle.

`BakedEngineAudioPlayer` performs only low-cost runtime operations:

- loads the committed `AudioStreamWAV` resources through `EngineAudioSampleBank`;
- selects the nearest RPM anchor;
- adjusts `pitch_scale` between anchors;
- crossfades when the selected anchor changes;
- crossfades coast and load layers from current engine load and throttle.

The normal steady state uses one coast voice and one load voice. Two additional native players exist only for short anchor transitions.

## Repository layout

```text
scripts/car/engine_audio.gd
scripts/car/profiled_engine_audio.gd
scripts/car/engine_audio_profile.gd
resources/audio/370z_stock_audio_profile.tres
resources/audio/370z_nismo_audio_profile.tres
    Live player-car synthesizer and profiles.

scripts/tools/engine_audio_bake_preset.gd
scripts/tools/engine_audio_bank_baker.gd
scripts/tools/bake_engine_audio_banks.gd
resources/audio/bake_presets/
    Offline bank generation.

assets/audio/engine/<bank_id>/
scripts/car/engine_audio_sample_bank.gd
scripts/car/baked_engine_audio_player.gd
    Committed WAV banks and AI runtime playback.
```

Generated WAV files remain source-controlled. AI audio and bank validation must not depend on an untracked local bake cache.

## Rebuilding every registered bank locally

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

## Rebuilding through GitHub Actions

Open **Actions → Bake engine audio banks → Run workflow** and select the target branch.

- Leave `preset_path` empty to rebuild every registered bank.
- Enter a complete `res://...tres` preset path to rebuild one bank.

The workflow downloads the pinned Godot binary, verifies its checksum, imports resources, runs the baker, uploads diagnostics and commits changed files under `assets/audio/engine/`.

## Adding engine audio for another car

1. Add or adapt a deterministic synthesizer with `generate_test_frames(frame_count, rpm, load, throttle)`.
2. Add a profile resource exposing `is_valid()` and `apply_to(target)`.
3. Assign the profiled synthesizer to the player scene and enable full runtime generation.
4. Create an `EngineAudioBakePreset` for the AI bank.
5. Define increasing RPM anchors, sample rate, loop duration and coast/load operating points.
6. Add the preset to `DEFAULT_PRESET_PATHS` when it belongs in full rebuilds.
7. Bake and commit the generated bank.
8. Assign the bank to `BakedEngineAudioPlayer` in the AI scene.
9. Extend the audio backend contract test with the new player and AI scenes.

## Validation

Automated coverage verifies that:

- player scenes use valid profiled synthesizers with full runtime generation enabled;
- AI scenes use prepared baked banks and do not allocate `AudioStreamGenerator`;
- every committed clip exists and imports as mono `AudioStreamWAV`;
- sample rate and duration match bank metadata;
- the packaged player-car smoke test exposes live synthesis;
- production and test exports include the required profiles, scripts and bank resources.
