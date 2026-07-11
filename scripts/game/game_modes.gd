extends RefCounted
class_name GameModes

const FREE_DRIVE: String = "free_drive"
const RACE: String = "race"
const ALL: Array[String] = [FREE_DRIVE, RACE]


static func is_supported(mode_id: String) -> bool:
	return ALL.has(mode_id)
