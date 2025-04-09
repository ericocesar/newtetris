extends Node

# Cores padrão do tema
const COLOR_BACKGROUND = Color("#0F1035")
const COLOR_PANEL = Color("#1A1A40")
const COLOR_BUTTON = Color("#3E4684")
const COLOR_BUTTON_HOVER = Color("#545AA7")
const COLOR_BUTTON_PRESSED = Color("#272B58")
const COLOR_TEXT = Color("#FFFFFF")
const COLOR_TEXT_DISABLED = Color("#888888")
const COLOR_ACCENT = Color("#F806CC")
const COLOR_SUCCESS = Color("#00FF00")
const COLOR_ERROR = Color("#FF0000")
const COLOR_WARNING = Color("#FFAA00")

# Cores dos tetrominós
const COLOR_I = Color("#00FFFF") # Ciano
const COLOR_J = Color("#0000FF") # Azul
const COLOR_L = Color("#FF7F00") # Laranja
const COLOR_O = Color("#FFFF00") # Amarelo
const COLOR_S = Color("#00FF00") # Verde
const COLOR_T = Color("#800080") # Roxo
const COLOR_Z = Color("#FF0000") # Vermelho

# Cores para modo daltônico
const COLORBLIND_I = Color("#01A9DB") # Azul mais escuro
const COLORBLIND_J = Color("#0B2161") # Azul marinho
const COLORBLIND_L = Color("#8A4B08") # Marrom
const COLORBLIND_O = Color("#F4FA58") # Amarelo mais claro
const COLORBLIND_S = Color("#088A08") # Verde mais escuro
const COLORBLIND_T = Color("#4C0B5F") # Roxo mais escuro
const COLORBLIND_Z = Color("#8A0808") # Vermelho mais escuro

# Tamanhos padrão
const FONT_SIZE_SMALL = 12
const FONT_SIZE_MEDIUM = 18
const FONT_SIZE_LARGE = 24
const FONT_SIZE_TITLE = 36

# Espaçamentos
const MARGIN_SMALL = 4
const MARGIN_MEDIUM = 8
const MARGIN_LARGE = 16

# Flags de configuração visual
var high_contrast_mode = false
var colorblind_mode = false
var font_size_multiplier = 1.0
var animations_enabled = true
var particles_enabled = true

# Fontes
var font_normal: FontFile
var font_bold: FontFile

func _ready():
	# Carregar as fontes
	load_fonts()
	
	# Ler configurações do arquivo de configuração (se existir)
	load_theme_settings()
	
	# Aplicar configurações iniciais
	apply_theme_settings()

func load_fonts():
	# Tenta carregar as fontes do sistema
	font_normal = load("res://assets/fonts/retro_gaming.ttf")
	if font_normal == null:
		# Fallback para a fonte padrão
		font_normal = ThemeDB.fallback_font
	
	# Por enquanto, usamos a mesma fonte para normal e negrito
	font_bold = font_normal

func load_theme_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		high_contrast_mode = config.get_value("visual", "high_contrast", false)
		colorblind_mode = config.get_value("visual", "colorblind_mode", false)
		font_size_multiplier = config.get_value("visual", "font_size", 1.0)
		animations_enabled = config.get_value("visual", "animations", true)
		particles_enabled = config.get_value("visual", "particles", false)

func apply_theme_settings():
	# Esta função será chamada para aplicar configurações visuais globais
	# Implementação real dependerá de como o tema é gerenciado no jogo
	pass

func get_tetromino_color(type: String) -> Color:
	# Seleciona a cor do tetrominô com base no modo atual
	if colorblind_mode:
		match type:
			"I": return COLORBLIND_I
			"J": return COLORBLIND_J
			"L": return COLORBLIND_L
			"O": return COLORBLIND_O
			"S": return COLORBLIND_S
			"T": return COLORBLIND_T
			"Z": return COLORBLIND_Z
			_: return COLOR_TEXT
	else:
		match type:
			"I": return COLOR_I
			"J": return COLOR_J
			"L": return COLOR_L
			"O": return COLOR_O
			"S": return COLOR_S
			"T": return COLOR_T
			"Z": return COLOR_Z
			_: return COLOR_TEXT

func get_font_size(size_type: String) -> int:
	# Aplica o multiplicador nas configurações
	match size_type:
		"small": return int(FONT_SIZE_SMALL * font_size_multiplier)
		"medium": return int(FONT_SIZE_MEDIUM * font_size_multiplier)
		"large": return int(FONT_SIZE_LARGE * font_size_multiplier)
		"title": return int(FONT_SIZE_TITLE * font_size_multiplier)
		_: return int(FONT_SIZE_MEDIUM * font_size_multiplier)

func create_button_style(normal_color: Color = COLOR_BUTTON, 
						hover_color: Color = COLOR_BUTTON_HOVER,
						pressed_color: Color = COLOR_BUTTON_PRESSED,
						disabled_color: Color = COLOR_BUTTON.darkened(0.3)) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = normal_color
	style.border_width_bottom = 4
	style.border_color = normal_color.darkened(0.2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Ajuste para modo de alto contraste
	if high_contrast_mode:
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_color = COLOR_TEXT
	
	return style

func create_panel_style(panel_color: Color = COLOR_PANEL) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = panel_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	# Ajuste para modo de alto contraste
	if high_contrast_mode:
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = COLOR_TEXT
	
	return style

func set_high_contrast_mode(enabled: bool):
	high_contrast_mode = enabled
	apply_theme_settings()

func set_colorblind_mode(enabled: bool):
	colorblind_mode = enabled
	apply_theme_settings()

func set_font_size_multiplier(multiplier: float):
	font_size_multiplier = clamp(multiplier, 0.5, 2.0)
	apply_theme_settings()

func set_animations_enabled(enabled: bool):
	animations_enabled = enabled
	apply_theme_settings()

func set_particles_enabled(enabled: bool):
	particles_enabled = enabled
	apply_theme_settings() 