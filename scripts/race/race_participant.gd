extends RefCounted
class_name RaceParticipant


enum Kind {
	PLAYER,
	OPPONENT,
}


var _participant_id: StringName = &""
var _kind: Kind = Kind.OPPONENT
var _car: PlayerCarController
var _ordinal: int = 0
var _display_name: String = ""


func _init(
	id: StringName = &"",
	participant_kind: Kind = Kind.OPPONENT,
	participant_car: PlayerCarController = null,
	participant_ordinal: int = 0,
	custom_display_name: String = ""
) -> void:
	_participant_id = id
	_kind = participant_kind
	_car = participant_car
	_ordinal = participant_ordinal
	_display_name = custom_display_name


static func create_player(player_car: PlayerCarController) -> RaceParticipant:
	if not is_instance_valid(player_car):
		return null
	return RaceParticipant.new(&"player", Kind.PLAYER, player_car)


static func create_opponent(opponent_car: PlayerCarController, opponent_ordinal: int) -> RaceParticipant:
	if not is_instance_valid(opponent_car) or opponent_ordinal <= 0:
		return null
	return RaceParticipant.new(
		StringName("opponent_%d" % opponent_ordinal),
		Kind.OPPONENT,
		opponent_car,
		opponent_ordinal
	)


func is_valid() -> bool:
	if _participant_id == &"" or not is_instance_valid(_car):
		return false
	if _kind == Kind.PLAYER:
		return _ordinal == 0
	return _kind == Kind.OPPONENT and _ordinal > 0


func is_player() -> bool:
	return _kind == Kind.PLAYER


func get_participant_id() -> StringName:
	return _participant_id


func get_kind() -> Kind:
	return _kind


func get_car() -> PlayerCarController:
	return _car


func get_ordinal() -> int:
	return _ordinal


func set_display_name(display_name: String) -> void:
	_display_name = display_name


func get_display_name() -> String:
	return _display_name


func get_display_label() -> String:
	if not _display_name.is_empty():
		return _display_name
	if is_player():
		return tr("Ty")
	return tr("Kierowca %d") % _ordinal
