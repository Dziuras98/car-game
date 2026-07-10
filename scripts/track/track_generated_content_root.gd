extends RefCounted
class_name TrackGeneratedContentRoot

const GENERATED_CONTENT_NAME: String = "GeneratedContent"


func get_or_create(owner: Node) -> Node3D:
	var existing: Node = owner.get_node_or_null(GENERATED_CONTENT_NAME)
	if existing is Node3D:
		return existing as Node3D

	return _create_container(owner)


func clear(owner: Node) -> Node3D:
	# A queued node remains discoverable until the end of the frame. Reusing the
	# same container therefore allowed builders that resolve children by name to
	# attach new collision shapes to nodes already scheduled for deletion.
	# Replace the whole generated subtree synchronously instead.
	var existing: Node = owner.get_node_or_null(GENERATED_CONTENT_NAME)
	if existing != null:
		owner.remove_child(existing)
		existing.queue_free()

	return _create_container(owner)


func _create_container(owner: Node) -> Node3D:
	var container: Node3D = Node3D.new()
	container.name = GENERATED_CONTENT_NAME
	owner.add_child(container)
	container.owner = owner.owner
	return container
