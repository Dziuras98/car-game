extends CarSpecs
class_name TrafficRiderCarSpecs

enum DataQuality {
	FACTORY_EXACT,
	EVIDENCE_CONSTRAINED_SIMULATION,
	ENGINEERING_ESTIMATE,
}

@export_group("Traffic Rider fidelity")
@export var data_quality: int = DataQuality.ENGINEERING_ESTIMATE
@export_range(0.0, 1.0, 0.01) var confidence_score: float = 0.50
@export var evidence_basis: String = ""
@export var simulated_fields := PackedStringArray()
@export var target_zero_100_s: float = 0.0
@export var target_top_speed_kph: float = 0.0

@export_group("Traffic Rider architecture")
@export var traffic_rider_powertrain_definition: TrafficRiderPowertrainDefinition
@export var inline_engine_audio_profile: TrafficRiderInlineEngineAudioProfile


func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if data_quality < DataQuality.FACTORY_EXACT or data_quality > DataQuality.ENGINEERING_ESTIMATE:
		errors.append("data_quality is invalid")
	if confidence_score <= 0.0 or confidence_score > 1.0:
		errors.append("confidence_score must be in (0, 1]")
	if data_quality != DataQuality.FACTORY_EXACT and evidence_basis.strip_edges().is_empty():
		errors.append("simulated Traffic Rider specs require an evidence_basis")
	if data_quality != DataQuality.FACTORY_EXACT and simulated_fields.is_empty():
		errors.append("simulated Traffic Rider specs require explicit simulated_fields")
	if target_zero_100_s <= 0.0:
		errors.append("target_zero_100_s must be positive")
	if target_top_speed_kph <= 0.0:
		errors.append("target_top_speed_kph must be positive")
	if traffic_rider_powertrain_definition == null:
		errors.append("traffic_rider_powertrain_definition must not be null")
	if inline_engine_audio_profile == null:
		errors.append("inline_engine_audio_profile must not be null")
	else:
		for audio_error: String in inline_engine_audio_profile.validate():
			errors.append("inline_engine_audio_profile: %s" % audio_error)
	return errors
