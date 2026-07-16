# Traffic Rider engine-audio implementation contract

## Purpose

This document is the authoritative Stage 8 procedure for every Traffic Rider combustion and electric powertrain. It preserves the audio methods established during research and prevents a new engine from being represented by pitch-shifting, equalizing or retuning the waveform of an unrelated architecture.

A profile is not an engine architecture. Profiles may calibrate an appropriate synthesizer; they may not change the underlying cylinder layout, crank geometry, firing sequence or collector topology.

## Fundamental rule

Start from the physical acoustic event sources and their timing. The implementation must account for, where applicable:

- four-stroke or two-stroke cycle;
- cylinder count and inline, V, flat or other layout;
- crank arrangement and bank angles;
- exact firing order and unequal/equal firing intervals;
- cylinder-to-bank and bank-to-collector routing;
- intake runners, plenum and throttle arrangement;
- exhaust manifold, collector, turbine and pipe grouping;
- combustion type, injection system and ignition character;
- valvetrain, timing drive and rotating-assembly mechanical sources;
- aspiration: naturally aspirated, supercharged, single turbo, sequential/parallel twin turbo or variable-geometry turbo;
- displacement, inertia, idle behaviour, redline/limiter and load transients;
- engine-brake, overrun, cylinder-deactivation or governor behaviour where relevant.

The same number of cylinders does not make two engines acoustically interchangeable.

## Required research record before synthesis

For each engine family/calibration retain, or explicitly mark unavailable:

1. engine code/family, displacement and cylinder layout;
2. crank type, bank angle, firing order and firing intervals;
3. idle, operating range, redline and limiter/governor behaviour;
4. intake and exhaust/collector topology;
5. aspiration hardware and control sequence;
6. fuel, ignition/combustion and injection system;
7. valvetrain and important mechanical-noise sources;
8. cylinder deactivation, variable displacement or other mode transitions;
9. representative recordings or measured order/spectral evidence when available;
10. source identifiers and evidence classification.

Missing primary evidence must remain visible. It does not authorize use of a convenient unrelated backend.

## Reuse decision

Use this decision in order:

1. **Same fundamental acoustic architecture and hardware family.** Reuse the architecture synthesizer and create a calibration-specific `EngineAudioProfile` or typed family resource.
2. **Same broad layout but materially different crank, firing, collector, combustion or aspiration topology.** Add a dedicated architecture/family synthesizer, sharing only low-level DSP utilities.
3. **Architecture absent.** Build the procedural source model from first principles and add deterministic signal tests before assigning it to a vehicle.
4. **Evidence or implementation incomplete.** Keep the variant unavailable. Do not assign a generic engine-audio fallback.

Shared filters, oscillators, saturation, sample-rate helpers, noise generators, turbo utilities and baking infrastructure are reusable. A primary combustion waveform, bank cadence or collector model is reusable only when the physical architecture is genuinely shared.

The base VQ backend is explicitly V6-specific and must not pretend to model another cylinder count. Changing a `cylinders` property, pitch scale or EQ is insufficient.

## Architecture implementation procedure

### 1. Define event timing

Implement the crank-cycle phase and exact firing sequence. For banked engines, preserve bank assignment and interval asymmetry. Tests must verify the expected firing frequency and dominant orders across RPM.

### 2. Build combustion pulses

Create a pulse shape appropriate to spark ignition, direct injection, compression ignition or other combustion type. Separate calibration parameters from the timing architecture. Output-specific profiles may alter sharpness, energy and envelopes, but may not alter the researched firing geometry.

### 3. Model intake and exhaust paths

Provide distinct intake, exhaust and mechanical paths. Where relevant include:

- individual-bank or grouped-collector exhaust resonances;
- unequal header/collector timing;
- plenum and runner resonances;
- throttle/airflow and induction transient noise;
- exhaust reflections, body/cabin/pickup-bed resonance and load-dependent roughness.

### 4. Model mechanical sources

Represent valvetrain, timing chain/gears, injector rattle, diesel clatter, rotating assembly and driveline/geartrain layers at their physically related orders. Commercial engines require appropriate low-speed/high-load and accessory character rather than a passenger-car profile shifted downward.

### 5. Model forced induction

Turbo or supercharger audio must be driven by a state model, not directly by RPM alone. Retain:

- spool state from exhaust energy/load and shaft inertia;
- compressor/turbine/VGT or sequential-stage behaviour;
- wastegate/bypass control;
- blow-off or compressor-release events only on a real pressure/throttle transition;
- flutter only under the appropriate operating condition;
- boost and induction/exhaust interaction;
- stage handover for sequential twin-turbo systems.

A limiter torque cut is not a pedal lift. It must not instantly erase spool, cut the turbo signal or trigger a false blow-off event. Turbo layers must be level-controlled so the complete turbocharged engine does not become louder solely because extra layers were added.

### 6. Implement operating states and transients

Cover:

- starter and cranking;
- catch and idle stabilization;
- idle irregularity/governor behaviour;
- throttle tip-in and tip-out;
- load without equivalent pedal position, including converter/clutch and grade effects;
- overrun and engine braking;
- gearshift torque reduction and rev matching;
- limiter/governor with residual combustion and continuous auxiliary/turbo state;
- shutdown run-down to digital silence.

The audio backend must consume truthful runtime telemetry: engine RPM, driver throttle, applied engine load/torque request, boost/spool state, clutch/converter/shift state and engine-running state. It must not infer load only from vehicle speed or selected gear.

## Family and calibration policy

Create one architecture/family backend for physically shared timing and routing, then separate profiles for materially different calibrations, intake/exhaust systems or aspiration controls.

Examples from the retained research:

- LV3 90-degree V6 must not use an inline-six or unrelated V6 waveform;
- L83 and L86 may share low-level Gen-V cross-plane V8 utilities but require separate displacement, combustion, intake/exhaust, inertia and AFM profiles;
- B38/H4B turbo inline-three requires true three-cylinder cadence;
- N55/B58 inline-six differs from a V6 in firing geometry and collector behaviour;
- EA189 single-turbo and BiTDI require different turbo state models;
- EA897 V6 TDI requires banked six-cylinder diesel timing rather than a shifted inline-four diesel;
- OM934 commercial inline-four requires engine-brake, low-speed load and driveline layers distinct from a passenger diesel;
- electric vehicles require motor/inverter/reduction/tyre audio and must not play an idling combustion loop.

Output variants remain separate profiles when boost, injection, governor, intake/exhaust or limiter calibration materially changes, even if they share the architecture backend.

## Repository integration

### Live player backend

Every player vehicle must use an explicit live architecture-correct synthesizer driven by runtime telemetry. Do not silently replace the player backend with baked samples or distance-suspended generation.

The live synthesizer must provide deterministic offline rendering compatible with:

`generate_test_frames(frame_count, rpm, load, throttle)`

It must expose validated profile/configuration resources and preserve finite, bounded output at supported sample rates.

### AI backend decision

Choose explicitly per model/family:

- **committed baked bank** through `BakedEngineAudioPlayer`; or
- **live synthesis** with a documented simultaneous-opponent performance budget.

A baked bank is preferred for scalable AI when it preserves identity. It must be generated from the correct live synthesizer, not from another engine family.

For a baked backend:

1. create an `EngineAudioBakePreset`;
2. define increasing RPM anchors and coast/load operating points;
3. bake and commit WAV files, `bank.tres` and manifest;
4. validate mono format, rate, duration, clips and exported-resource inclusion;
5. assign a dedicated AI scene when it differs from the player scene.

For a live AI backend, add a fleet benchmark representing the maximum supported simultaneous opponent count.

### Scene and catalog binding

Each exposed variant must bind explicitly to:

- the correct architecture synthesizer;
- a valid family/calibration profile;
- the correct live player scene;
- the selected and tested AI backend;
- no fallback scene or profile belonging to another layout.

Transmission type must not choose the engine backend implicitly.

## Level and mix contract

The complete engine output includes combustion, intake, exhaust, mechanical and forced-induction layers. Validation applies to their sum.

Required rules:

- samples remain finite and smoothly bounded;
- added turbo/mechanical layers do not create uncontrolled gain stacking;
- load operation is audibly distinct from idle/coast without clipping;
- engines are normalized to a catalog reference so turbocharged variants are not automatically louder than comparable naturally aspirated engines;
- model/family differences must come from character and dynamics, not arbitrary output gain;
- start, limiter and shutdown must not produce abrupt discontinuities unless physically intentional;
- LOD/backend changes must not cause large level jumps.

## Mandatory deterministic tests

### Signal and safety

Test:

- finite samples and peak bound;
- non-silent idle/load output where appropriate;
- digital silence after shutdown;
- sample-rate-invariant envelopes and anti-alias limits;
- deterministic rendering for a fixed seed/state;
- no buffer-state corruption or unbounded tail.

### Architecture identity

Test:

- expected firing frequency and dominant engine orders;
- bank/collector timing where applicable;
- meaningful waveform difference from unrelated architectures;
- distinct profiles for materially different engine families/calibrations;
- diesel, petrol, turbo, supercharged and electric-specific layers only where valid.

### Operating behaviour

Test:

- idle, coast and high-load energy/character;
- throttle/load decoupling;
- induction and boost spool/release;
- real pedal lift versus limiter torque cut;
- gearshift cut/rev-match continuity;
- overrun and engine-brake behaviour;
- starter/catch and shutdown;
- limiter cadence with residual combustion and no sudden turbo disappearance.

### Level validation

Test the summed output at representative RPM/load points:

- no clipping or excessive saturation;
- consistent catalog loudness reference;
- turbocharged total level does not exceed the allowed reference merely due to added turbo layers;
- profile gain changes remain within declared limits;
- perceptual identity remains after level normalization.

### Runtime and fleet validation

Test:

- player scenes use live synthesis and full runtime generation;
- AI scenes use the explicitly selected backend;
- baked banks are prepared and committed;
- live AI families have representative fleet budgets;
- backend matrix and production fleet benchmark are updated when opponent composition changes;
- Windows exports include every script, profile, bank and WAV.

## Acceptance review

Before exposing an engine family, record:

1. architecture evidence and unresolved facts;
2. reuse/new-backend decision;
3. synthesizer and profile paths;
4. player and AI backend decision;
5. firing/order and perceptual comparison results;
6. limiter/turbo/transient results;
7. loudness-normalization results;
8. runtime/fleet cost results;
9. export resource validation;
10. reviewer confirmation that no unrelated primary waveform is used.

## Catalog gate

An engine variant may be exposed only when:

- its architecture and calibration are explicitly bound;
- the fundamental timing/collector model is correct;
- all required operating states are implemented;
- summed-output level and safety tests pass;
- turbo/limiter behaviour is continuous and semantically correct;
- player and AI backends pass their respective runtime contracts;
- it is perceptually distinguishable from unrelated layouts after normalization;
- no generic fallback, pitch-only substitution or unrelated waveform remains.
