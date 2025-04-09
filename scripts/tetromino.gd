extends Node2D

# Sinais
signal settled

# Constantes
const BLOCK_SIZE = 25

# Tipos de tetrominós e suas formas
const SHAPES = {
	"I": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	"J": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	"L": [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	"O": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	"S": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"T": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	"Z": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
}

# Cores para os diferentes tipos
const COLORS = {
	"I": Color("#00FFFF"),  # Ciano
	"J": Color("#0000FF"),  # Azul
	"L": Color("#FF7F00"),  # Laranja
	"O": Color("#FFFF00"),  # Amarelo
	"S": Color("#00FF00"),  # Verde
	"T": Color("#800080"),  # Roxo
	"Z": Color("#FF0000")   # Vermelho
}

# Rotações - Sistema Super Rotation System (SRS)
const WALL_KICKS = {
	# Rotações para peças J, L, S, T, Z
	"JLSTZ": {
		"0>>1": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
		"1>>2": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
		"2>>3": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
		"3>>0": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)]
	},
	# Rotações para peça I
	"I": {
		"0>>1": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
		"1>>2": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
		"2>>3": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
		"3>>0": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)]
	},
	# A peça O não precisa de teste de colisão de parede, pois sua rotação não muda sua forma
	"O": {
		"0>>1": [Vector2i(0, 0)],
		"1>>2": [Vector2i(0, 0)],
		"2>>3": [Vector2i(0, 0)],
		"3>>0": [Vector2i(0, 0)]
	}
}

# Variáveis do tetromino
var grid = null
var blocks = []
var ghost_blocks = []
var shape_type = ""
var current_rotation = 0  # 0, 1, 2, 3 (0, 90, 180, 270 graus)
var current_shape = []
var level = 1

# Variáveis de movimentação
var fall_speed = 1.0
var fall_speed_multiplier = 1.0
var move_cooldown = 0.0
var move_cooldown_time = 0.08
var grid_position = Vector2i(0, 0)
var is_special = false

# Nós
@onready var blocks_container = $Blocks
@onready var ghost_piece = $GhostPiece
@onready var fall_timer = $FallTimer
@onready var lock_delay_timer = $LockDelayTimer

# Inicialização
func _ready():
	fall_timer.timeout.connect(_on_fall_timer_timeout)
	lock_delay_timer.timeout.connect(_on_lock_delay_timer_timeout)
	fall_timer.wait_time = get_fall_time_for_level(level)
	fall_timer.start()

# Inicializa o tetromino com valores específicos
func init(player_level = 1, difficulty = 1, special_chance = 0.1):
	level = player_level
	fall_timer.wait_time = get_fall_time_for_level(level)
	
	# Define se é uma peça especial com base na chance
	is_special = randf() < special_chance
	
	# Seleciona um tipo aleatório de tetromino
	var types = SHAPES.keys()
	shape_type = types[randi() % types.size()]
	
	# Configura a forma inicial
	current_shape = SHAPES[shape_type].duplicate()
	current_rotation = 0
	
	# Cria os blocos visuais
	create_blocks()
	
	# Cria os blocos fantasma para preview
	create_ghost_blocks()
	
	# Inicia o movimento
	fall_timer.start()

# Cria os blocos visuais para o tetromino
func create_blocks():
	# Limpa blocos existentes
	for block in blocks:
		block.queue_free()
	blocks.clear()
	
	# Determina a cor com base no tipo
	var color = COLORS[shape_type]
	if is_special:
		# Peças especiais têm um efeito visual diferente
		color = color.lightened(0.3)
	
	# Cria um bloco para cada posição da forma
	for pos in current_shape:
		var block = ColorRect.new()
		block.size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
		block.color = color
		block.position = Vector2(pos.x * BLOCK_SIZE, pos.y * BLOCK_SIZE)
		
		# Adiciona uma borda
		var border = ReferenceRect.new()
		border.size = block.size
		border.border_color = Color(0, 0, 0, 0.3)
		border.border_width = 1.0
		border.editor_only = false
		block.add_child(border)
		
		# Se for especial, adiciona um indicador visual
		if is_special:
			var indicator = ColorRect.new()
			indicator.size = Vector2(BLOCK_SIZE * 0.4, BLOCK_SIZE * 0.4)
			indicator.position = Vector2(BLOCK_SIZE * 0.3, BLOCK_SIZE * 0.3)
			indicator.color = Color(1, 1, 1, 0.7)
			block.add_child(indicator)
		
		blocks_container.add_child(block)
		blocks.append(block)

# Cria os blocos fantasma para a visualização da queda
func create_ghost_blocks():
	# Limpa blocos existentes
	for block in ghost_blocks:
		block.queue_free()
	ghost_blocks.clear()
	
	# Cria um bloco fantasma para cada posição
	for pos in current_shape:
		var ghost_block = ColorRect.new()
		ghost_block.size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
		ghost_block.color = COLORS[shape_type]
		ghost_block.position = Vector2(pos.x * BLOCK_SIZE, pos.y * BLOCK_SIZE)
		
		# Borda para o bloco fantasma
		var border = ReferenceRect.new()
		border.size = ghost_block.size
		border.border_color = Color(1, 1, 1, 0.3)
		border.border_width = 1.0
		border.editor_only = false
		ghost_block.add_child(border)
		
		ghost_piece.add_child(ghost_block)
		ghost_blocks.append(ghost_block)
	
	update_ghost_position()

# Atualiza a posição do bloco fantasma
func update_ghost_position():
	if grid == null:
		return
		
	# Encontra a posição mais baixa possível para a peça atual
	var test_position = grid_position
	var valid_position = test_position
	
	while grid.is_valid_position(current_shape, Vector2i(test_position.x, test_position.y + 1)):
		test_position.y += 1
		valid_position = test_position
	
	# Posiciona o bloco fantasma
	ghost_piece.position = Vector2(valid_position.x * BLOCK_SIZE, valid_position.y * BLOCK_SIZE)

# Define a grade de jogo
func set_grid(tetris_grid):
	grid = tetris_grid

# Move a peça para a esquerda
func move_left():
	if grid == null or move_cooldown > 0:
		return false
		
	move_cooldown = move_cooldown_time
	
	var new_position = Vector2i(grid_position.x - 1, grid_position.y)
	if grid.is_valid_position(current_shape, new_position):
		grid_position = new_position
		position = Vector2(grid_position.x * BLOCK_SIZE, grid_position.y * BLOCK_SIZE)
		update_ghost_position()
		return true
	
	return false

# Move a peça para a direita
func move_right():
	if grid == null or move_cooldown > 0:
		return false
		
	move_cooldown = move_cooldown_time
	
	var new_position = Vector2i(grid_position.x + 1, grid_position.y)
	if grid.is_valid_position(current_shape, new_position):
		grid_position = new_position
		position = Vector2(grid_position.x * BLOCK_SIZE, grid_position.y * BLOCK_SIZE)
		update_ghost_position()
		return true
	
	return false

# Move a peça para baixo (queda suave)
func soft_drop():
	if grid == null:
		return false
		
	var new_position = Vector2i(grid_position.x, grid_position.y + 1)
	if grid.is_valid_position(current_shape, new_position):
		grid_position = new_position
		position = Vector2(grid_position.x * BLOCK_SIZE, grid_position.y * BLOCK_SIZE)
		
		# Reinicia o temporizador de queda
		fall_timer.start()
		
		return true
	else:
		# Se não puder mover para baixo, inicia o timer de travamento
		lock_delay_timer.start()
		return false

# Queda rápida (hard drop)
func hard_drop():
	if grid == null:
		return false
		
	var drop_distance = 0
	
	while soft_drop():
		drop_distance += 1
	
	# Adiciona pontos extras pelo hard drop
	if drop_distance > 0:
		# A pontuação é tratada pelo grid ou pelo game manager
		pass
	
	# Trava a peça imediatamente
	lock_piece()
	
	return true

# Rotaciona a peça
func rotate_piece():
	if grid == null or shape_type == "O":  # O não precisa de rotação
		return false
	
	# Guarda a rotação atual
	var old_rotation = current_rotation
	
	# Calcula a nova rotação
	var new_rotation = (current_rotation + 1) % 4
	
	# Guarda a forma atual
	var old_shape = current_shape.duplicate()
	
	# Gera a nova forma após a rotação
	var new_shape = []
	
	for pos in SHAPES[shape_type]:
		# Aplica a matriz de rotação
		var new_pos = Vector2i()
		
		match new_rotation:
			0:  # 0 graus
				new_pos = Vector2i(pos.x, pos.y)
			1:  # 90 graus
				new_pos = Vector2i(-pos.y, pos.x)
			2:  # 180 graus
				new_pos = Vector2i(-pos.x, -pos.y)
			3:  # 270 graus
				new_pos = Vector2i(pos.y, -pos.x)
		
		new_shape.append(new_pos)
	
	# Normaliza as coordenadas para garantir que começam em 0,0
	var min_x = 999
	var min_y = 999
	for pos in new_shape:
		min_x = min(min_x, pos.x)
		min_y = min(min_y, pos.y)
	
	for i in range(new_shape.size()):
		new_shape[i] = Vector2i(new_shape[i].x - min_x, new_shape[i].y - min_y)
	
	# Testa se a nova posição é válida com os "wall kicks" do SRS
	var kick_tests = []
	var kick_type = "JLSTZ"
	
	if shape_type == "I":
		kick_type = "I"
	elif shape_type == "O":
		kick_type = "O"
	
	var kick_key = "%d>>%d" % [old_rotation, new_rotation]
	if WALL_KICKS[kick_type].has(kick_key):
		kick_tests = WALL_KICKS[kick_type][kick_key]
	
	# Tenta aplicar os testes de wall kick
	for kick in kick_tests:
		var test_position = Vector2i(grid_position.x + kick.x, grid_position.y + kick.y)
		if grid.is_valid_position(new_shape, test_position):
			# Aplicando a rotação bem sucedida
			current_shape = new_shape
			current_rotation = new_rotation
			grid_position = test_position
			
			# Atualiza a posição visual
			position = Vector2(grid_position.x * BLOCK_SIZE, grid_position.y * BLOCK_SIZE)
			
			# Atualiza a aparência
			update_blocks_position()
			update_ghost_position()
			
			return true
	
	# Se chegou aqui, nenhum dos testes de wall kick funcionou
	return false

# Atualiza a posição visual dos blocos
func update_blocks_position():
	for i in range(min(blocks.size(), current_shape.size())):
		var block_pos = current_shape[i]
		blocks[i].position = Vector2(block_pos.x * BLOCK_SIZE, block_pos.y * BLOCK_SIZE)

# Fixa a peça na grade
func lock_piece():
	if grid == null:
		return
	
	fall_timer.stop()
	lock_delay_timer.stop()
	
	# Adiciona a peça à grade
	grid.add_piece(current_shape, grid_position, shape_type, is_special)
	
	# Emite sinal de que a peça assentou
	emit_signal("settled")

# Física/movimento processado a cada frame
func _process(delta):
	# Reduz o cooldown de movimento
	if move_cooldown > 0:
		move_cooldown -= delta

# Callback do timer de queda
func _on_fall_timer_timeout():
	# Aplica o multiplicador de velocidade (usado por power-ups)
	fall_timer.wait_time = get_fall_time_for_level(level) / fall_speed_multiplier
	
	# Tenta mover a peça para baixo
	if not soft_drop():
		# Se não puder mover, inicia o temporizador de travamento
		if not lock_delay_timer.is_stopped():
			lock_delay_timer.start()
	
	fall_timer.start()

# Callback do timer de travamento
func _on_lock_delay_timer_timeout():
	lock_piece()

# Calcula o tempo de queda com base no nível
func get_fall_time_for_level(level):
	# Fórmula clássica do Tetris: quanto maior o nível, menor o tempo de queda
	return max(0.1, 1.0 - ((level - 1) * 0.05))

# Aumenta a velocidade de queda de acordo com o nível
func increase_fall_speed(new_level):
	level = new_level
	fall_timer.wait_time = get_fall_time_for_level(level)

# Define um multiplicador de velocidade de queda (usado por power-ups)
func set_fall_speed_multiplier(multiplier):
	fall_speed_multiplier = multiplier
	fall_timer.wait_time = get_fall_time_for_level(level) / fall_speed_multiplier

# Restaura a velocidade de queda normal após fim de um power-up
func reset_fall_speed_multiplier():
	fall_speed_multiplier = 1.0
	fall_timer.wait_time = get_fall_time_for_level(level)

# Retorna dados da forma para exibição na UI
func get_shape_data():
	return {
		"shape": current_shape,
		"type": shape_type,
		"special": is_special
	} 