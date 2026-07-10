extends Resource
class_name TrackCatalog

@export var tracks: Array[Resource] = []
@export var default_track_id: StringName = &""


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
	if default_track_id == &"":
		return null
	return get_track_by_id(default_track_id)


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var definitions: Array[TrackDefinition] = get_tracks()
	if definitions.size() != tracks.size():
		errors.append("all track entries must be TrackDefinition resources")
	if definitions.is_empty():
		errors.append("catalog must contain at least one track")
		return errors

	var used_ids: Dictionary = {}
	for definition: TrackDefinition in definitions:
		if not definition.is_valid():
			errors.append("track definition '%s' is invalid" % str(definition.track_id))
			continue
		var id_key: String = str(definition.track_id)
		if used_ids.has(id_key):
			errors.append("track id '%s' is duplicated" % id_key)
		used_ids[id_key] = true

	if default_track_id == &"":
		errors.append("catalog must define default_track_id")
	elif not used_ids.has(str(default_track_id)):
		errors.append("default_track_id '%s' does not reference a valid track" % str(default_track_id))
	return errors


func is_valid() -> bool:
	return validate().is_empty()
