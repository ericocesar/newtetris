extends Node

class_name GameFonts

# Fontes principais do jogo
var press_start_2p: FontFile
var retro_gaming: FontFile

# Tamanhos predefinidos
const SIZE_SMALL = 12
const SIZE_MEDIUM = 18
const SIZE_LARGE = 24
const SIZE_TITLE = 32

# Singleton
static var _instance = null

static func get_instance() -> GameFonts:
	if _instance == null:
		_instance = GameFonts.new()
	return _instance

func _init():
	# Carrega as fontes
	press_start_2p = load_font("res://assets/fonts/press_start_2p.ttf")
	retro_gaming = load_font("res://assets/fonts/Retro Gaming.ttf")
	
	# Caso alguma fonte não carregue, usa a fonte padrão
	if press_start_2p == null:
		print("AVISO: Não foi possível carregar a fonte Press Start 2P.")
		press_start_2p = FontFile.new()
		
	if retro_gaming == null:
		print("AVISO: Não foi possível carregar a fonte Retro Gaming.")
		retro_gaming = FontFile.new()

# Função auxiliar para carregar fontes
func load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		return load(path)
	else:
		push_error("Fonte não encontrada: " + path)
		return null

# Obtém a fonte principal com tamanho específico
func get_main_font(size: int = SIZE_MEDIUM) -> Font:
	var font = press_start_2p
	return font

# Obtém a fonte secundária com tamanho específico
func get_secondary_font(size: int = SIZE_MEDIUM) -> Font:
	var font = retro_gaming
	return font 