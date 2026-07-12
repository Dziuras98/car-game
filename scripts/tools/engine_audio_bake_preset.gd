extends Resource
class_name EngineAudioBakePreset

@export var bank_id: String = ""
@export var profile: Resource
@export var synthesizer_script: Script
@export_dir var output_directory: String = ""
@export var sample_rpms: PackedInt32Array = PackedInt32Array([700, 1200, 2000, 3000, 4000, 5000, 6000, 7000, 7600])
@export_range(8000, 48000, 1000) var sample_rate: int = 32000
@export_range(0.0, 5.0, 0.01) var warmup_seconds: float = 0.50
@export_range(0.10, 10.0, 0.01) var loop_seconds: float = 1.00
@export_range(0.0, 0.25, 0.001) var boundary_correction_seconds: float = 0.025
@export_range(0.0, 1.0, 0.01) var coast_load: float = 0.08
@export_range(0.0, 1.0, 0.01) var coast_throttle: float = 0.02
@export_range(0.0, 1.0, 0.01) var loaded_load: float = 0.95
@export_range(0.0, 1.0, 0.01) var loaded_throttle: float = 0.92


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if bank_id.strip_edges().is_empty():
		errors.append("bank_id must not be empty")
	if profile == null:
		errors.append("profile must be assigned")
	elif not profile.has_method("is_valid") or not bool(profile.call("is_valid")):
		errors.append("profile must expose a valid is_valid() contract")
	elif not profile.has_method("apply_to"):
		errors.append("profile must expose apply_to(target)")
	if synthesizer_script == null or not synthesizer_script.can_instantiate():
		errors.append("synthesizer_script must be instantiable")
	if not output_directory.begins_with("res://") and not output_directory.begins_with("user://"):
		errors.append("output_directory must use res:// or user://")
	if sample_rpms.size() < 2:
		errors.append("sample_rpms must contain at least two anchors")
	var previous_rpm: int = 0
	for rpm: int in sample_rpms:
		if rpm <= previous_rpm:
			errors.append("sample_rpms must be positive and strictly increasing")
			break
		previous_rpm = rpm
	if sample_rate < 8000 or sample_rate > 48000:
		errors.append("sample_rate must be between 8000 and 48000")
	if not is_finite(warmup_seconds) or warmup_seconds < 0.0:
		errors.append("warmup_seconds must be finite and non-negative")
	if not is_finite(loop_seconds) or loop_seconds <= 0.0:
		errors.append("loop_seconds must be finite and positive")
	if (
		not is_finite(boundary_correction_seconds)
		or boundary_correction_seconds < 0.0
		or boundary_correction_seconds > loop_seconds * 0.25
	):
		errors.append("boundary_correction_seconds must be finite and at most one quarter of the loop")
	for operating_value: float in [coast_load, coast_throttle, loaded_load, loaded_throttle]:
		if not is_finite(operating_value) or operating_value < 0.0 or operating_value > 1.0:
			errors.append("operating-point values must be finite and between zero and one")
			break
	return errors
