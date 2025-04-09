extends Node

class_name GameAudio

# Categorias de áudio
enum AudioType {
	MUSIC,
	SFX,
	UI
}

# Configurações por categoria
var volume_settings = {
	AudioType.MUSIC: 0.8,
	AudioType.SFX: 1.0,
	AudioType.UI: 0.9
}

# Controle de mudo por categoria
var muted_settings = {
	AudioType.MUSIC: false,
	AudioType.SFX: false,
	AudioType.UI: false
}

# Caminhos para os arquivos de áudio
var audio_paths = {
	# Músicas
	"music_menu": "res://assets/audio/music/menu.ogg",
	"music_game": "res://assets/audio/music/game.ogg",
	
	# Efeitos sonoros
	"sfx_move": "res://assets/audio/sfx/move.ogg",
	"sfx_rotate": "res://assets/audio/sfx/rotate.ogg",
	"sfx_drop": "res://assets/audio/sfx/drop.ogg",
	"sfx_clear_line": "res://assets/audio/sfx/clear_line.ogg",
	"sfx_tetris": "res://assets/audio/sfx/tetris.ogg",
	"sfx_level_up": "res://assets/audio/sfx/level_up.ogg",
	"sfx_game_over": "res://assets/audio/sfx/game_over.ogg",
	"sfx_power_up": "res://assets/audio/sfx/power_up.ogg",
	
	# UI
	"ui_click": "res://assets/audio/ui/click.ogg",
	"ui_hover": "res://assets/audio/ui/hover.ogg",
	"ui_back": "res://assets/audio/ui/back.ogg",
	"ui_success": "res://assets/audio/ui/success.ogg",
	"ui_error": "res://assets/audio/ui/error.ogg"
}

# Cache para os recursos de áudio carregados
var audio_cache = {}

# Players de áudio para diferentes categorias
var music_player: AudioStreamPlayer
var sfx_players = []
var ui_players = []

# Número de players para efeitos e UI
const NUM_SFX_PLAYERS = 4
const NUM_UI_PLAYERS = 2

# Singleton
static var _instance = null

static func get_instance() -> GameAudio:
	if _instance == null:
		_instance = GameAudio.new()
	return _instance

func _init():
	# Inicializa os players de áudio
	_initialize_audio_players()

# Inicializa os players de áudio
func _initialize_audio_players():
	# Player de música
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(volume_settings[AudioType.MUSIC])
	
	# Players de efeitos sonoros
	for i in range(NUM_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(volume_settings[AudioType.SFX])
		sfx_players.append(player)
	
	# Players de UI
	for i in range(NUM_UI_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "UI"
		player.volume_db = linear_to_db(volume_settings[AudioType.UI])
		ui_players.append(player)

# Adiciona os players à árvore quando o objeto é adicionado à árvore
func _enter_tree():
	# Adiciona o player de música
	add_child(music_player)
	
	# Adiciona os players de efeitos sonoros
	for player in sfx_players:
		add_child(player)
	
	# Adiciona os players de UI
	for player in ui_players:
		add_child(player)

# Carrega um recurso de áudio do cache ou do disco
func _load_audio(audio_name: String) -> AudioStream:
	if not audio_paths.has(audio_name):
		push_error("Arquivo de áudio não encontrado: " + audio_name)
		return null
	
	# Verifica se o áudio já está em cache
	if audio_cache.has(audio_name):
		return audio_cache[audio_name]
	
	# Carrega o arquivo de áudio
	var path = audio_paths[audio_name]
	if ResourceLoader.exists(path):
		var audio: AudioStream = load(path)
		audio_cache[audio_name] = audio
		return audio
	else:
		push_error("Arquivo de áudio não existe: " + path)
		return null

# Reproduz uma música
func play_music(music_name: String, fade_time: float = 0.5):
	var audio = _load_audio(music_name)
	if audio == null:
		return
	
	# Se já houver uma música tocando, faz um fade
	if music_player.playing:
		var tween = get_tree().create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func(): _start_music(audio))
	else:
		_start_music(audio)

# Inicia a reprodução de uma música
func _start_music(audio: AudioStream):
	music_player.stream = audio
	music_player.play()
	
	# Restaura o volume normal se não estiver mudo
	if not muted_settings[AudioType.MUSIC]:
		var target_volume = linear_to_db(volume_settings[AudioType.MUSIC])
		var tween = get_tree().create_tween()
		tween.tween_property(music_player, "volume_db", target_volume, 0.5)
	else:
		music_player.volume_db = -80.0

# Para a música atual
func stop_music(fade_time: float = 0.5):
	if music_player.playing:
		var tween = get_tree().create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func(): music_player.stop())

# Reproduz um efeito sonoro
func play_sfx(sfx_name: String):
	if muted_settings[AudioType.SFX]:
		return
		
	var audio = _load_audio(sfx_name)
	if audio == null:
		return
	
	# Encontra um player disponível
	for player in sfx_players:
		if not player.playing:
			player.stream = audio
			player.play()
			return
	
	# Se não houver players disponíveis, usa o primeiro
	sfx_players[0].stream = audio
	sfx_players[0].play()

# Reproduz um som de UI
func play_ui(ui_name: String):
	if muted_settings[AudioType.UI]:
		return
		
	var audio = _load_audio(ui_name)
	if audio == null:
		return
	
	# Encontra um player disponível
	for player in ui_players:
		if not player.playing:
			player.stream = audio
			player.play()
			return
	
	# Se não houver players disponíveis, usa o primeiro
	ui_players[0].stream = audio
	ui_players[0].play()

# Define o volume para uma categoria de áudio
func set_volume(type: AudioType, volume: float):
	volume_settings[type] = clamp(volume, 0.0, 1.0)
	
	match type:
		AudioType.MUSIC:
			if not muted_settings[type]:
				music_player.volume_db = linear_to_db(volume_settings[type])
		AudioType.SFX:
			for player in sfx_players:
				if not muted_settings[type]:
					player.volume_db = linear_to_db(volume_settings[type])
		AudioType.UI:
			for player in ui_players:
				if not muted_settings[type]:
					player.volume_db = linear_to_db(volume_settings[type])

# Muta/desmuta uma categoria de áudio
func set_muted(type: AudioType, muted: bool):
	muted_settings[type] = muted
	
	match type:
		AudioType.MUSIC:
			music_player.volume_db = -80.0 if muted else linear_to_db(volume_settings[type])
		AudioType.SFX:
			for player in sfx_players:
				player.volume_db = -80.0 if muted else linear_to_db(volume_settings[type])
		AudioType.UI:
			for player in ui_players:
				player.volume_db = -80.0 if muted else linear_to_db(volume_settings[type])

# Obtém o status de mudo de uma categoria
func is_muted(type: AudioType) -> bool:
	return muted_settings[type]

# Obtém o volume de uma categoria
func get_volume(type: AudioType) -> float:
	return volume_settings[type] 