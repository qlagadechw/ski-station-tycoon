extends CanvasLayer

## HUD — heads-up display showing game state and build controls.

var _balance_label: Label
var _date_label: Label
var _season_label: Label
var _skier_label: Label
var _snow_bar: ProgressBar
var _snow_label: Label

var _speed_buttons: Array = []
var _build_panel: Control
var _slope_submenu: Control
var _lift_submenu: Control


func _ready() -> void:
	_build_ui()
	_connect_signals()


func _build_ui() -> void:
	# ---- Top bar ----
	var top_bar := PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_right = 1.0
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 20)
	top_bar.add_child(top_hbox)

	# Balance
	_balance_label = Label.new()
	_balance_label.name = "BalanceLabel"
	_balance_label.text = "💰 500 000 €"
	_balance_label.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(_balance_label)

	# Date
	_date_label = Label.new()
	_date_label.name = "DateLabel"
	_date_label.text = "📅 01/09/2024"
	_date_label.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(_date_label)

	# Season
	_season_label = Label.new()
	_season_label.name = "SeasonLabel"
	_season_label.text = "🍂 Automne"
	_season_label.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(_season_label)

	# Skier count
	_skier_label = Label.new()
	_skier_label.name = "SkierLabel"
	_skier_label.text = "⛷️ 0"
	_skier_label.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(_skier_label)

	# Snow bar
	var snow_container := HBoxContainer.new()
	top_hbox.add_child(snow_container)

	_snow_label = Label.new()
	_snow_label.text = "❄️ Neige:"
	_snow_label.add_theme_font_size_override("font_size", 16)
	snow_container.add_child(_snow_label)

	_snow_bar = ProgressBar.new()
	_snow_bar.min_value = 0.0
	_snow_bar.max_value = 1.0
	_snow_bar.value = 0.0
	_snow_bar.custom_minimum_size = Vector2(100, 20)
	snow_container.add_child(_snow_bar)

	# ---- Speed control (bottom-right) ----
	var speed_panel := PanelContainer.new()
	speed_panel.name = "SpeedPanel"
	speed_panel.anchor_left = 1.0
	speed_panel.anchor_right = 1.0
	speed_panel.anchor_top = 1.0
	speed_panel.anchor_bottom = 1.0
	speed_panel.offset_left = -220.0
	speed_panel.offset_top = -60.0
	speed_panel.offset_right = 0.0
	speed_panel.offset_bottom = 0.0
	add_child(speed_panel)

	var speed_hbox := HBoxContainer.new()
	speed_panel.add_child(speed_hbox)

	var speed_labels := ["⏸", "▶", "▶▶", "▶▶▶"]
	for i in range(speed_labels.size()):
		var btn := Button.new()
		btn.text = speed_labels[i]
		btn.custom_minimum_size = Vector2(50, 40)
		btn.pressed.connect(_on_speed_pressed.bind(i))
		speed_hbox.add_child(btn)
		_speed_buttons.append(btn)

	# ---- Build menu (bottom-center) ----
	_build_panel = PanelContainer.new()
	_build_panel.name = "BuildPanel"
	_build_panel.anchor_left = 0.5
	_build_panel.anchor_right = 0.5
	_build_panel.anchor_top = 1.0
	_build_panel.anchor_bottom = 1.0
	_build_panel.offset_left = -200.0
	_build_panel.offset_right = 200.0
	_build_panel.offset_top = -120.0
	_build_panel.offset_bottom = 0.0
	add_child(_build_panel)

	var build_vbox := VBoxContainer.new()
	_build_panel.add_child(build_vbox)

	# Sub-menus
	_slope_submenu = _create_slope_submenu()
	_slope_submenu.visible = false
	build_vbox.add_child(_slope_submenu)

	_lift_submenu = _create_lift_submenu()
	_lift_submenu.visible = false
	build_vbox.add_child(_lift_submenu)

	# Main build buttons
	var build_hbox := HBoxContainer.new()
	build_hbox.add_theme_constant_override("separation", 10)
	build_vbox.add_child(build_hbox)

	var hub_btn := Button.new()
	hub_btn.text = "🔵 Hub"
	hub_btn.custom_minimum_size = Vector2(110, 44)
	hub_btn.pressed.connect(_on_build_hub)
	build_hbox.add_child(hub_btn)

	var slope_btn := Button.new()
	slope_btn.text = "⛷️ Piste"
	slope_btn.custom_minimum_size = Vector2(110, 44)
	slope_btn.pressed.connect(_on_build_slope_menu)
	build_hbox.add_child(slope_btn)

	var lift_btn := Button.new()
	lift_btn.text = "🚡 Remontée"
	lift_btn.custom_minimum_size = Vector2(130, 44)
	lift_btn.pressed.connect(_on_build_lift_menu)
	build_hbox.add_child(lift_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "✖ Annuler"
	cancel_btn.custom_minimum_size = Vector2(110, 44)
	cancel_btn.pressed.connect(_on_build_cancel)
	build_hbox.add_child(cancel_btn)


func _create_slope_submenu() -> Control:
	var hbox := HBoxContainer.new()
	hbox.name = "SlopeSubmenu"
	var difficulties := [["🟢 Verte", 0], ["🔵 Bleue", 1], ["🔴 Rouge", 2], ["⬛ Noire", 3]]
	for d in difficulties:
		var btn := Button.new()
		btn.text = d[0]
		btn.custom_minimum_size = Vector2(90, 36)
		btn.pressed.connect(_on_slope_difficulty_selected.bind(d[1]))
		hbox.add_child(btn)
	return hbox


func _create_lift_submenu() -> Control:
	var hbox := HBoxContainer.new()
	hbox.name = "LiftSubmenu"
	var lifts := [
		["Téléski", 0],
		["T4", 1],
		["T6", 2],
		["TC8", 3],
		["Téléphérique", 4],
	]
	for l in lifts:
		var btn := Button.new()
		btn.text = l[0]
		btn.custom_minimum_size = Vector2(90, 36)
		btn.pressed.connect(_on_lift_type_selected.bind(l[1]))
		hbox.add_child(btn)
	return hbox


func _connect_signals() -> void:
	EconomyManager.balance_changed.connect(_on_balance_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	TimeManager.season_changed.connect(_on_season_changed)
	TimeManager.snow_started.connect(_on_snow_changed)
	TimeManager.snow_ended.connect(_on_snow_changed)


func _process(_delta: float) -> void:
	# Update skier count
	var skier_count := get_tree().get_nodes_in_group("skiers").size()
	_skier_label.text = "⛷️ %d" % skier_count
	# Update snow bar
	_snow_bar.value = TimeManager.snow_coverage


func _on_balance_changed(new_balance: float) -> void:
	_balance_label.text = "💰 " + EconomyManager.format_money(new_balance)
	if new_balance < 0.0:
		_balance_label.add_theme_color_override("font_color", Color.RED)
	else:
		_balance_label.remove_theme_color_override("font_color")


func _on_day_changed(day: int, month: int, year: int) -> void:
	_date_label.text = "📅 %02d/%02d/%04d" % [day, month, year]


func _on_season_changed(_season: String) -> void:
	_season_label.text = TimeManager.get_season_emoji() + " " + _season


func _on_snow_changed() -> void:
	_snow_bar.value = TimeManager.snow_coverage


func _on_speed_pressed(idx: int) -> void:
	TimeManager.set_speed(idx as TimeManager.SpeedMode)
	for i in range(_speed_buttons.size()):
		_speed_buttons[i].button_pressed = (i == idx)


func _on_build_hub() -> void:
	_slope_submenu.visible = false
	_lift_submenu.visible = false
	BuildManager.enter_build_mode(BuildManager.BuildMode.HUB)


func _on_build_slope_menu() -> void:
	_slope_submenu.visible = not _slope_submenu.visible
	_lift_submenu.visible = false


func _on_build_lift_menu() -> void:
	_lift_submenu.visible = not _lift_submenu.visible
	_slope_submenu.visible = false


func _on_build_cancel() -> void:
	_slope_submenu.visible = false
	_lift_submenu.visible = false
	BuildManager.exit_build_mode()


func _on_slope_difficulty_selected(difficulty: int) -> void:
	BuildManager.selected_slope_difficulty = difficulty as BuildManager.SlopeDifficulty
	BuildManager.enter_build_mode(BuildManager.BuildMode.SLOPE)
	_slope_submenu.visible = false


func _on_lift_type_selected(lift_type: int) -> void:
	BuildManager.selected_lift_type = lift_type as BuildManager.LiftType
	BuildManager.enter_build_mode(BuildManager.BuildMode.LIFT)
	_lift_submenu.visible = false
