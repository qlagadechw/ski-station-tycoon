extends Node

# GameManager — central game state coordinator

signal game_started()
signal game_paused()
signal game_resumed()

var is_running: bool = false
var total_skiers_served: int = 0
var game_start_time: float = 0.0


func _ready() -> void:
	pass


func start_game() -> void:
	is_running = true
	game_start_time = Time.get_ticks_msec() / 1000.0
	TimeManager.set_speed(TimeManager.SpeedMode.NORMAL)
	emit_signal("game_started")


func pause_game() -> void:
	TimeManager.set_speed(TimeManager.SpeedMode.PAUSED)
	emit_signal("game_paused")


func resume_game() -> void:
	TimeManager.set_speed(TimeManager.SpeedMode.NORMAL)
	emit_signal("game_resumed")


func register_skier_served() -> void:
	total_skiers_served += 1
