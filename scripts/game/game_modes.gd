extends RefCounted
class_name GameModes

const FREE_DRIVE: StringName = &"free_drive"
# Compatibility identifier for old tests and serialized scripts. It is intentionally unsupported.
const RACE: StringName = &"removed_race_mode"
const ALL: Array[StringName] = [FREE_DRIVE]


static func is_supported(mode_id: StringName) -> bool:
	return mode_id == FREE_DRIVE
