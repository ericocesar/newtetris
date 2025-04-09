extends Node2D

class_name Tetromino

# Sinais
signal settled
signal line_cleared(count, is_tetris, player_id)

# Constantes e enums
enum Shape { I, J, L, O, S, T, Z }
enum RotationState { SPAWN, RIGHT, INVERSE, LEFT }

# Propriedades exportadas
@export var fall_speed: float = 1.0
@export var fast_fall_multiplier: float = 5.0
@export var preview_mode: bool = false
@export var ghost_mode: bool = false
@export var player_id: int = 0

# Variáveis de estado
var shape_type: int
var rotation_state: int = RotationState.SPAWN
var blocks = []
var grid_position = Vector2i(0, 0)
var is_active = false
var fall_timer = 0.0
var fast_fall = false
var locked = false
var lock_delay_timer = 0.0
var lock_delay = 0.5
var lock_resets = 0
var max_lock_resets = 15

# Referência à grid
var grid = null

# Definição dos formatos de peças (coordenadas relativas)
const SHAPES = {
	Shape.I: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	Shape.J: [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	Shape.L: [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	Shape.O: [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	Shape.S: [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	Shape.T: [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	Shape.Z: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
}

# Cores das peças
const COLORS = {
	Shape.I: Color(0, 1, 1),    # Ciano
	Shape.J: Color(0, 0, 1),    # Azul
	Shape.L: Color(1, 0.5, 0),  # Laranja
	Shape.O: Color(1, 1, 0),    # Amarelo
	Shape.S: Color(0, 1, 0),    # Verde
	Shape.T: Color(0.5, 0, 0.5),# Roxo
	Shape.Z: Color(1, 0, 0)     # Vermelho
}

# Dados de rotação SRS (Super Rotation System)
const ROTATION_TESTS = {
	Shape.I: [
		# SPAWN->RIGHT
		[Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)],
		# RIGHT->INVERSE
		[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)],
		# INVERSE->LEFT
		[Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)],
		# LEFT->SPAWN
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)]
	],
	# Para outras peças (exceto O que não gira)
	"default": [
		# SPAWN->RIGHT
		[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
		# RIGHT->INVERSE
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
		# INVERSE->LEFT
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
		# LEFT->SPAWN
		[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)]
	]
}

# Inicialização do tetromino
func _ready():
	if preview_mode or ghost_mode:
		set_process(false)
	else:
		set_process(true)

# Configuração de uma nova peça
func initialize(shape_id: int, grid_ref, start_position: Vector2i):
	shape_type = shape_id
	grid = grid_ref
	grid_position = start_position
	rotation_state = RotationState.SPAWN
	
	# Cria os blocos visuais
	create_blocks()
	
	if not preview_mode and not ghost_mode:
		is_active = true
		fall_timer = 0.0
		fast_fall = false
		locked = false
		lock_delay_timer = 0.0
		lock_resets = 0
		
		# Verifica se a peça pode ser colocada na posição inicial
		if !is_valid_position(grid_position, get_block_positions()):
			# Game over se não puder
			grid.handle_game_over()
			is_active = false
			set_process(false)
	
	# Atualiza a posição visual
	update_visual_position()

# Cria os blocos visuais
func create_blocks():
	# Limpa blocos existentes, se houverem
	for block in blocks:
		if block != null:
			block.queue_free()
	blocks.clear()
	
	# Define a cor base e opacidade
	var color = COLORS[shape_type]
	var opacity = 1.0
	
	if ghost_mode:
		opacity = 0.3  # Fantasma é mais transparente
	elif preview_mode:
		opacity = 0.8  # Preview é ligeiramente transparente
	
	# Cria novos blocos para a peça
	for i in range(4):
		var block = ColorRect.new()
		block.size = Vector2(grid.cell_size, grid.cell_size)
		block.color = color
		block.color.a = opacity
		
		# Adiciona borda aos blocos
		var border = ColorRect.new()
		border.size = Vector2(grid.cell_size, grid.cell_size)
		border.color = Color(0, 0, 0, 0)  # Transparente por padrão
		
		if !ghost_mode:
			var border_width = 2.0
			# Cria a borda apenas desenhando retângulos menores por dentro
			var inner = ColorRect.new()
			inner.size = Vector2(grid.cell_size - 2 * border_width, grid.cell_size - 2 * border_width)
			inner.position = Vector2(border_width, border_width)
			inner.color = color
			border.add_child(inner)
			border.color = Color(1, 1, 1, opacity)  # Borda branca
		
		block.add_child(border)
		add_child(block)
		blocks.append(block)
	
	# Atualiza posições dos blocos
	update_blocks_position()

# Atualiza posições dos blocos baseado na forma atual
func update_blocks_position():
	var shape = SHAPES[shape_type]
	var block_positions = get_block_positions()
	
	for i in range(4):
		if i < blocks.size():
			var pos = block_positions[i]
			blocks[i].position = Vector2(pos.x * grid.cell_size, pos.y * grid.cell_size)

# Atualiza a posição visual do tetromino na grade
func update_visual_position():
	position = Vector2(grid_position.x * grid.cell_size, grid_position.y * grid.cell_size)
	update_blocks_position()
	
	# Atualiza a posição do ghost se não for ghost ou preview
	if !ghost_mode and !preview_mode:
		grid.update_ghost_position()

# Obtém as posições dos blocos após a rotação
func get_block_positions(test_rotation_state = null):
	var current_rotation = rotation_state if test_rotation_state == null else test_rotation_state
	var base_shape = SHAPES[shape_type]
	var rotated_positions = []
	
	# A peça O não gira
	if shape_type == Shape.O:
		return base_shape.duplicate()
	
	# Aplica a rotação
	for pos in base_shape:
		var rotated = Vector2i()
		match current_rotation:
			RotationState.SPAWN:
				rotated = pos
			RotationState.RIGHT:
				rotated = Vector2i(-pos.y, pos.x)
			RotationState.INVERSE:
				rotated = Vector2i(-pos.x, -pos.y)
			RotationState.LEFT:
				rotated = Vector2i(pos.y, -pos.x)
		rotated_positions.append(rotated)
	
	return rotated_positions

# Verifica se uma posição é válida na grade
func is_valid_position(grid_pos, block_positions):
	for pos in block_positions:
		var check_pos = grid_pos + pos
		
		# Verifica limites da grade
		if check_pos.x < 0 or check_pos.x >= grid.grid_width or check_pos.y < 0 or check_pos.y >= grid.grid_height:
			return false
		
		# Verifica colisão com outros blocos
		if grid.is_cell_occupied(check_pos.x, check_pos.y):
			return false
	
	return true

# Move a peça horizontalmente
func move_horizontal(direction):
	if !is_active or locked:
		return false
	
	var new_pos = grid_position + Vector2i(direction, 0)
	
	if is_valid_position(new_pos, get_block_positions()):
		grid_position = new_pos
		update_visual_position()
		
		# Reseta timer de travamento se estiver próximo ao chão
		if is_at_bottom() and lock_resets < max_lock_resets:
			lock_delay_timer = 0.0
			lock_resets += 1
		
		return true
	
	return false

# Move a peça para baixo
func move_down():
	if !is_active or locked:
		return false
	
	var new_pos = grid_position + Vector2i(0, 1)
	
	if is_valid_position(new_pos, get_block_positions()):
		grid_position = new_pos
		update_visual_position()
		return true
	else:
		# Inicia contador de travamento quando atinge o fundo
		if !locked:
			lock_delay_timer = 0.0
			locked = true
		return false

# Queda rápida (hard drop)
func hard_drop():
	if !is_active or locked:
		return
	
	while move_down():
		pass
	
	# Trava a peça imediatamente
	settle()

# Gira a peça
func rotate(clockwise: bool = true):
	if !is_active or locked or shape_type == Shape.O:  # O não gira
		return false
	
	# Determina a próxima rotação
	var next_rotation = rotation_state
	if clockwise:
		next_rotation = (rotation_state + 1) % 4
	else:
		next_rotation = (rotation_state + 3) % 4  # +3 é -1 em módulo 4
	
	# Testes de rotação SRS
	var tests = ROTATION_TESTS.get(shape_type, ROTATION_TESTS["default"])[rotation_state]
	var rotated_positions = get_block_positions(next_rotation)
	
	for test in tests:
		var test_pos = grid_position + test
		
		if is_valid_position(test_pos, rotated_positions):
			grid_position = test_pos
			rotation_state = next_rotation
			update_visual_position()
			
			# Reseta timer de travamento se estiver próximo ao chão
			if is_at_bottom() and lock_resets < max_lock_resets:
				lock_delay_timer = 0.0
				lock_resets += 1
			
			return true
	
	return false

# Verifica se a peça está no fundo
func is_at_bottom():
	var next_pos = grid_position + Vector2i(0, 1)
	return !is_valid_position(next_pos, get_block_positions())

# Habilita/desabilita queda rápida
func set_fast_fall(enable):
	fast_fall = enable

# Fixa a peça na grade
func settle():
	if !is_active:
		return
	
	is_active = false
	locked = true
	var blocks_pos = get_block_positions()
	
	# Adiciona os blocos à grade
	for i in range(blocks_pos.size()):
		var pos = grid_position + blocks_pos[i]
		grid.set_cell(pos.x, pos.y, shape_type)
	
	# Limpa linhas completas
	var lines_cleared = grid.check_lines()
	
	# Emite sinal de assentamento
	emit_signal("settled")
	
	# Emite sinal para linhas limpas
	if lines_cleared > 0:
		var is_tetris = lines_cleared >= 4
		emit_signal("line_cleared", lines_cleared, is_tetris, player_id)
	
	# Remove o tetromino após um breve delay
	await get_tree().create_timer(0.1).timeout
	queue_free()

# Processo de jogo
func _process(delta):
	if !is_active or preview_mode or ghost_mode:
		return
	
	if locked:
		lock_delay_timer += delta
		if lock_delay_timer >= lock_delay:
			settle()
		return
	
	# Atualiza o timer de queda
	fall_timer += delta
	var current_fall_speed = fall_speed
	
	if fast_fall:
		current_fall_speed *= fast_fall_multiplier
	
	if fall_timer >= current_fall_speed:
		fall_timer = 0.0
		
		# Tenta mover para baixo
		if !move_down() and !locked:
			locked = true
			lock_delay_timer = 0.0

# Obtém a posição mais baixa possível para o ghost
func get_drop_position():
	if preview_mode or ghost_mode:
		return grid_position
	
	var drop_pos = grid_position
	var block_positions = get_block_positions()
	
	# Testa posições cada vez mais baixas
	while true:
		var test_pos = drop_pos + Vector2i(0, 1)
		if is_valid_position(test_pos, block_positions):
			drop_pos = test_pos
		else:
			break
	
	return drop_pos

# Define a velocidade de queda
func set_fall_speed(speed):
	fall_speed = speed 