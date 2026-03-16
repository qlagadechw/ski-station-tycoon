extends Node

signal time_tick(game_date: Dictionary)
signal season_changed(new_season: String)
signal snow_started()
signal snow_ended()
signal day_changed(day: int, month: int, year: int)
signal month_changed(month: int, year: int)

enum Season { AUTUMN, WINTER, SPRING, SUMMER }
enum SpeedMode { PAUSED, NORMAL, FAST, ULTRA }

const REAL_SECONDS_PER_GAME_DAY := {
	SpeedMode.PAUSED: 0.0,
	SpeedMode.NORMAL: 60.0,
	SpeedMode.FAST: 30.0,
	SpeedMode.ULTRA: 20.0,
}

const DAYS_IN_MONTH := [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

const SEASON_NAMES := {
	Season.AUTUMN: "Automne",
	Season.WINTER: "Hiver",
	Season.SPRING: "Printemps",
	Season.SUMMER: "Été",
}

var current_day: int = 1
var current_month: int = 9
var current_year: int = 2024
var current_season: Season = Season.AUTUMN
var current_speed: SpeedMode = SpeedMode.NORMAL
var time_scale: float = 1.0
var day_progress: float = 0.0
var is_snow_season: bool = false
var snow_coverage: float = 0.0

var _elapsed: float = 0.0


func _ready() -> void:
	_update_season()
	_update_snow()


func _process(delta: float) -> void:
	if current_speed == SpeedMode.PAUSED:
		return

	var seconds_per_day: float = REAL_SECONDS_PER_GAME_DAY[current_speed]
	if seconds_per_day <= 0.0:
		return

	_elapsed += delta
	day_progress = clampf(_elapsed / seconds_per_day, 0.0, 1.0)

	if _elapsed >= seconds_per_day:
		_elapsed -= seconds_per_day
		_advance_day()


func _advance_day() -> void:
	current_day += 1
	var days_this_month: int = DAYS_IN_MONTH[current_month]
	if current_day > days_this_month:
		current_day = 1
		_advance_month()

	_update_snow()
	emit_signal("day_changed", current_day, current_month, current_year)
	emit_signal("time_tick", get_date_dict())


func _advance_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1

	var old_season := current_season
	_update_season()
	if current_season != old_season:
		emit_signal("season_changed", SEASON_NAMES[current_season])

	emit_signal("month_changed", current_month, current_year)


func _update_season() -> void:
	match current_month:
		9, 10, 11:
			current_season = Season.AUTUMN
		12, 1, 2:
			current_season = Season.WINTER
		3, 4, 5:
			current_season = Season.SPRING
		_:
			current_season = Season.SUMMER


func _update_snow() -> void:
	# Snow season: November 20 to April 25
	var snow_start_month := 11
	var snow_start_day := 20
	var snow_end_month := 4
	var snow_end_day := 25

	var was_snow := is_snow_season

	var after_start := (current_month > snow_start_month) or \
		(current_month == snow_start_month and current_day >= snow_start_day)
	var before_end := (current_month < snow_end_month) or \
		(current_month == snow_end_month and current_day <= snow_end_day)

	# Handle year boundary (snow spans across January)
	if current_month >= snow_start_month or current_month <= snow_end_month:
		if current_month >= snow_start_month:
			is_snow_season = after_start
		else:
			is_snow_season = before_end
	else:
		is_snow_season = false

	# Update snow coverage based on date
	if is_snow_season:
		# Build up coverage over first 15 days of snow season
		if current_month == snow_start_month and current_day < snow_start_day + 15:
			var days_in := float(current_day - snow_start_day + 1)
			snow_coverage = clampf(days_in / 15.0, 0.0, 1.0)
		elif current_month == snow_end_month and current_day > snow_end_day - 15:
			var days_left := float(snow_end_day - current_day + 1)
			snow_coverage = clampf(days_left / 15.0, 0.0, 1.0)
		else:
			snow_coverage = 1.0
	else:
		snow_coverage = 0.0

	if is_snow_season and not was_snow:
		emit_signal("snow_started")
	elif not is_snow_season and was_snow:
		emit_signal("snow_ended")


func set_speed(mode: SpeedMode) -> void:
	current_speed = mode
	match mode:
		SpeedMode.PAUSED:
			time_scale = 0.0
		SpeedMode.NORMAL:
			time_scale = 1.0
		SpeedMode.FAST:
			time_scale = 2.0
		SpeedMode.ULTRA:
			time_scale = 3.0


func get_date_string() -> String:
	return "%02d/%02d/%04d" % [current_day, current_month, current_year]


func get_date_dict() -> Dictionary:
	return {
		"day": current_day,
		"month": current_month,
		"year": current_year,
		"season": SEASON_NAMES[current_season],
		"snow": is_snow_season,
		"snow_coverage": snow_coverage,
	}


func get_season_emoji() -> String:
	match current_season:
		Season.AUTUMN:
			return "🍂"
		Season.WINTER:
			return "❄️"
		Season.SPRING:
			return "🌸"
		Season.SUMMER:
			return "☀️"
	return "🍂"
