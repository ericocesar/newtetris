extends Node

# Sound Manager - Gerencia todos os efeitos sonoros do jogo Tetris Duelistas

# Dicionário para armazenar as referências dos sons pré-carregados
var sound_effects = {}

# Variáveis para controle de configurações
var sound_enabled = true
var sound_volume = 0.7 # 70% do volume máximo

# Precarregar todos os efeitos sonoros
func _ready():
	# Carregar efeitos sonoros principais
	preload_sound("tetromino_move", "res://assets/sounds/tetromino_move.ogg")
	preload_sound("tetromino_rotate", "res://assets/sounds/tetromino_rotate.ogg")
	preload_sound("tetromino_land", "res://assets/sounds/tetromino_land.ogg")
	preload_sound("line_clear", "res://assets/sounds/line_clear.ogg")
	preload_sound("game_over", "res://assets/sounds/game_over.ogg")
	preload_sound("powerup_activate", "res://assets/sounds/powerup_activate.ogg")
	preload_sound("menu_select", "res://assets/sounds/menu_select.ogg")
	preload_sound("countdown", "res://assets/sounds/countdown.ogg")

# Carrega e armazena um som no dicionário
func preload_sound(name, path):
	var sound = load(path)
	if sound:
		sound_effects[name] = sound
	else:
		print("ERRO: Não foi possível carregar o som: ", path)

# Reproduz um som pelo nome
func play_sound(sound_name, volume_scale = 1.0):
	if not sound_enabled:
		return
		
	if sound_effects.has(sound_name):
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = sound_effects[sound_name]
		audio_player.volume_db = linear_to_db(sound_volume * volume_scale)
		audio_player.play()
		
		# Configurar para auto-destruir após a reprodução
		audio_player.connect("finished", Callable(audio_player, "queue_free"))
	else:
		print("AVISO: Som não encontrado: ", sound_name)

# Reproduz o som de movimento da peça
func play_move_sound():
	play_sound("tetromino_move", 0.6) # Volume um pouco mais baixo por ser frequente

# Reproduz o som de rotação da peça
func play_rotate_sound():
	play_sound("tetromino_rotate", 0.8)

# Reproduz o som de aterrissagem da peça
func play_land_sound():
	play_sound("tetromino_land")

# Reproduz o som de limpeza de linha
func play_line_clear_sound():
	play_sound("line_clear", 1.2) # Volume um pouco mais alto por ser importante

# Reproduz o som de game over
func play_game_over_sound():
	play_sound("game_over", 1.5) # Volume mais alto por ser um evento significativo

# Reproduz o som de ativação de power-up
func play_powerup_sound():
	play_sound("powerup_activate", 1.3) # Volume mais alto para destacar

# Reproduz o som de seleção de menu
func play_menu_select_sound():
	play_sound("menu_select")

# Reproduz o som de contagem regressiva
func play_countdown_sound():
	play_sound("countdown")

# Ativa ou desativa o som
func toggle_sound(enabled):
	sound_enabled = enabled

# Define o volume do som (0.0 a 1.0)
func set_volume(volume):
	sound_volume = clamp(volume, 0.0, 1.0)

# Obtém o estado atual da configuração de som
func is_sound_enabled():
	return sound_enabled

# Obtém o volume atual
func get_volume():
	return sound_volume 