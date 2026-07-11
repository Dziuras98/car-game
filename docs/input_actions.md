# Input action contract

The canonical runtime action identifiers are defined in:

```text
scripts/input/game_input_actions.gd
```

Runtime code must use the `GameInputActions` `StringName` constants instead of repeating action-name string literals. The class separates the project-defined required action set, analog actions and built-in Godot UI actions used by runtime code.

## Required actions

The project-defined contract covers:

- throttle and brake;
- left and right steering;
- handbrake and car reset;
- rear camera, pause and free-drive car switching;
- manual gear up and gear down.

`GameInputActions.UI_CANCEL` owns the built-in Godot `ui_cancel` identifier used for menu navigation. It is intentionally not part of `REQUIRED_ACTIONS`, because its default engine mapping is not configured by this project.

Keyboard and gamepad bindings remain configured in `project.godot`. The action class owns identifiers only; it does not override user-facing bindings or deadzone values at runtime.

## Validation

`scripts/tests/input_mapping_test.gd` validates the project-defined contract against the imported `InputMap`:

- every required identifier is unique and exists;
- every required action has keyboard and gamepad input;
- analog actions have an `InputEventJoypadMotion` binding;
- every deadzone is normalized;
- analog deadzones remain at or below the contract maximum;
- left and right steering use the same deadzone.

`scripts/ci/validate_input_action_literals.ps1` recursively scans production GDScript and rejects raw action-name literals passed to Godot input APIs. The only excluded locations are the canonical `GameInputActions` definition and `scripts/tests/**`, where deterministic fixtures may synthesize input directly. Multi-action calls such as `Input.get_axis()` and `Input.get_vector()` are checked argument by argument.

`scripts/ci/test_input_action_literal_validation.ps1` runs the scanner against a temporary project tree. It verifies detection of `Input`, `InputMap` and `InputEvent` calls, multiline axis arguments, project-relative line diagnostics and the two intentional exclusions.

This keeps input tuning in project configuration while preventing spelling drift and invalid mappings in runtime code.
