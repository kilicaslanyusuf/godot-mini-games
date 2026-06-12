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
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

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
