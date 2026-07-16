# Physics and DPI validation matrix

This matrix defines the release gate for changes to the per-wheel vehicle solver and DPI v3.

## Runtime physics

- effective wheel and reflected drivetrain inertia;
- per-contact-patch road speed and longitudinal slip;
- wheel-space to chassis-space force transformation;
- complete yaw moment from longitudinal and lateral tire forces;
- two-pass load transfer based on achievable acceleration;
- suspension-support-weighted wheel load;
- combined longitudinal and lateral grip in the same substep;
- split-grip and asymmetric wheel-force behavior;
- differential torque redistribution;
- CVT with a configured minimum ratio and with an unbounded `0.0` minimum;
- vector aerodynamic resistance, banking and soft speed limiting.

## DPI v3

- the current Nissan 370Z 7AT resource remains the exact 1000-point reference;
- technical, mixed and fast course times remain finite for every catalog variant;
- increased rotating inertia cannot improve DPI;
- ABS and traction control improve repeatability without exceeding peak tire capacity;
- a positive CVT minimum ratio is respected, while `0.0` permits continuation toward the numerical epsilon;
- catalog ordering and large score changes are reviewed against sourced performance envelopes.

## Integration gate

The pull request may be merged only after the complete Godot 4.7 verification workflow, Windows export and smoke test pass on the final clean commit.
