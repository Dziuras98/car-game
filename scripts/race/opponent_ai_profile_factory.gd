extends RefCounted
class_name OpponentAiProfileFactory

const MIN_TARGET_SPEED_KMH: float = 96.0
const MAX_TARGET_SPEED_KMH: float = 128.0
const MIN_CORNER_SPEED_KMH: float = 66.0
const MAX_CORNER_SPEED_KMH: float = 84.0


func create_profile(session_seed: int, opponent_index: int, lane_offset: float) -> AiDriverProfile:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([session_seed, maxi(opponent_index, 0), "opponent_ai_profile"])

	var profile: AiDriverProfile = AiDriverProfile.new()
	profile.lane_offset = lane_offset
	profile.target_speed_kmh = rng.randf_range(MIN_TARGET_SPEED_KMH, MAX_TARGET_SPEED_KMH)
	profile.corner_speed_kmh = rng.randf_range(MIN_CORNER_SPEED_KMH, MAX_CORNER_SPEED_KMH)
	return profile
