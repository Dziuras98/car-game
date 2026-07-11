extends RefCounted
class_name GameModes

const FREE_DRIVE: StringName = &"free_drive"
const RACE: StringName = &"race"
const ALL: Array[StringName] = [FREE_DRIVE, RACE]


static func is_supported(mode_id: StringName) -> bool:
	return ALL.has(mode_id)
