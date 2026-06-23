extends Node

var last_game := "collector"

var fullscreen_enabled := false
var master_volume := 100
var settings_path := "user://settings.cfg"

func _ready():
	load_settings()
	apply_settings()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(settings_path)

	if err == OK:
		fullscreen_enabled = bool(config.get_value("video", "fullscreen", false))
		master_volume = int(config.get_value("audio", "master_volume", 100))
	else:
		fullscreen_enabled = false
		master_volume = 100

	master_volume = clampi(master_volume, 0, 100)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen_enabled)
	config.set_value("audio", "master_volume", master_volume)
	config.save(settings_path)

func apply_settings():
	apply_display_settings()
	apply_audio_settings()

func apply_display_settings():
	var window = get_window()
	if window == null:
		return

	var screen = DisplayServer.window_get_current_screen()
	var screen_pos = DisplayServer.screen_get_position(screen)
	var screen_size = DisplayServer.screen_get_size(screen)

	if fullscreen_enabled:
		window.mode = Window.MODE_WINDOWED
		window.borderless = true
		window.position = screen_pos
		window.size = screen_size
	else:
		window.borderless = false
		window.mode = Window.MODE_WINDOWED

		var windowed_size = Vector2i(1152, 648)
		window.size = windowed_size
		window.position = Vector2i(
			screen_pos.x + int((screen_size.x - windowed_size.x) / 2),
			screen_pos.y + int((screen_size.y - windowed_size.y) / 2)
		)

func apply_audio_settings():
	var bus_index = AudioServer.get_bus_index("Master")

	if bus_index == -1:
		return

	if master_volume <= 0:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		var linear_volume = float(master_volume) / 100.0
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_volume))

func toggle_fullscreen():
	fullscreen_enabled = not fullscreen_enabled
	apply_display_settings()
	save_settings()

func change_master_volume(amount: int):
	master_volume = clampi(master_volume + amount, 0, 100)
	apply_audio_settings()
	save_settings()
