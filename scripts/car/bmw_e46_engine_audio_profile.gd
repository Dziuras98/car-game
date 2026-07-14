extends EngineAudioProfile
class_name BmwE46EngineAudioProfile

@export_group("Architecture")
@export_range(4, 12, 1) var cylinders: int = 6
@export var engine_layout: String = "inline"
@export var firing_order: String = ""
@export var aspiration: String = "naturally_aspirated"
@export var family_id: StringName = &""
@export_range(1.0, 40.0, 0.5) var rpm_smoothing: float = 13.0
@export_range(1.0, 40.0, 0.5) var throttle_smoothing: float = 17.0

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if cylinders < 4 or cylinders > 12:
		errors.append("cylinders must be between 4 and 12")
	if engine_layout.strip_edges().is_empty():
		errors.append("engine_layout must not be empty")
	if family_id == &"":
		errors.append("family_id must not be empty")
	if rpm_smoothing < 1.0 or rpm_smoothing > 40.0:
		errors.append("rpm_smoothing must be between 1 and 40")
	if throttle_smoothing < 1.0 or throttle_smoothing > 40.0:
		errors.append("throttle_smoothing must be between 1 and 40")
	return errors
