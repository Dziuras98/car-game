extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_expect(OS.has_feature("windows"), "exported executable reports the Windows platform feature")
	_expect(not OS.has_feature("editor"), "smoke test runs from an export template, not the editor")
	_expect(ProjectSettings.get_setting("application/config/name", "") == "Car Game", "exported project settings contain the application name")
	_expect(CAR_CATALOG != null and not CAR_CATALOG.get_all_variants().is_empty(), "car catalog is present in the exported package")
	_expect(TRACK_CATALOG != null and TRACK_CATALOG.is_valid(), "track catalog is present and valid")
	_expect(SIMPLE_OVAL_LAYOUT != null and SIMPLE_OVAL_LAYOUT.is_valid(), "track layout Resource is present and valid")
	_expect(ResourceLoader.exists("res://scenes/cars/370zat.tscn"), "automatic car scene is included in the export")
	_expect(ResourceLoader.exists("res://scenes/cars/370z.tscn"), "manual car scene is included in the export")

	var original_locale: String = TranslationServer.get_locale()
	_expect(LocalizationCatalogLoader.ensure_loaded().is_empty(), "translation catalogs load from the exported package")
	TranslationServer.set_locale("en")
	_expect(tr("Wyniki") == "Results", "English catalog is usable in the exported package")
	_expect(tr("Okrążenie %d/%d") % [2, 3] == "Lap 2/3", "packaged translations preserve format placeholders")

	var main_instance: Node = MAIN_SCENE.instantiate()
	_expect(main_instance != null, "main scene instantiates from the exported package")
	if main_instance == null:
		TranslationServer.set_locale(original_locale)
		_finish()
		return

	add_child(main_instance)
	await get_tree().process_frame
	await get_tree().physics_frame

	var main_menu: Node = main_instance.get_node_or_null("MainMenu")
	_expect(main_menu != null, "main menu exists in the exported main scene")
	_expect(main_instance.get_node_or_null("Camera3D") != null, "follow camera exists in the exported main scene")
	_expect(main_instance.get_node_or_null("Speedometer") != null, "speedometer exists in the exported main scene")
	_expect(main_instance.get_node_or_null("Minimap") != null, "minimap exists in the exported main scene")
	_expect(main_instance.get_node_or_null("TrackContainer") != null, "runtime track container exists in the exported main scene")
	if main_menu != null:
		var menu_subtitle: Label = main_menu.get_node_or_null(
			"Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel"
		) as Label
		_expect(menu_subtitle != null and menu_subtitle.text == "Choose mode", "exported main menu renders English text")

	var speed_title: Label = main_instance.get_node_or_null("Speedometer/Panel/VBoxContainer/Title") as Label
	var gear_label: Label = main_instance.get_node_or_null(
		"Speedometer/Panel/VBoxContainer/GearRow/GearLabel"
	) as Label
	_expect(speed_title != null and speed_title.text == "SPEED", "exported speedometer renders its translated title")
	_expect(gear_label != null and gear_label.text == "GEAR", "exported speedometer renders its translated gear label")

	var results_screen: ResultsScreen = ResultsScreen.new()
	results_screen.build(self, Callable())
	var results_layer: CanvasLayer = get_node_or_null("ResultsScreen") as CanvasLayer
	var results_title: Label = results_layer.get_node_or_null(
		"Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel"
	) as Label if results_layer != null else null
	var results_menu_button: Button = results_layer.get_node_or_null(
		"Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuButton"
	) as Button if results_layer != null else null
	_expect(results_title != null and results_title.text == "Results", "exported results builder translates its title")
	_expect(results_menu_button != null and results_menu_button.text == "Return to menu", "exported results builder translates its menu action")
	if results_layer != null:
		results_layer.queue_free()

	var pause_menu: PauseMenu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	add_child(pause_menu)
	var pause_title: Label = pause_menu.get_node_or_null(
		"Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title"
	) as Label
	var resume_button: Button = pause_menu.get_node_or_null(
		"Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton"
	) as Button
	_expect(pause_title != null and pause_title.text == "Paused", "exported pause menu translates its title")
	_expect(resume_button != null and resume_button.text == "Resume", "exported pause menu translates its resume action")
	pause_menu.queue_free()

	var track: Node = main_instance.get_node_or_null("TrackContainer/ActiveTrack")
	_expect(track != null, "default catalog track is instantiated in the exported main scene")
	if track != null:
		_expect(track.has_method("get_racing_line_points"), "exported track exposes the racing-line API")
		_expect(track.has_method("get_checkpoint_count"), "exported track exposes checkpoint metadata")
		var racing_line: Array = track.call("get_racing_line_points")
		_expect(racing_line.size() == 108, "exported track generates the expected 108-point racing line")
		_expect(int(track.call("get_checkpoint_count")) == 3, "exported track exposes three intermediate checkpoints")
		_expect(int(track.call("get_checkpoint_gate_count")) == 4, "exported track builds the finish and checkpoint gates")
	_expect(main_instance.call("get_active_lap_count") == 3, "exported runtime applies track recommended lap metadata")

	TranslationServer.set_locale(original_locale)
	main_instance.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[EXPORTED_BUILD_SMOKE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[EXPORTED_BUILD_SMOKE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EXPORTED_BUILD_SMOKE_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[EXPORTED_BUILD_SMOKE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[EXPORTED_BUILD_SMOKE_TEST] - %s" % failure_message)
	get_tree().quit(1)
