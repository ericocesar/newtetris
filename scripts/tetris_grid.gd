extends Node2D

class_name TetrisGrid

# Referência ao script de power-up
const PowerUpClass = preload("res://scripts/power_up.gd")

# Constantes do jogo
const CELL_SIZE = 32
const GRID_WIDTH = 10
const GRID_HEIGHT = 22
const EMPTY_CELL = 0

# Referências a outros scripts
var Tetromino = load("res://scripts/tetromino.gd")

# Variáveis do jogo
var grid = []
var current_piece = null
var ghost_piece = null
var next_piece = null
var held_piece = null
var can_hold = true
var drop_timer = 0
var drop_speed = 1.0
var player_id = 1
var is_game_over = false
var is_frozen = false
var freeze_timer = 0

# Variáveis para power-ups
var active_power_ups = []
var available_power_ups = []
var power_up_meter = 0
var power_up_threshold = 4 # Número de linhas para ganhar power-up

# Sinais
signal game_over
signal piece_locked
signal lines_cleared(num_lines, player_id)
signal power_up_activated(type, player_id)
signal power_up_deactivated(type, player_id)
signal power_up_received(type, from_player_id)
signal power_up_gained(type, player_id)
signal power_up_used(type, player_id)
signal power_up_meter_updated(value, threshold)

# Inicialização
func _ready():
	randomize()
	reset_grid()

# Reset da grade para o estado inicial
func reset_grid():
	grid = []
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append(EMPTY_CELL)
		grid.append(row)
	
	is_game_over = false
	is_frozen = false
	freeze_timer = 0
	
	# Reset de power-ups
	reset_power_ups()
	
	# Iniciar com uma nova peça
	current_piece = Tetromino.random_piece()
	next_piece = Tetromino.random_piece()
	update_ghost_piece()

# Reinicia o sistema de power-ups
func reset_power_ups():
	active_power_ups = []
	available_power_ups = []
	power_up_meter = 0
	emit_signal("power_up_meter_updated", power_up_meter, power_up_threshold)

# Loop principal
func _process(delta):
	if is_game_over or GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	# Lidar com o congelamento de peça
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0:
			is_frozen = false
	
	# Atualizar power-ups ativos
	process_active_power_ups(delta)
	
	# Atualiza o temporizador de queda
	if !is_frozen:
		drop_timer += delta
		if drop_timer >= drop_speed:
			drop_timer = 0
			
			# Verificar bombas antes de mover
			if current_piece and current_piece.is_bomb and check_bomb_collision():
				return  # Bomba explodiu, não continua o movimento
				
			move_piece_down()
	
	# Atualiza a peça fantasma a cada frame
	update_ghost_piece()
	
	# Redesenha o jogo
	queue_redraw()

# Processa os power-ups ativos
func process_active_power_ups(delta):
	var i = 0
	while i < active_power_ups.size():
		var power_up = active_power_ups[i]
		power_up.process(delta, player_id)
		
		if !power_up.active:
			emit_signal("power_up_deactivated", power_up.power_type, player_id)
			active_power_ups.remove_at(i)
		else:
			i += 1

# Desenhando tudo na tela
func _draw():
	if is_game_over:
		return
	
	# Desenhar a grade
	draw_grid_background()
	
	# Desenhar as células ocupadas na grade
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] != EMPTY_CELL:
				var cell_type = grid[y][x]
				var cell_is_special = false
				
				# Verifica se é uma célula especial (código da peça é negativo para células especiais)
				if cell_type < 0 and cell_type != EMPTY_CELL:
					cell_type = abs(cell_type) - 1
					cell_is_special = true
				
				var color = Tetromino.COLORS[cell_type]
				if cell_is_special:
					color = Color(color.r + 0.2, color.g + 0.2, color.b + 0.2, 1.0)
				
				draw_block(x, y, color)
	
	# Desenhar a peça fantasma
	if ghost_piece and not is_frozen:
		draw_tetromino(ghost_piece)
	
	# Desenhar a peça atual
	if current_piece and not is_game_over:
		draw_tetromino(current_piece)
	
	# Efeito visual para peça congelada
	if is_frozen and current_piece:
		draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), 
			Color(0.5, 0.8, 1.0, 0.2), false, 3.0)

# Desenha o fundo da grade
func draw_grid_background():
	# Desenhar o fundo da grade
	draw_rect(Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), 
		Color(0.1, 0.1, 0.1, 1.0), true)
	
	# Desenhar as linhas da grade
	for x in range(GRID_WIDTH + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE), 
			Color(0.3, 0.3, 0.3, 0.5), 1.0)
	
	for y in range(GRID_HEIGHT + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE), 
			Color(0.3, 0.3, 0.3, 0.5), 1.0)

# Desenha um bloco na posição especificada
func draw_block(x, y, color):
	var pos_x = x * CELL_SIZE
	var pos_y = y * CELL_SIZE
	
	# Cor de fundo do bloco
	draw_rect(Rect2(pos_x, pos_y, CELL_SIZE, CELL_SIZE), color, true)
	
	# Borda mais clara para dar efeito 3D
	var light_color = Color(min(color.r + 0.3, 1.0), min(color.g + 0.3, 1.0), min(color.b + 0.3, 1.0), color.a)
	var dark_color = Color(max(color.r - 0.3, 0.0), max(color.g - 0.3, 0.0), max(color.b - 0.3, 0.0), color.a)
	
	draw_line(Vector2(pos_x, pos_y), Vector2(pos_x + CELL_SIZE, pos_y), light_color, 2.0)
	draw_line(Vector2(pos_x, pos_y), Vector2(pos_x, pos_y + CELL_SIZE), light_color, 2.0)
	draw_line(Vector2(pos_x + CELL_SIZE, pos_y), Vector2(pos_x + CELL_SIZE, pos_y + CELL_SIZE), dark_color, 2.0)
	draw_line(Vector2(pos_x, pos_y + CELL_SIZE), Vector2(pos_x + CELL_SIZE, pos_y + CELL_SIZE), dark_color, 2.0)

# Desenha uma peça tetromino
func draw_tetromino(piece):
	var shape = piece.get_shape()
	var color = piece.get_color()
	
	for y in range(4):
		for x in range(4):
			if shape[y][x] == 1:
				var grid_x = piece.position.x + x
				var grid_y = piece.position.y + y
				
				# Só desenha se estiver dentro da grade visível
				if grid_y >= 0 and grid_y < GRID_HEIGHT and grid_x >= 0 and grid_x < GRID_WIDTH:
					draw_block(grid_x, grid_y, color)

# Atualiza a posição da peça fantasma
func update_ghost_piece():
	if current_piece == null:
		ghost_piece = null
		return
	
	ghost_piece = current_piece.create_ghost()
	
	# Move a peça fantasma o máximo possível para baixo
	while can_piece_move(ghost_piece, Vector2i(0, 1)):
		ghost_piece.position.y += 1

# Verifica se uma peça pode se mover para a posição especificada
func can_piece_move(piece, movement: Vector2i):
	var new_position = piece.position + movement
	var shape = piece.get_shape()
	
	for y in range(4):
		for x in range(4):
			if shape[y][x] == 1:
				var grid_x = new_position.x + x
				var grid_y = new_position.y + y
				
				# Verifica colisão com as paredes e o chão
				if grid_x < 0 or grid_x >= GRID_WIDTH or grid_y >= GRID_HEIGHT:
					return false
				
				# Verifica colisão com peças já na grade
				if grid_y >= 0 and grid[grid_y][grid_x] != EMPTY_CELL:
					return false
	
	return true

# Verifica se a peça pode girar
func can_piece_rotate(piece):
	var new_rotation = (piece.rotation + 1) % 4
	var test_piece = piece.duplicate()
	test_piece.rotation = new_rotation
	
	# Algoritmo de wallkick: tenta várias posições de ajuste caso a rotação colida
	var wallkick_tests = [
		Vector2i(0, 0),   # Sem ajuste
		Vector2i(-1, 0),  # 1 à esquerda
		Vector2i(1, 0),   # 1 à direita
		Vector2i(0, -1),  # 1 para cima
		Vector2i(-1, -1), # 1 esquerda, 1 cima
		Vector2i(1, -1)   # 1 direita, 1 cima
	]
	
	# Para a peça I, adicione mais testes
	if piece.type == Tetromino.Types.I:
		wallkick_tests.append(Vector2i(-2, 0))  # 2 à esquerda
		wallkick_tests.append(Vector2i(2, 0))   # 2 à direita
	
	for test in wallkick_tests:
		test_piece.position = piece.position + test
		if can_piece_move(test_piece, Vector2i(0, 0)):
			piece.rotation = new_rotation
			piece.position = test_piece.position
			return true
	
	return false

# Move a peça atual para baixo
func move_piece_down():
	if current_piece != null and not is_frozen:
		if can_piece_move(current_piece, Vector2i(0, 1)):
			current_piece.position.y += 1
		else:
			lock_piece()

# Move a peça para a esquerda se possível
func move_piece_left():
	if current_piece != null and not is_frozen:
		if can_piece_move(current_piece, Vector2i(-1, 0)):
			current_piece.position.x -= 1
			update_ghost_piece()

# Move a peça para a direita se possível
func move_piece_right():
	if current_piece != null and not is_frozen:
		if can_piece_move(current_piece, Vector2i(1, 0)):
			current_piece.position.x += 1
			update_ghost_piece()

# Gira a peça atual se possível
func rotate_piece():
	if current_piece != null and not is_frozen:
		can_piece_rotate(current_piece)
		update_ghost_piece()

# Drop rápido - move a peça até o final
func hard_drop():
	if current_piece != null and not is_frozen:
		while can_piece_move(current_piece, Vector2i(0, 1)):
			current_piece.position.y += 1
		
		lock_piece()

# Bloqueia a peça na grade
func lock_piece():
	var shape = current_piece.get_shape()
	
	for y in range(4):
		for x in range(4):
			if shape[y][x] == 1:
				var grid_x = current_piece.position.x + x
				var grid_y = current_piece.position.y + y
				
				# Só adiciona à grade se estiver dentro dos limites
				if grid_y >= 0 and grid_y < GRID_HEIGHT and grid_x >= 0 and grid_x < GRID_WIDTH:
					# Para peças especiais, armazenamos como valor negativo
					if current_piece.is_special:
						grid[grid_y][grid_x] = -(current_piece.type + 1)
					else:
						grid[grid_y][grid_x] = current_piece.type
	
	# Verifica se há linhas completas
	var lines_cleared = check_and_clear_lines()
	
	# Calcula a pontuação (mais pontos para mais linhas de uma vez)
	var score_multiplier = [0, 40, 100, 300, 1200]  # 0, 1, 2, 3, 4 linhas
	var base_score = score_multiplier[min(lines_cleared, 4)] * player_id
	
	# Bônus para peças especiais
	if current_piece.is_special:
		base_score *= 2
	
	if lines_cleared > 0:
		GameManager.add_score(player_id, base_score)
		GameManager.add_lines(player_id, lines_cleared)
		emit_signal("lines_cleared", lines_cleared, player_id)
	
	# Atualiza a velocidade de queda para o nível atual
	drop_speed = GameManager.get_drop_speed(player_id)
	
	# Próxima peça
	spawn_new_piece()
	
	# Emite sinal de que a peça foi bloqueada
	emit_signal("piece_locked")

# Verifica se há linhas completas e as remove
func check_and_clear_lines():
	return clear_lines()

# Verifica se uma célula é uma bomba pelo seu valor
func is_bomb_cell(value):
	# O valor 8 indica uma célula de bomba
	return value == 8

# Limpa linhas completas e detecta bombas
func clear_lines(start_row = 0, end_row = GRID_HEIGHT - 1, detect_bombs = true):
	var lines_cleared = 0
	var bomb_triggered = false
	var bomb_positions = []
	
	# Verificar quais linhas estão completas
	for row in range(start_row, end_row + 1):
		var line_filled = true
		var has_bomb = false
		
		for col in range(GRID_WIDTH):
			if grid[row][col] == EMPTY_CELL:
				line_filled = false
				break
			
			# Verifica se há uma bomba na linha
			if detect_bombs and is_bomb_cell(grid[row][col]):
				has_bomb = true
				bomb_positions.append(Vector2i(col, row))
		
		if line_filled:
			# Move todas as linhas acima para baixo
			for r in range(row, 0, -1):
				for c in range(GRID_WIDTH):
					grid[r][c] = grid[r-1][c]
			
			# Limpa a linha do topo
			for c in range(GRID_WIDTH):
				grid[0][c] = EMPTY_CELL
			
			lines_cleared += 1
			
			# Verifica se há uma bomba na linha que está sendo removida
			if has_bomb:
				bomb_triggered = true
	
	# Processa explosões de bombas se alguma foi encontrada
	if bomb_triggered and detect_bombs:
		# Efeito visual de explosão
		for bomb_pos in bomb_positions:
			# Cria explosão em área 3x3 ao redor da bomba
			for r in range(max(0, bomb_pos.y - 1), min(GRID_HEIGHT, bomb_pos.y + 2)):
				for c in range(max(0, bomb_pos.x - 1), min(GRID_WIDTH, bomb_pos.x + 2)):
					grid[r][c] = EMPTY_CELL
			
			# Efeito visual
			modulate = Color(1.0, 0.5, 0.0, 1.0)  # Laranja para explosão
			await get_tree().create_timer(0.3).timeout
			modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			# Chama clear_lines novamente para processar as linhas após a explosão
			# mas desativa a detecção de bombas para evitar loop infinito
			lines_cleared += clear_lines(max(0, bomb_pos.y - 1), min(GRID_HEIGHT - 1, bomb_pos.y + 1), false)
	
	# Calcula a pontuação com base no número de linhas limpas
	var points = 0
	match lines_cleared:
		1: points = 100
		2: points = 300
		3: points = 500
		4: points = 800
	
	if points > 0:
		GameManager.add_score(player_id, points)
		GameManager.add_lines(player_id, lines_cleared)
		emit_signal("lines_cleared", lines_cleared, player_id)
	
	queue_redraw()
	return lines_cleared

# Adiciona linhas de lixo na parte inferior
func add_garbage_lines(num_lines):
	# Mover linhas existentes para cima
	for y in range(num_lines):
		# Remover linhas do topo
		grid.pop_front()
		
		# Adicionar novas linhas de lixo na parte inferior
		var new_row = []
		for x in range(GRID_WIDTH):
			new_row.append(EMPTY_CELL)
		grid.append(new_row)
	
	# Preencher as linhas de lixo com blocos e uma lacuna aleatória
	for y in range(GRID_HEIGHT - num_lines, GRID_HEIGHT):
		var gap = randi() % GRID_WIDTH  # Posição aleatória para a lacuna
		for x in range(GRID_WIDTH):
			grid[y][x] = EMPTY_CELL if x == gap else (randi() % 7 + 1)  # Valor entre 1-7 para diferentes tipos de blocos
	
	# Atualizar a visualização do grid
	queue_redraw()

# Gera uma nova peça
func spawn_new_piece():
	current_piece = next_piece
	
	# 10% de chance de gerar uma peça especial
	if randf() < 0.1:
		next_piece = Tetromino.random_special_piece()
	else:
		next_piece = Tetromino.random_piece()
	
	can_hold = true
	
	# Verifica se a nova peça pode ser colocada no campo
	if not can_piece_move(current_piece, Vector2i(0, 0)):
		emit_signal("game_over")
		is_game_over = true

# Verifica se o jogo terminou (se há blocos na área de spawn)
func is_game_over_condition():
	# Verifica se há blocos nas duas primeiras linhas
	for y in range(2):
		for x in range(GRID_WIDTH):
			if grid[y][x] != EMPTY_CELL:
				return true
	return false

# Mantém a peça atual e troca pela peça guardada
func hold_piece():
	if current_piece != null and can_hold:
		if held_piece == null:
			held_piece = current_piece.duplicate()
			held_piece.position = Vector2i(3, 0)
			held_piece.rotation = 0
			spawn_new_piece()
		else:
			var temp = held_piece
			held_piece = current_piece.duplicate()
			held_piece.position = Vector2i(3, 0)
			held_piece.rotation = 0
			current_piece = temp
			update_ghost_piece()
		
		can_hold = false

# Ativa um power-up na grade
func activate_power_up(power_type, param = null):
	match power_type:
		GameManager.PowerUp.SPEED_UP:
			# Aumenta a velocidade de queda temporariamente
			powerup_active = true
			powerup_type = power_type
			powerup_timer = 10.0  # 10 segundos de efeito
			drop_speed = drop_speed * 2.0  # Dobra a velocidade
		
		GameManager.PowerUp.LINE_GARBAGE:
			# Adiciona linhas de lixo
			var lines = 1
			if param != null:
				lines = param
			add_garbage_lines(lines)
		
		GameManager.PowerUp.CLEAR_SPECIAL:
			# Remove todas as células especiais
			for y in range(GRID_HEIGHT):
				for x in range(GRID_WIDTH):
					if grid[y][x] < 0 and grid[y][x] != EMPTY_CELL:
						grid[y][x] = EMPTY_CELL
		
		GameManager.PowerUp.BLOCK_FREEZE:
			# Congela a peça atual temporariamente
			is_frozen = true
			freeze_timer = 5.0  # 5 segundos de congelamento

# Função para usar um power-up
func use_power_up(power_type):
	if GameManager.activate_power_up(player_id, power_type):
		emit_signal("power_up_used", power_type, player_id)

# Adicionar função para atualizar power-ups
func update_power_ups(delta):
	var i = 0
	while i < active_power_ups.size():
		var power_up = active_power_ups[i]
		if power_up.update(delta):
			i += 1
		else:
			active_power_ups.remove_at(i)

# Adicionar função para aplicar power-up ao grid
func apply_power_up(power_up):
	# Adicionar o power-up à lista de ativos
	active_power_ups.append(power_up)
	
	# Aplicar efeitos baseados no tipo
	match power_up.type:
		PowerUpClass.Types.SPEED_UP:
			# Aumentar velocidade temporariamente
			var original_speed = drop_speed
			drop_speed *= (1.0 + power_up.strength)
			
			# Restaurar velocidade após expirar
			await get_tree().create_timer(power_up.duration).timeout
			if is_instance_valid(self):
				drop_speed = original_speed
		
		PowerUpClass.Types.BLOCK_FREEZE:
			# Congelar a peça atual
			if current_piece != null:
				is_frozen = true
				freeze_timer = power_up.duration
		
		PowerUpClass.Types.CLEAR_SPECIAL:
			# Limpar células especiais do grid
			for y in range(GRID_HEIGHT):
				for x in range(GRID_WIDTH):
					if grid[y][x] < 0 and grid[y][x] != EMPTY_CELL:
						grid[y][x] = EMPTY_CELL
		
		PowerUpClass.Types.LINE_GARBAGE:
			# Adicionar linhas de lixo
			add_garbage_lines(int(1 + power_up.strength))
		
		PowerUpClass.Types.TETRIS_BOMB:
			# Adicionar um bloco bomba
			spawn_bomb_tetromino()

# Função para limpar células especiais
func clear_special_cells():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if is_cell_special(x, y):
				grid[y][x] = 0
	
	# Atualizar a visualização do grid
	queue_redraw()

# Função para verificar se uma célula é especial
func is_cell_special(x, y):
	# Implementar verificação para células especiais
	# Por exemplo, células com valores > 10 podem ser consideradas especiais
	return grid[y][x] > 10

# Atualiza a função para fazer spawn de bomba
func spawn_bomb_tetromino():
	# Cria uma peça de bomba
	var bomb_piece = Tetromino.create_bomb()
	bomb_piece.position = Vector2i(3, 0)
	
	# Substitui a próxima peça ou a atual se não houver
	if current_piece == null:
		current_piece = bomb_piece
		update_ghost_piece()
	else:
		next_piece = bomb_piece
	
	# Efeito visual
	modulate = Color(1.0, 0.5, 0.0, 1.0)  # Flash laranja
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	emit_signal("power_up_used", GameManager.PowerUp.TETRIS_BOMB, player_id)

# Verifica se o tetromino atual é uma bomba e se está pronto para explodir
func check_bomb_collision():
	if current_piece == null or not current_piece.is_bomb:
		return false
		
	# Verifica se a bomba colidiu com algum bloco ou chegou ao fundo
	var shape = current_piece.get_shape()
	for y in range(4):
		for x in range(4):
			if shape[y][x] == 1:
				var grid_x = current_piece.position.x + x
				var grid_y = current_piece.position.y + y + 1  # Verifica posição abaixo
				
				# Se estiver na parte inferior do grid ou colidir com outro bloco
				if grid_y >= GRID_HEIGHT or (grid_y >= 0 and grid_x >= 0 and grid_x < GRID_WIDTH and grid[grid_y][grid_x] != EMPTY_CELL):
					explode_bomb()
					return true
	
	return false

# Faz a bomba explodir, criando um efeito de explosão e limpando blocos
func explode_bomb():
	# Obtém posição central da bomba
	var center_x = current_piece.position.x + 1  # Centro do formato 2x2
	var center_y = current_piece.position.y + 1
	
	# Efeito visual
	modulate = Color(1.0, 0.3, 0.0, 1.0)  # Laranja intenso
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Limpa uma área 5x5 ao redor da bomba
	var radius = 2
	for y in range(center_y - radius, center_y + radius + 1):
		for x in range(center_x - radius, center_x + radius + 1):
			if x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT:
				grid[y][x] = EMPTY_CELL
	
	# Aplica gravidade aos blocos flutuantes
	apply_gravity()
	
	# Verifica linhas completas após a explosão
	var lines_cleared = check_and_clear_lines()
	
	# Adiciona pontuação pela explosão
	var explosion_score = 300  # Pontuação base pela explosão
	GameManager.add_score(player_id, explosion_score + (lines_cleared * 100))
	
	# Gera nova peça
	current_piece = next_piece if next_piece else Tetromino.random_piece()
	next_piece = Tetromino.random_piece()
	update_ghost_piece()
	
	queue_redraw()

# Aplica gravidade aos blocos flutuantes após uma explosão
func apply_gravity():
	var blocks_moved = true
	
	# Continua aplicando gravidade até que nada mais caia
	while blocks_moved:
		blocks_moved = false
		
		# Começa da parte inferior (exceto última linha) e move para cima
		for y in range(GRID_HEIGHT - 2, -1, -1):
			for x in range(GRID_WIDTH):
				if grid[y][x] != EMPTY_CELL and grid[y + 1][x] == EMPTY_CELL:
					# Move bloco para baixo
					grid[y + 1][x] = grid[y][x]
					grid[y][x] = EMPTY_CELL
					blocks_moved = true
	
	queue_redraw()

# Adicionar na função public para receber e aplicar power-ups de fora
func receive_power_up(power_up_type, from_player_id):
	var power_up = PowerUpClass.new(power_up_type, player_id)
	apply_power_up(power_up)
	
	# Notificar UI ou outros sistemas
	emit_signal("power_up_received", power_up_type, from_player_id)

# Ativa o power-up da bomba, criando uma peça especial de bomba
func activate_bomb_powerup():
	# Cria uma peça de bomba - usando o formato "O" (quadrado)
	var bomb_tetromino = current_piece if current_piece else spawn_new_piece()
	
	# Marca como bomba (valor 8)
	bomb_tetromino.type = Tetromino.Types.O  # Formato de bomba é sempre quadrado
	for block in bomb_tetromino.blocks:
		block.value = 8  # Valor especial para identificar como bomba
	
	# Aplica efeito visual à bomba
	bomb_tetromino.modulate = Color(1.0, 0.0, 0.0, 1.0)  # Vermelho intenso
	
	# Pisca a peça para destacar que é uma bomba
	var tween = create_tween()
	tween.tween_property(bomb_tetromino, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.3)
	tween.tween_property(bomb_tetromino, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.3)
	tween.set_loops(3)
	
	# Aguarda o término do efeito visual
	await tween.finished
	bomb_tetromino.modulate = Color(1.0, 0.0, 0.0, 0.8)  # Vermelho semi-transparente
	
	# Se já existe uma peça atual, a próxima peça será a bomba
	if current_piece:
		next_piece = bomb_tetromino
		update_ghost_piece()
	else:
		# Substitui a peça atual pela bomba
		current_piece = bomb_tetromino
		place_tetromino_at_start(current_piece)
		
	# Avisa o jogador sobre a bomba
	emit_signal("power_up_activated", "Tetris Bomb ativada!", player_id)

# Aplica um power-up recebido
func apply_powerup(power_up_type):
	match power_up_type:
		PowerUp.Types.SPEED_UP:
			# Aumenta a velocidade de queda do oponente
			emit_signal("send_powerup_to_opponent", PowerUp.Types.SPEED_UP, player_id)
			
		PowerUp.Types.SLOW_DOWN:
			# Aplica desaceleração a si mesmo
			current_fall_speed *= 0.5  # Reduz velocidade pela metade
			
			# Cria um temporizador para restaurar a velocidade após 10 segundos
			var timer = get_tree().create_timer(10.0)
			await timer.timeout
			current_fall_speed = calculate_fall_speed(level)  # Restaura velocidade normal
			
		PowerUp.Types.CLEAR_BOTTOM:
			# Limpa as duas linhas inferiores do grid
			for y in range(grid_height - 2, grid_height):
				for x in range(grid_width):
					if grid[y][x] > 0:  # Se tiver um bloco
						grid[y][x] = 0  # Limpa
			update_grid_display()  # Atualiza a exibição do grid
			
		PowerUp.Types.BOMB:
			# Ativa a peça bomba
			activate_bomb_powerup()
			
		PowerUp.Types.SWAP_GRID:
			# Enviar sinal para trocar grids
			emit_signal("send_powerup_to_opponent", PowerUp.Types.SWAP_GRID, player_id)
			
		PowerUp.Types.MIRROR:
			# Inverte o grid horizontalmente
			for y in range(grid_height):
				var row = grid[y].duplicate()
				for x in range(grid_width):
					grid[y][x] = row[grid_width - 1 - x]
			update_grid_display()
			
		PowerUp.Types.RANDOM_BLOCKS:
			# Adiciona blocos aleatórios no grid do oponente
			emit_signal("send_powerup_to_opponent", PowerUp.Types.RANDOM_BLOCKS, player_id)
			
	# Informa à UI sobre o power-up ativado
	emit_signal("power_up_activated", PowerUp.get_name(power_up_type), player_id)

# Processa um power-up recebido do oponente
func receive_powerup_from_opponent(power_up_type):
	match power_up_type:
		PowerUp.Types.SPEED_UP:
			# Aumenta a velocidade de queda
			current_fall_speed *= 1.5  # Aumenta velocidade em 50%
			
			# Cria um temporizador para restaurar a velocidade após 10 segundos
			var timer = get_tree().create_timer(10.0)
			await timer.timeout
			current_fall_speed = calculate_fall_speed(level)  # Restaura velocidade normal
			
		PowerUp.Types.RANDOM_BLOCKS:
			# Adiciona 3-5 blocos aleatórios no grid
			var num_blocks = randi() % 3 + 3  # 3 a 5 blocos
			for i in range(num_blocks):
				var x = randi() % grid_width
				var y = randi() % (grid_height - 5)  # Evita as linhas superiores
				if grid[y][x] == 0:  # Se estiver vazio
					grid[y][x] = randi() % 7 + 1  # Valor aleatório de 1 a 7
			update_grid_display()
			
		PowerUp.Types.SWAP_GRID:
			# Trocar grids - emitir sinal para o Game Manager trocar
			emit_signal("request_grid_swap")
			
	# Informa à UI sobre o power-up recebido
	emit_signal("power_up_received", PowerUp.get_name(power_up_type), player_id)

# Conecta ao receber um power-up
func _on_power_up_received(power_up_type, from_player_id):
	# Se o power-up foi enviado pelo oponente
	if from_player_id != player_id:
		receive_powerup_from_opponent(power_up_type)
	else:
		# Power-up adquirido por este jogador
		apply_powerup(power_up_type)

# Modifica a função de atualização física para verificar colisões de bomba
func _physics_process(delta):
	if is_game_over or GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	# Verifica se é hora de mover o tetromino para baixo
	drop_timer += delta
	if drop_timer >= drop_speed:
		drop_timer = 0
		if current_piece != null:
			# Se o tetromino for uma bomba, verificar colisão especial
			if current_piece.type == Tetromino.Types.O and check_bomb_collision():
				return
				
			# Movimento normal para baixo
			if can_piece_move(current_piece, Vector2i(0, 1)):
				current_piece.position.y += 1
			else:
				lock_piece()
	
	# Atualiza o display a cada frame
	queue_redraw() 