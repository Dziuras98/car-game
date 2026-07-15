extends MainMenu
class_name ModeFilteredMainMenu


func _show_track_step() -> void:
	_show_selection_panel()
	_current_step = STEP_TRACK
	_selected_track_id = &""
	_selected_car_index = -1
	_title_label.text = tr("Wybierz tor")
	_subtitle_label.text = "%s: %s" % [tr("Tryb"), _get_mode_label(_selected_mode_id)]
	_back_button.visible = true
	_clear_options()

	var available_tracks: Array[TrackMenuOption] = []
	for track_option: TrackMenuOption in _track_options:
		if (
			track_option != null
			and track_option.is_valid()
			and track_option.supports_mode(_selected_mode_id)
		):
			available_tracks.append(track_option)

	if available_tracks.is_empty():
		_show_configuration_error(tr("Brak dostępnych torów"))
		return

	# Free-drive-only spaces are utility maps rather than race circuits. Keep them
	# above the shared circuit list without changing the production catalog order.
	if _selected_mode_id == GameModes.FREE_DRIVE:
		for track_option: TrackMenuOption in available_tracks:
			if _is_free_drive_only(track_option):
				_add_track_option_button(track_option)

	for track_option: TrackMenuOption in available_tracks:
		if _selected_mode_id == GameModes.FREE_DRIVE and _is_free_drive_only(track_option):
			continue
		_add_track_option_button(track_option)
	_focus_first_option()


func _on_track_pressed(track_id: StringName) -> void:
	var track_option: TrackMenuOption = _find_track_option(track_id)
	if track_option == null or not track_option.supports_mode(_selected_mode_id):
		_show_configuration_error(tr("Wybrany tor nie jest dostępny"))
		return
	_selected_track_id = track_id
	_show_car_step()


func _focus_first_option() -> void:
	for child: Node in _options.get_children():
		if child is Button:
			_defer_focus(child as Button)
			return
	_focus_back_button()


func _focus_back_button() -> void:
	if _back_button.visible:
		_defer_focus(_back_button)


func _defer_focus(control: Control) -> void:
	_grab_focus_if_available.call_deferred(control)


func _grab_focus_if_available(control: Control) -> void:
	if not is_instance_valid(control) or not control.is_inside_tree():
		return
	if not control.is_visible_in_tree():
		return
	control.grab_focus()


func _add_track_option_button(track_option: TrackMenuOption) -> void:
	_add_option_button(
		track_option.label,
		Callable(self, "_on_track_pressed").bind(track_option.track_id)
	)


func _is_free_drive_only(track_option: TrackMenuOption) -> bool:
	return (
		track_option.supports_mode(GameModes.FREE_DRIVE)
		and not track_option.supports_mode(GameModes.RACE)
	)
