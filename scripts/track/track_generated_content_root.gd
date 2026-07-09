extends RefCounted
class_name TrackGeneratedContentRoot

const GENERATED_CONTENT_NAME: String = "GeneratedContent"


func get_or_create(owner: Node) -> Node3D:
	var existing: Node = owner.get_node_or_null(GENERATED_CONTENT_NAME)
	if existing is Node3D:
		return existing as Node3D

	var container: Node3D = Node3D.new()
	container.name = GENERATED_CONTENT_NAME
	owner.add_child(container)
	container.owner = owner.owner
	return container


func clear(owner: Node) -> Node3D:
	var container: Node3D = get_or_create(owner)
	for child: Node in container.get_children():
		child.queue_free()
	return container
