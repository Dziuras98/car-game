# Baked engine audio pipeline

The production engine sound is generated offline from the deterministic VQ37VHR synthesizer. Runtime scenes must consume the resulting WAV banks rather than instantiate the per-sample GDScript synthesizer.

## Rebuilding a bank

Run the Godot tool script that calls `EngineAudioBankBaker` with the selected `EngineAudioProfile`. The baker renders warmed-up one-second mono loops at 32 kHz for fixed RPM anchors and for coast/load operating layers, writes PCM16 WAV files, and emits a JSON manifest containing the profile levels and file ordering.

The runtime bank resources and player are intentionally separate from the synthesizer. The synthesizer remains a production tool and deterministic reference model; it must not be attached to player or AI car scenes.
