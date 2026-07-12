extends RefCounted
class_name AiDriverProfile

var lane_offset: float = 0.0
var lookahead_points: int = 5
var target_speed_kmh: float = 118.0
var corner_speed_kmh: float = 78.0
var waypoint_reach_distance: float = 8.0
var search_points_behind: int = 4
var search_points_ahead: int = 14
var recovery_search_distance: float = 45.0
var full_search_interval_updates: int = 120
var stuck_detection_seconds: float = 1.5
var recovery_stop_speed_kmh: float = 1.0
var reverse_engage_timeout_seconds: float = 1.5
var reverse_recovery_distance: float = 3.0
var reverse_recovery_seconds: float = 2.5


func duplicate_profile() -> AiDriverProfile:
	var profile: AiDriverProfile = AiDriverProfile.new()
	profile.lane_offset = lane_offset
	profile.lookahead_points = lookahead_points
	profile.target_speed_kmh = target_speed_kmh
	profile.corner_speed_kmh = corner_speed_kmh
	profile.waypoint_reach_distance = waypoint_reach_distance
	profile.search_points_behind = search_points_behind
	profile.search_points_ahead = search_points_ahead
	profile.recovery_search_distance = recovery_search_distance
	profile.full_search_interval_updates = full_search_interval_updates
	profile.stuck_detection_seconds = stuck_detection_seconds
	profile.recovery_stop_speed_kmh = recovery_stop_speed_kmh
	profile.reverse_engage_timeout_seconds = reverse_engage_timeout_seconds
	profile.reverse_recovery_distance = reverse_recovery_distance
	profile.reverse_recovery_seconds = reverse_recovery_seconds
	return profile


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not is_finite(lane_offset):
		errors.append("lane_offset must be finite")
	if lookahead_points < 1:
		errors.append("lookahead_points must be at least one")
	if not is_finite(target_speed_kmh) or target_speed_kmh <= 0.0:
		errors.append("target_speed_kmh must be finite and greater than zero")
	if not is_finite(corner_speed_kmh) or corner_speed_kmh <= 0.0:
		errors.append("corner_speed_kmh must be finite and greater than zero")
	elif is_finite(target_speed_kmh) and corner_speed_kmh > target_speed_kmh:
		errors.append("corner_speed_kmh must not exceed target_speed_kmh")
	if not is_finite(waypoint_reach_distance) or waypoint_reach_distance <= 0.0:
		errors.append("waypoint_reach_distance must be finite and greater than zero")
	if search_points_behind < 0:
		errors.append("search_points_behind must be non-negative")
	if search_points_ahead < 0:
		errors.append("search_points_ahead must be non-negative")
	if search_points_behind + search_points_ahead < 1:
		errors.append("the racing-line search window must contain at least two points")
	if not is_finite(recovery_search_distance) or recovery_search_distance <= 0.0:
		errors.append("recovery_search_distance must be finite and greater than zero")
	if full_search_interval_updates < 1:
		errors.append("full_search_interval_updates must be at least one")
	if not is_finite(stuck_detection_seconds) or stuck_detection_seconds <= 0.0:
		errors.append("stuck_detection_seconds must be finite and greater than zero")
	if not is_finite(recovery_stop_speed_kmh) or recovery_stop_speed_kmh <= 0.0:
		errors.append("recovery_stop_speed_kmh must be finite and greater than zero")
	if not is_finite(reverse_engage_timeout_seconds) or reverse_engage_timeout_seconds <= 0.0:
		errors.append("reverse_engage_timeout_seconds must be finite and greater than zero")
	if not is_finite(reverse_recovery_distance) or reverse_recovery_distance <= 0.0:
		errors.append("reverse_recovery_distance must be finite and greater than zero")
	if not is_finite(reverse_recovery_seconds) or reverse_recovery_seconds <= 0.0:
		errors.append("reverse_recovery_seconds must be finite and greater than zero")
	return errors
