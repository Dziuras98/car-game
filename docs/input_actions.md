# Input action contract

The canonical runtime action identifiers are defined in:

```text
scripts/input/game_input_actions.gd
```

Runtime code must use the `GameInputActions` `StringName` constants instead of repeating action-name string literals. The class separates the complete required action set from actions that require analog axis bindings.

## Required actions

The contract covers:

- throttle and brake;
- left and right steering;
- handbrake and car reset;
- rear camera, pause and free-drive car switching;
- manual gear up and gear down.

Keyboard and gamepad bindings remain configured in `project.godot`. The action class owns identifiers only; it does not override user-facing bindings or deadzone values at runtime.

## Validation

`scripts/tests/input_mapping_test.gd` validates the contract against the imported `InputMap`:

- every required identifier is unique and exists;
- every required action has keyboard and gamepad input;
- analog actions have an `InputEventJoypadMotion` binding;
- every deadzone is normalized;
- analog deadzones remain at or below the contract maximum;
- left and right steering use the same deadzone.

This keeps input tuning in project configuration while preventing spelling drift and invalid mappings in runtime code.
