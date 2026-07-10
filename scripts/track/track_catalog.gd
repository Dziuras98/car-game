extends Resource
class_name TrackCatalog

@export var tracks: Array[Resource] = []


func get_tracks() -> Array[TrackDefinition]:
	var result: Array[TrackDefinition] = []
	for resource: Resource in tracks:
		var definition: TrackDefinition = resource as TrackDefinition
		if definition != null:
			result.append(definition)
	return result


func get_track_by_id(track_id: StringName) -> TrackDefinition:
	for definition: TrackDefinition in get_tracks():
		if definition.track_id == track_id:
			return definition
	return null


func get_default_track() -> TrackDefinition:
	var definitions: Array[TrackDefinition] = get_tracks()
	for definition: TrackDefinition in definitions:
		if definition.is_default:
			return definition
	if definitions.is_empty():
		return null
	return definitions[0]


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var definitions: Array[TrackDefinition] = get_tracks()
	if definitions.size() != tracks.size():
		errors.append("all track entries must be TrackDefinition resources")
	if definitions.is_empty():
		errors.append("catalog must contain at least one track")
		return errors

	var used_ids: Dictionary = {}
	var default_count: int = 0
	for definition: TrackDefinition in definitions:
		if not definition.is_valid():
			errors.append("track definition '%s' is invalid" % str(definition.track_id))
		continue
		var id_key: String = str(definition.track_id)
		if used_ids.has(id_key):
			errors.append("track id '%s' is duplicated" % id_key)
		used_ids[id_key] = true
		if definition.is_default:
			default_count += 1
	if default_count != 1:
		errors.append("catalog must define exactly one default track")
	return errors


func is_valid() -> bool:
	return validate().is_empty()
