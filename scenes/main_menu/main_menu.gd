extends Control

## MainMenu — the game's main menu screen.


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Background gradient
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.05, 0.1, 0.25)
	add_child(bg)

	# Gradient overlay (mountain feel — dark blue at top, lighter at bottom)
	var grad_rect := ColorRect.new()
	grad_rect.name = "GradientOverlay"
	grad_rect.anchor_right = 1.0
	grad_rect.anchor_bottom = 1.0
	var grad_mat := CanvasItemMaterial.new()
	grad_rect.material = grad_mat
	# Top color darker, bottom lighter
	var sub_bg := ColorRect.new()
	sub_bg.anchor_right = 1.0
	sub_bg.anchor_top = 0.5
	sub_bg.anchor_bottom = 1.0
	sub_bg.color = Color(0.7, 0.85, 1.0, 0.3)
	add_child(sub_bg)

	# Mountain silhouette (decorative CSGBox-style using ColorRect panels)
	_add_mountain_silhouette()

	# Center VBox
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.name = "MenuVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.name = "Title"
	title.text = "🎿 Ski Station Tycoon"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Massif du Jura"
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	# New game button
	var new_game_btn := Button.new()
	new_game_btn.name = "NewGameButton"
	new_game_btn.text = "🎮 Nouvelle Partie"
	new_game_btn.custom_minimum_size = Vector2(300, 50)
	new_game_btn.add_theme_font_size_override("font_size", 22)
	new_game_btn.pressed.connect(_on_new_game)
	vbox.add_child(new_game_btn)

	# Options button (disabled)
	var options_btn := Button.new()
	options_btn.name = "OptionsButton"
	options_btn.text = "⚙️ Options"
	options_btn.custom_minimum_size = Vector2(300, 50)
	options_btn.add_theme_font_size_override("font_size", 22)
	options_btn.disabled = true
	vbox.add_child(options_btn)

	# Quit button
	var quit_btn := Button.new()
	quit_btn.name = "QuitButton"
	quit_btn.text = "🚪 Quitter"
	quit_btn.custom_minimum_size = Vector2(300, 50)
	quit_btn.add_theme_font_size_override("font_size", 22)
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

	# Version label
	var version := Label.new()
	version.name = "Version"
	version.text = "v0.1 — En développement"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	version.anchor_left = 0.0
	version.anchor_right = 1.0
	version.anchor_bottom = 1.0
	version.anchor_top = 1.0
	version.offset_top = -30
	version.offset_bottom = 0
	add_child(version)


func _add_mountain_silhouette() -> void:
	# Simple geometric mountain shapes as decorative background elements
	var mountains_data := [
		[0.0, 0.5, 0.25, 0.25, Color(0.15, 0.2, 0.4, 0.8)],
		[0.2, 0.55, 0.2, 0.2, Color(0.2, 0.25, 0.45, 0.7)],
		[0.6, 0.5, 0.25, 0.25, Color(0.15, 0.2, 0.4, 0.8)],
		[0.75, 0.55, 0.2, 0.2, Color(0.2, 0.25, 0.45, 0.7)],
	]
	for m in mountains_data:
		var rect := ColorRect.new()
		rect.anchor_left = m[0]
		rect.anchor_top = m[1]
		rect.anchor_right = m[0] + m[2]
		rect.anchor_bottom = 1.0
		rect.color = m[4]
		add_child(rect)


func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game_world.tscn")


func _on_quit() -> void:
	get_tree().quit()
