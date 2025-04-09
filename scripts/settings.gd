extends Control

const CONFIG_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

# Referências aos nós de UI
@onready var music_slider: HSlider = %MusicSlider
@onready var music_value_label: Label = %MusicValueLabel
@onready var music_mute_checkbox: CheckBox = %MusicMuteCheckBox

@onready var sfx_slider: HSlider = %SFXSlider
@onready var sfx_value_label: Label = %SFXValueLabel
@onready var sfx_mute_checkbox: CheckBox = %SFXMuteCheckBox

@onready var ui_slider: HSlider = %UISlider
@onready var ui_value_label: Label = %UIValueLabel
@onready var ui_mute_checkbox: CheckBox = %UIMuteCheckBox

@onready var particles_checkbox: CheckBox = %ParticlesCheckBox
@onready var animations_checkbox: CheckBox = %AnimationsCheckBox
@onready var high_contrast_checkbox: CheckBox = %HighContrastCheckBox
@onready var colorblind_mode_checkbox: CheckBox = %ColorblindModeCheckBox
@onready var font_size_slider: HSlider = %FontSizeSlider
@onready var font_size_value_label: Label = %FontSizeValueLabel

# Controles do jogador 1
@onready var move_left_button: Button = %MoveLeftButton
@onready var move_right_button: Button = %MoveRightButton
@onready var rotate_button: Button = %RotateButton
@onready var soft_drop_button: Button = %SoftDropButton
@onready var hard_drop_button: Button = %HardDropButton
@onready var power_up_button: Button = %PowerUpButton

# Controles do jogador 2
@onready var move_left_button2: Button = %MoveLeftButton2
@onready var move_right_button2: Button = %MoveRightButton2
@onready var rotate_button2: Button = %RotateButton2
@onready var soft_drop_button2: Button = %SoftDropButton2
@onready var hard_drop_button2: Button = %HardDropButton2
@onready var power_up_button2: Button = %PowerUpButton2

# Valores padrão
var default_settings = {
	"audio": {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ui_volume": 0.9,
		"music_muted": false,
		"sfx_muted": false,
		"ui_muted": false
	},
	"controls": {
		"player1": {
			"move_left": "A",
			"move_right": "D",
			"rotate": "W",
			"soft_drop": "S",
			"hard_drop": "Espaço",
			"power_up": "E"
		},
		"player2": {
			"move_left": "Seta Esquerda",
			"move_right": "Seta Direita",
			"rotate": "Seta Cima",
			"soft_drop": "Seta Baixo",
			"hard_drop": "Enter",
			"power_up": "Shift"
		}
	},
	"visual": {
		"particles": false,
		"animations": true,
		"high_contrast": false,
		"colorblind_mode": false,
		"font_size": 1.0
	}
}

# Configurações atuais
var current_settings = {}

# Mapeamento de nomes para teclas
var key_mapping = {}
var is_waiting_for_key = false
var button_waiting_for_input = null

func _ready():
	# Configurar os sliders e conectar sinais
	setup_ui()
	load_settings()
	connect_signals()

func setup_ui():
	# Configurar sliders
	music_slider.value = default_settings.audio.music_volume
	sfx_slider.value = default_settings.audio.sfx_volume
	ui_slider.value = default_settings.audio.ui_volume
	
	# Configurar checkboxes
	music_mute_checkbox.button_pressed = default_settings.audio.music_muted
	sfx_mute_checkbox.button_pressed = default_settings.audio.sfx_muted
	ui_mute_checkbox.button_pressed = default_settings.audio.ui_muted
	
	particles_checkbox.button_pressed = default_settings.visual.particles
	animations_checkbox.button_pressed = default_settings.visual.animations
	high_contrast_checkbox.button_pressed = default_settings.visual.high_contrast
	colorblind_mode_checkbox.button_pressed = default_settings.visual.colorblind_mode
	
	font_size_slider.value = default_settings.visual.font_size
	
	# Configurar botões de controle
	move_left_button.text = default_settings.controls.player1.move_left
	move_right_button.text = default_settings.controls.player1.move_right
	rotate_button.text = default_settings.controls.player1.rotate
	soft_drop_button.text = default_settings.controls.player1.soft_drop
	hard_drop_button.text = default_settings.controls.player1.hard_drop
	power_up_button.text = default_settings.controls.player1.power_up
	
	move_left_button2.text = default_settings.controls.player2.move_left
	move_right_button2.text = default_settings.controls.player2.move_right
	rotate_button2.text = default_settings.controls.player2.rotate
	soft_drop_button2.text = default_settings.controls.player2.soft_drop
	hard_drop_button2.text = default_settings.controls.player2.hard_drop
	power_up_button2.text = default_settings.controls.player2.power_up
	
	# Atualizar labels
	update_volume_labels()
	update_font_size_label()

func connect_signals():
	# Conectar sinais dos sliders
	music_slider.value_changed.connect(func(value): on_music_volume_changed(value))
	sfx_slider.value_changed.connect(func(value): on_sfx_volume_changed(value))
	ui_slider.value_changed.connect(func(value): on_ui_volume_changed(value))
	font_size_slider.value_changed.connect(func(value): on_font_size_changed(value))
	
	# Conectar sinais dos checkboxes
	music_mute_checkbox.toggled.connect(func(toggled): on_music_mute_toggled(toggled))
	sfx_mute_checkbox.toggled.connect(func(toggled): on_sfx_mute_toggled(toggled))
	ui_mute_checkbox.toggled.connect(func(toggled): on_ui_mute_toggled(toggled))
	
	particles_checkbox.toggled.connect(func(toggled): on_particles_toggled(toggled))
	animations_checkbox.toggled.connect(func(toggled): on_animations_toggled(toggled))
	high_contrast_checkbox.toggled.connect(func(toggled): on_high_contrast_toggled(toggled))
	colorblind_mode_checkbox.toggled.connect(func(toggled): on_colorblind_mode_toggled(toggled))
	
	# Conectar sinais dos botões de controle
	connect_control_buttons()
	
	# Conectar botões da interface
	$MainPanel/ButtonContainer/ResetButton.pressed.connect(reset_to_defaults)
	$MainPanel/ButtonContainer/ApplyButton.pressed.connect(apply_settings)
	$MainPanel/ButtonContainer/BackButton.pressed.connect(go_back)

func connect_control_buttons():
	var control_buttons = [
		move_left_button, move_right_button, rotate_button, 
		soft_drop_button, hard_drop_button, power_up_button,
		move_left_button2, move_right_button2, rotate_button2, 
		soft_drop_button2, hard_drop_button2, power_up_button2
	]
	
	for button in control_buttons:
		button.pressed.connect(func(): on_control_button_pressed(button))

func on_control_button_pressed(button):
	# Se já estiver esperando uma tecla, cancele
	if is_waiting_for_key:
		clear_waiting_state()
	
	# Configure o estado de espera
	is_waiting_for_key = true
	button_waiting_for_input = button
	button.text = "Pressione uma tecla..."

func _input(event):
	if is_waiting_for_key and button_waiting_for_input != null:
		if event is InputEventKey and event.pressed and not event.echo:
			# Obter a tecla pressionada
			var key_text = OS.get_keycode_string(event.keycode)
			button_waiting_for_input.text = key_text
			
			# Atualizar configurações
			update_control_setting(button_waiting_for_input, key_text)
			
			# Limpar estado de espera
			clear_waiting_state()
			
			# Aceitar o evento para evitar que ele seja processado por outros manipuladores
			get_viewport().set_input_as_handled()

func clear_waiting_state():
	is_waiting_for_key = false
	button_waiting_for_input = null

func update_control_setting(button, key_text):
	var player = "player1"
	var action = ""
	
	# Identificar qual botão foi pressionado
	match button:
		move_left_button: 
			action = "move_left"
		move_right_button: 
			action = "move_right"
		rotate_button: 
			action = "rotate"
		soft_drop_button: 
			action = "soft_drop"
		hard_drop_button: 
			action = "hard_drop"
		power_up_button: 
			action = "power_up"
		_:
			player = "player2"
			match button:
				move_left_button2: 
					action = "move_left"
				move_right_button2: 
					action = "move_right"
				rotate_button2: 
					action = "rotate"
				soft_drop_button2: 
					action = "soft_drop"
				hard_drop_button2: 
					action = "hard_drop"
				power_up_button2: 
					action = "power_up"
	
	if action and player:
		current_settings.controls[player][action] = key_text

func load_settings():
	# Tentar carregar configurações do arquivo
	var err = config.load(CONFIG_FILE_PATH)
	
	# Se o arquivo não existir ou houver erro, use os valores padrão
	if err != OK:
		current_settings = default_settings.duplicate(true)
		return
	
	# Carregar configurações de áudio
	current_settings = {
		"audio": {
			"music_volume": config.get_value("audio", "music_volume", default_settings.audio.music_volume),
			"sfx_volume": config.get_value("audio", "sfx_volume", default_settings.audio.sfx_volume),
			"ui_volume": config.get_value("audio", "ui_volume", default_settings.audio.ui_volume),
			"music_muted": config.get_value("audio", "music_muted", default_settings.audio.music_muted),
			"sfx_muted": config.get_value("audio", "sfx_muted", default_settings.audio.sfx_muted),
			"ui_muted": config.get_value("audio", "ui_muted", default_settings.audio.ui_muted)
		},
		"controls": {
			"player1": {
				"move_left": config.get_value("controls_player1", "move_left", default_settings.controls.player1.move_left),
				"move_right": config.get_value("controls_player1", "move_right", default_settings.controls.player1.move_right),
				"rotate": config.get_value("controls_player1", "rotate", default_settings.controls.player1.rotate),
				"soft_drop": config.get_value("controls_player1", "soft_drop", default_settings.controls.player1.soft_drop),
				"hard_drop": config.get_value("controls_player1", "hard_drop", default_settings.controls.player1.hard_drop),
				"power_up": config.get_value("controls_player1", "power_up", default_settings.controls.player1.power_up)
			},
			"player2": {
				"move_left": config.get_value("controls_player2", "move_left", default_settings.controls.player2.move_left),
				"move_right": config.get_value("controls_player2", "move_right", default_settings.controls.player2.move_right),
				"rotate": config.get_value("controls_player2", "rotate", default_settings.controls.player2.rotate),
				"soft_drop": config.get_value("controls_player2", "soft_drop", default_settings.controls.player2.soft_drop),
				"hard_drop": config.get_value("controls_player2", "hard_drop", default_settings.controls.player2.hard_drop),
				"power_up": config.get_value("controls_player2", "power_up", default_settings.controls.player2.power_up)
			}
		},
		"visual": {
			"particles": config.get_value("visual", "particles", default_settings.visual.particles),
			"animations": config.get_value("visual", "animations", default_settings.visual.animations),
			"high_contrast": config.get_value("visual", "high_contrast", default_settings.visual.high_contrast),
			"colorblind_mode": config.get_value("visual", "colorblind_mode", default_settings.visual.colorblind_mode),
			"font_size": config.get_value("visual", "font_size", default_settings.visual.font_size)
		}
	}
	
	# Aplicar configurações carregadas à UI
	apply_settings_to_ui()

func apply_settings_to_ui():
	# Aplicar configurações de áudio
	music_slider.value = current_settings.audio.music_volume
	sfx_slider.value = current_settings.audio.sfx_volume
	ui_slider.value = current_settings.audio.ui_volume
	
	music_mute_checkbox.button_pressed = current_settings.audio.music_muted
	sfx_mute_checkbox.button_pressed = current_settings.audio.sfx_muted
	ui_mute_checkbox.button_pressed = current_settings.audio.ui_muted
	
	# Aplicar configurações visuais
	particles_checkbox.button_pressed = current_settings.visual.particles
	animations_checkbox.button_pressed = current_settings.visual.animations
	high_contrast_checkbox.button_pressed = current_settings.visual.high_contrast
	colorblind_mode_checkbox.button_pressed = current_settings.visual.colorblind_mode
	font_size_slider.value = current_settings.visual.font_size
	
	# Aplicar configurações de controle
	move_left_button.text = current_settings.controls.player1.move_left
	move_right_button.text = current_settings.controls.player1.move_right
	rotate_button.text = current_settings.controls.player1.rotate
	soft_drop_button.text = current_settings.controls.player1.soft_drop
	hard_drop_button.text = current_settings.controls.player1.hard_drop
	power_up_button.text = current_settings.controls.player1.power_up
	
	move_left_button2.text = current_settings.controls.player2.move_left
	move_right_button2.text = current_settings.controls.player2.move_right
	rotate_button2.text = current_settings.controls.player2.rotate
	soft_drop_button2.text = current_settings.controls.player2.soft_drop
	hard_drop_button2.text = current_settings.controls.player2.hard_drop
	power_up_button2.text = current_settings.controls.player2.power_up
	
	# Atualizar labels
	update_volume_labels()
	update_font_size_label()

func save_settings():
	# Salvar configurações de áudio
	config.set_value("audio", "music_volume", current_settings.audio.music_volume)
	config.set_value("audio", "sfx_volume", current_settings.audio.sfx_volume)
	config.set_value("audio", "ui_volume", current_settings.audio.ui_volume)
	config.set_value("audio", "music_muted", current_settings.audio.music_muted)
	config.set_value("audio", "sfx_muted", current_settings.audio.sfx_muted)
	config.set_value("audio", "ui_muted", current_settings.audio.ui_muted)
	
	# Salvar configurações de controle
	config.set_value("controls_player1", "move_left", current_settings.controls.player1.move_left)
	config.set_value("controls_player1", "move_right", current_settings.controls.player1.move_right)
	config.set_value("controls_player1", "rotate", current_settings.controls.player1.rotate)
	config.set_value("controls_player1", "soft_drop", current_settings.controls.player1.soft_drop)
	config.set_value("controls_player1", "hard_drop", current_settings.controls.player1.hard_drop)
	config.set_value("controls_player1", "power_up", current_settings.controls.player1.power_up)
	
	config.set_value("controls_player2", "move_left", current_settings.controls.player2.move_left)
	config.set_value("controls_player2", "move_right", current_settings.controls.player2.move_right)
	config.set_value("controls_player2", "rotate", current_settings.controls.player2.rotate)
	config.set_value("controls_player2", "soft_drop", current_settings.controls.player2.soft_drop)
	config.set_value("controls_player2", "hard_drop", current_settings.controls.player2.hard_drop)
	config.set_value("controls_player2", "power_up", current_settings.controls.player2.power_up)
	
	# Salvar configurações visuais
	config.set_value("visual", "particles", current_settings.visual.particles)
	config.set_value("visual", "animations", current_settings.visual.animations)
	config.set_value("visual", "high_contrast", current_settings.visual.high_contrast)
	config.set_value("visual", "colorblind_mode", current_settings.visual.colorblind_mode)
	config.set_value("visual", "font_size", current_settings.visual.font_size)
	
	# Salvar no arquivo
	config.save(CONFIG_FILE_PATH)

# Callbacks para alterações de volume
func on_music_volume_changed(value):
	current_settings.audio.music_volume = value
	update_volume_labels()
	
	# Atualizar volume da música se o GameAudio estiver disponível
	if GameAudio:
		GameAudio.set_volume(GameAudio.AudioType.MUSIC, value)

func on_sfx_volume_changed(value):
	current_settings.audio.sfx_volume = value
	update_volume_labels()
	
	# Atualizar volume de SFX se o GameAudio estiver disponível
	if GameAudio:
		GameAudio.set_volume(GameAudio.AudioType.SFX, value)

func on_ui_volume_changed(value):
	current_settings.audio.ui_volume = value
	update_volume_labels()
	
	# Atualizar volume de UI se o GameAudio estiver disponível
	if GameAudio:
		GameAudio.set_volume(GameAudio.AudioType.UI, value)

func on_font_size_changed(value):
	current_settings.visual.font_size = value
	update_font_size_label()
	
	# Implementar ajuste de tamanho de fonte

func update_volume_labels():
	music_value_label.text = "%d%%" % (music_slider.value * 100)
	sfx_value_label.text = "%d%%" % (sfx_slider.value * 100)
	ui_value_label.text = "%d%%" % (ui_slider.value * 100)

func update_font_size_label():
	font_size_value_label.text = "%d%%" % (font_size_slider.value * 100)

# Callbacks para checkboxes
func on_music_mute_toggled(toggled):
	current_settings.audio.music_muted = toggled
	
	# Atualizar estado mudo da música se o GameAudio estiver disponível
	if GameAudio:
		GameAudio.set_muted(GameAudio.AudioType.MUSIC, toggled)

func on_sfx_mute_toggled(toggled):
	current_settings.audio.sfx_muted = toggled
	
	# Atualizar estado mudo de SFX se o GameAudio estiver disponível
	if GameAudio:
		GameAudio.set_muted(GameAudio.AudioType.SFX, toggled)

func on_ui_mute_toggled(toggled):
	current_settings.audio.ui_muted = toggled
	
	# Atualizar estado mudo de UI se o GameAudio estiver disponível
	if GameAudio:
		GameAudio.set_muted(GameAudio.AudioType.UI, toggled)

func on_particles_toggled(toggled):
	current_settings.visual.particles = toggled
	# Implementar ativação/desativação de partículas

func on_animations_toggled(toggled):
	current_settings.visual.animations = toggled
	# Implementar ativação/desativação de animações

func on_high_contrast_toggled(toggled):
	current_settings.visual.high_contrast = toggled
	# Implementar modo de alto contraste

func on_colorblind_mode_toggled(toggled):
	current_settings.visual.colorblind_mode = toggled
	# Implementar modo daltônico

# Botões de ação
func reset_to_defaults():
	current_settings = default_settings.duplicate(true)
	apply_settings_to_ui()

func apply_settings():
	# Aplicar as configurações ao jogo
	apply_settings_to_game()
	
	# Salvar as configurações
	save_settings()

func apply_settings_to_game():
	# Aplicar configurações de áudio ao GameAudio se disponível
	if GameAudio:
		GameAudio.set_volume(GameAudio.AudioType.MUSIC, current_settings.audio.music_volume)
		GameAudio.set_volume(GameAudio.AudioType.SFX, current_settings.audio.sfx_volume)
		GameAudio.set_volume(GameAudio.AudioType.UI, current_settings.audio.ui_volume)
		
		GameAudio.set_muted(GameAudio.AudioType.MUSIC, current_settings.audio.music_muted)
		GameAudio.set_muted(GameAudio.AudioType.SFX, current_settings.audio.sfx_muted)
		GameAudio.set_muted(GameAudio.AudioType.UI, current_settings.audio.ui_muted)
	
	# Aplicar configurações visuais
	# Implementar aplicação de configurações visuais no jogo
	
	# Aplicar configurações de controle
	# Deverá mapear os controles para o sistema de input da Godot

func go_back():
	# Voltar para o menu principal
	get_tree().change_scene_to_file("res://scenes/menu.tscn") 