extends Resource

# Classe que representa um power-up no jogo
class_name PowerUp

# Tipos de power-ups disponíveis
enum Type {
	CLEAR_LINE,      # Limpa uma linha aleatória
	SPEED_UP,        # Aumenta a velocidade do oponente
	SPEED_DOWN,      # Diminui a velocidade do próprio jogador
	BLOCK_ROTATION,  # Bloqueia a rotação do oponente
	BLOCK_MOVEMENT,  # Bloqueia o movimento lateral do oponente
	FLIP_CONTROLS,   # Inverte os controles do oponente
	GARBAGE_LINES,   # Adiciona linhas de lixo para o oponente
	RANDOM_BLOCKS,   # Gera blocos aleatórios para o oponente
	INSTANT_DROP     # Força queda instantânea para o oponente
}

# Duração padrão dos power-ups em segundos
const DEFAULT_DURATION = 10.0

# Propriedades do power-up
var id: String
var type: Type
var owner_id: int  # ID do jogador que possui o power-up
var target_id: int  # ID do jogador que será alvo do power-up
var duration: float  # Duração em segundos (0 para efeito instantâneo)
var active: bool = false

# Nomes e descrições dos power-ups
static var names = {
	Type.CLEAR_LINE: "Limpar Linha",
	Type.SPEED_UP: "Acelerar",
	Type.SPEED_DOWN: "Desacelerar",
	Type.BLOCK_ROTATION: "Bloquear Rotação",
	Type.BLOCK_MOVEMENT: "Bloquear Movimento", 
	Type.FLIP_CONTROLS: "Inverter Controles",
	Type.GARBAGE_LINES: "Linhas de Lixo",
	Type.RANDOM_BLOCKS: "Blocos Aleatórios",
	Type.INSTANT_DROP: "Queda Instantânea"
}

static var descriptions = {
	Type.CLEAR_LINE: "Limpa uma linha aleatória do seu grid.",
	Type.SPEED_UP: "Aumenta a velocidade de queda das peças do oponente.",
	Type.SPEED_DOWN: "Diminui a velocidade de queda das suas peças.",
	Type.BLOCK_ROTATION: "Impede o oponente de rotacionar suas peças.",
	Type.BLOCK_MOVEMENT: "Impede o oponente de mover suas peças lateralmente.",
	Type.FLIP_CONTROLS: "Inverte os controles do oponente.",
	Type.GARBAGE_LINES: "Adiciona 2 linhas de lixo no grid do oponente.",
	Type.RANDOM_BLOCKS: "Adiciona blocos aleatórios no grid do oponente.",
	Type.INSTANT_DROP: "Força uma queda instantânea da peça atual do oponente."
}

# Cores para representação visual dos power-ups
static var colors = {
	Type.CLEAR_LINE: Color("#00FF00"),  # Verde
	Type.SPEED_UP: Color("#FF0000"),    # Vermelho
	Type.SPEED_DOWN: Color("#0000FF"),  # Azul
	Type.BLOCK_ROTATION: Color("#800080"),  # Roxo
	Type.BLOCK_MOVEMENT: Color("#FFA500"),  # Laranja
	Type.FLIP_CONTROLS: Color("#FFFF00"),   # Amarelo
	Type.GARBAGE_LINES: Color("#A52A2A"),   # Marrom
	Type.RANDOM_BLOCKS: Color("#00FFFF"),   # Ciano
	Type.INSTANT_DROP: Color("#FF00FF")     # Magenta
}

# Duração específica para cada tipo de power-up
static var durations = {
	Type.CLEAR_LINE: 0.0,       # Efeito instantâneo
	Type.SPEED_UP: 15.0,
	Type.SPEED_DOWN: 15.0,
	Type.BLOCK_ROTATION: 10.0,
	Type.BLOCK_MOVEMENT: 7.0,
	Type.FLIP_CONTROLS: 12.0,
	Type.GARBAGE_LINES: 0.0,    # Efeito instantâneo
	Type.RANDOM_BLOCKS: 0.0,    # Efeito instantâneo
	Type.INSTANT_DROP: 0.0      # Efeito instantâneo
}

# Inicializa um power-up
func _init(p_type: Type = Type.SPEED_UP, p_owner_id: int = 0):
	id = str(randi())
	type = p_type
	owner_id = p_owner_id
	target_id = 1 - p_owner_id  # Por padrão, o alvo é o outro jogador
	duration = durations[type]
	active = false
	
	# Alguns power-ups afetam o próprio jogador
	if type == Type.SPEED_DOWN or type == Type.CLEAR_LINE:
		target_id = p_owner_id

# Retorna o nome do power-up
func get_name() -> String:
	return names[type]

# Retorna a descrição do power-up
func get_description() -> String:
	return descriptions[type]

# Retorna a cor do power-up
func get_color() -> Color:
	return colors[type]

# Verifica se o power-up tem efeito instantâneo
func is_instant() -> bool:
	return duration == 0.0

# Retorna uma representação de string do power-up
func _to_string() -> String:
	return "PowerUp[%s, owner=%d, target=%d, duration=%.1f]" % [get_name(), owner_id, target_id, duration] 