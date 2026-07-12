# Baked engine audio pipeline

Production car scenes play committed WAV banks. They do not synthesize individual audio samples in GDScript while the game is running.

The detailed engine synthesizer remains in the repository as an offline production tool and deterministic reference model. A bank can therefore be regenerated after tuning a profile, and the same process can be used for future cars.

## Runtime architecture

Each bank contains two mono PCM16 layers for every RPM anchor:

- `coast`: closed or nearly closed throttle;
- `load`: high engine load and throttle.

`BakedEngineAudioPlayer` performs only low-cost runtime operations:

- loads the committed `AudioStreamWAV` resources once through `EngineAudioSampleBank`;
- selects the nearest RPM anchor;
- adjusts `pitch_scale` between anchors;
- crossfades when the selected anchor changes;
- crossfades coast and load layers from current engine load and throttle.

The normal steady state uses one coast voice and one load voice. Two additional native players exist only to make short anchor transitions click-free. No `AudioStreamGenerator`, per-sample loop or procedural synthesis runs in player or AI scenes.

## Repository layout

```text
scripts/car/engine_audio.gd
scripts/car/profiled_engine_audio.gd
scripts/car/engine_audio_profile.gd
    Offline synthesizer and profile model.

scripts/tools/engine_audio_bake_preset.gd
scripts/tools/engine_audio_bank_baker.gd
scripts/tools/bake_engine_audio_banks.gd
    Generic bank definition, renderer and command-line entrypoint.

resources/audio/bake_presets/
    One reusable EngineAudioBakePreset resource per sound bank.

assets/audio/engine/<bank_id>/
    Committed WAV clips, bank.tres and bank_manifest.json.

scripts/car/engine_audio_sample_bank.gd
scripts/car/baked_engine_audio_player.gd
    Runtime bank loader and native sample player.
```

Generated WAV files are source-controlled deliberately. A production build must never need to run the synthesizer or depend on a developer machine having previously filled an untracked cache.

## Rebuilding every registered bank locally

Run Godot 4.7 from the repository root:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --import
Godot_v4.7-stable_win64_console.exe --headless --path . --script scripts/tools/bake_engine_audio_banks.gd
```

The CLI uses the preset list in `scripts/tools/bake_engine_audio_banks.gd`. It rewrites generated WAVs, `bank.tres` and `bank_manifest.json` under each preset's `output_directory`.

To rebuild one bank:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --script scripts/tools/bake_engine_audio_banks.gd -- --preset=res://resources/audio/bake_presets/370z_stock_bake.tres
```

The same arguments work with another Godot executable on Linux or macOS.

## Rebuilding through GitHub Actions

Open **Actions → Bake engine audio banks → Run workflow** and select the branch that should receive the generated files.

- Leave `preset_path` empty to rebuild all registered banks.
- Enter a complete `res://...tres` preset path to rebuild one bank.

The workflow downloads the pinned Godot 4.7 binary, verifies its SHA-512 checksum, imports project resources, runs the baker, uploads the bake log and commits changed files under `assets/audio/engine/` back to the selected branch.

## Adding engine audio for another car

1. Add or adapt a deterministic synthesizer script with `generate_test_frames(frame_count, rpm, load, throttle)`.
2. Add a profile resource exposing `is_valid()` and `apply_to(target)`.
3. Create an `EngineAudioBakePreset` in `resources/audio/bake_presets/`.
4. Choose an output directory under `res://assets/audio/engine/`.
5. Define increasing RPM anchors, sample rate, loop duration and coast/load operating points.
6. Add the preset path to `DEFAULT_PRESET_PATHS` in `bake_engine_audio_banks.gd` when it should be included in full rebuilds.
7. Run the local command or manual workflow and commit the generated bank.
8. Assign the resulting `bank.tres` to a `BakedEngineAudioPlayer` in player and AI scenes.
9. Extend the production bank contract test with the new bank and scenes.

The generic baker does not contain Nissan-specific rendering logic. The current VQ37VHR presets are examples of the reusable contract.

## Generated-bank contract

For each preset the baker writes:

- one `coast_<rpm>.wav` per anchor;
- one `load_<rpm>.wav` per anchor;
- `bank_manifest.json` with generation metadata and file ordering;
- `bank.tres` consumed by runtime scenes.

Current 370Z banks use nine anchors from 700 to 7600 RPM, two layers, mono PCM16 audio, 32 kHz sample rate and one-second loops. This produces 18 clips per bank and 36 clips for stock plus NISMO.

## Validation

Automated coverage verifies that:

- every committed clip exists and imports as mono `AudioStreamWAV`;
- sample rate and duration match the generated bank metadata;
- all production 370Z player and AI scenes use `BakedEngineAudioPlayer`;
- no production scene allocates an `AudioStreamGenerator`;
- a compact temporary bank can still be rendered from a preset;
- the packaged Windows live-audio smoke test plays the committed WAV bank;
- production and test exports include the required audio resources.

The live synthesizer's model-level tests remain in place because it is still the authoritative source used to create future banks. It must not be attached to production car scenes.
