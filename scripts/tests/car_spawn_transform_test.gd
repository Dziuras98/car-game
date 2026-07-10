extends Node

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var world: Node3D = Node3D.new()
	world.transform = Transform3D(Basis(Vector3.UP, 0.47), Vector3(18.0, 3.0, -11.0))
	add_child(world)

	var spawn_marker: Node3D = Node3D.new()
	spawn_marker.transform = Transform3D(Basis(Vector3.UP, -0.23), Vector3(4.0, 1.0, 7.0))
	world.add_child(spawn_marker)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	var factory: CarInstanceFactory = CarInstanceFactory.new()
	factory.configure(CATALOG.get_variant_scene_list(), CATALOG.get_all_variants(), rng)

	_test_player_spawn(world, factory)
	_test_opponent_spawn(world, spawn_marker, factory, rng)

	world.queue_free()
	await get_tree().process_frame
	_finish()


func _test_player_spawn(world: Node3D, factory: CarInstanceFactory) -> void:
	var target_transform: Transform3D = Transform3D(Basis(Vector3.UP, 0.81), Vector3(-24.0, 2.5, 36.0))
	var spawner: PlayerCarSpawnController = PlayerCarSpawnController.new()
	spawner.configure(world, factory)
	var car: PlayerCarController = spawner.spawn_player_car(0, target_transform, false)
	_expect(car != null, "player car spawns under a transformed owner")
	if car != null:
		_expect(_transforms_match(car.global_transform, target_transform), "player spawn preserves the requested global transform")
	spawner.clear_current_car()


func _test_opponent_spawn(
	world: Node3D,
	spawn_marker: Node3D,
	factory: CarInstanceFactory,
	rng: RandomNumberGenerator
) -> void:
	var layout: OpponentSpawnLayout = OpponentSpawnLayout.new()
	layout.configure(4.2, 7.0)
	var expected_transform: Transform3D = layout.get_spawn_transform(spawn_marker, 0)
	var paint_randomizer: OpponentPaintRandomizer = OpponentPaintRandomizer.new()
	paint_randomizer.configure(rng)
	var spawner: OpponentParticipantSpawner = OpponentParticipantSpawner.new()
	spawner.configure(world, spawn_marker, null, factory, layout, paint_randomizer, rng)
	var opponents: Array[PlayerCarController] = spawner.spawn_opponents(1)
	_expect(opponents.size() == 1, "one opponent spawns under a transformed owner")
	if opponents.size() == 1:
		_expect(_transforms_match(opponents[0].global_transform, expected_transform), "opponent spawn preserves the computed global transform")
	spawner.clear_opponents()


func _transforms_match(left: Transform3D, right: Transform3D) -> bool:
	return (
		left.origin.distance_to(right.origin) <= 0.001
		and left.basis.x.distance_to(right.basis.x) <= 0.001
		and left.basis.y.distance_to(right.basis.y) <= 0.001
		and left.basis.z.distance_to(right.basis.z) <= 0.001
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_SPAWN_TRANSFORM_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_SPAWN_TRANSFORM_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_SPAWN_TRANSFORM_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[CAR_SPAWN_TRANSFORM_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_SPAWN_TRANSFORM_TEST] - %s" % failure_message)
	get_tree().quit(1)
