extends Node

class_name PowerUpSystem

# Sinais
signal power_up_spawned(power_up_type, player_id)
signal power_up_activated(power_up_type, player_id, target_id)
signal power_up_ended(power_up_type, player_id, target_id)
signal power_up_available(power_up_type, player_id)

# Tipos de power-ups
enum PowerUpType {
	CLEAR_LINE,      # Limpa uma linha aleatória na grade do adversário
	SPEED_UP,        # Aumenta a velocidade de queda das peças do adversário
	SPEED_DOWN,      # Diminui a velocidade de queda das próprias peças
	BLOCK_ROTATION,  # Impede o adversário de girar peças
	BLOCK_MOVEMENT,  # Impede o adversário de mover peças lateralmente
	FLIP_CONTROLS,   # Inverte os controles do adversário
	GARBAGE_LINES,   # Adiciona linhas de lixo na grade do adversário
	RANDOM_BLOCKS,   # Envia blocos aleatórios para o adversário
	INSTANT_DROP     # Dropa instantaneamente a peça atual do adversário
}

# Duração dos efeitos dos power-ups (em segundos)
const POWER_UP_DURATIONS = {
	PowerUpType.CLEAR_LINE: 0.0,       # Efeito instantâneo
	PowerUpType.SPEED_UP: 10.0,        # 10 segundos
	PowerUpType.SPEED_DOWN: 10.0,      # 10 segundos
	PowerUpType.BLOCK_ROTATION: 8.0,   # 8 segundos
	PowerUpType.BLOCK_MOVEMENT: 6.0,   # 6 segundos
	PowerUpType.FLIP_CONTROLS: 12.0,   # 12 segundos
	PowerUpType.GARBAGE_LINES: 0.0,    # Efeito instantâneo
	PowerUpType.RANDOM_BLOCKS: 0.0,    # Efeito instantâneo
	PowerUpType.INSTANT_DROP: 0.0      # Efeito instantâneo
}

# Power-ups ativos por jogador
var active_power_ups = {
	1: {},  # player_id: {tipo: {timer: Timer, target_player_id: int}}
	2: {}
}

# Peso dos power-ups para geração (maior = mais frequente)
const POWER_UP_WEIGHTS = {
	PowerUpType.CLEAR_LINE: 10,
	PowerUpType.SPEED_UP: 12,
	PowerUpType.SPEED_DOWN: 15,
	PowerUpType.BLOCK_ROTATION: 8,
	PowerUpType.BLOCK_MOVEMENT: 8,
	PowerUpType.FLIP_CONTROLS: 5,
	PowerUpType.GARBAGE_LINES: 7,
	PowerUpType.RANDOM_BLOCKS: 6,
	PowerUpType.INSTANT_DROP: 3
}

# Sistema de geração de power-ups
var power_up_spawn_time_min = 15.0
var power_up_spawn_time_max = 30.0
var next_power_up_time = 0.0
var game_time = 0.0

# Armazenamento de power-ups disponíveis
var available_power_ups = {1: [], 2: []}  # {player_id: [PowerUpType]}

# Referências
var player_grids = {}
var player_controllers = {}

# Configuração
func setup(grids, controllers):
	player_grids = grids
	player_controllers = controllers
	randomize()
	_reset_power_up_timer()

func _process(delta):
	game_time += delta
	
	# Verifica se é hora de gerar um novo power-up
	if game_time >= next_power_up_time:
		_spawn_random_power_up()
		_reset_power_up_timer()

# Reseta o timer para o próximo power-up
func _reset_power_up_timer():
	next_power_up_time = game_time + randf_range(power_up_spawn_time_min, power_up_spawn_time_max)

# Gera um power-up para um jogador aleatório
func _spawn_random_power_up():
	var player_id = 1 + randi() % 2  # Jogador 1 ou 2
	var power_up_type = generate_random_power_up(player_id)
	
	# Adiciona à lista de power-ups disponíveis
	if available_power_ups[player_id].size() < 3:  # Máximo de 3 power-ups por jogador
		available_power_ups[player_id].append(power_up_type)
		emit_signal("power_up_spawned", power_up_type, player_id)

# Gera um power-up aleatório com base nos pesos
func generate_random_power_up(player_id):
	var total_weight = 0
	var power_up_types = PowerUpType.values()
	
	for type in power_up_types:
		total_weight += POWER_UP_WEIGHTS[type]
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for type in power_up_types:
		current_weight += POWER_UP_WEIGHTS[type]
		if random_value < current_weight:
			emit_signal("power_up_available", type, player_id)
			return type
	
	# Fallback se algo der errado
	return PowerUpType.CLEAR_LINE

# Usa um power-up disponível
func use_power_up(player_id, power_up_index, target_player_id):
	if power_up_index < 0 or power_up_index >= available_power_ups[player_id].size():
		return false
	
	var power_up_type = available_power_ups[player_id][power_up_index]
	available_power_ups[player_id].remove_at(power_up_index)
	
	apply_power_up(power_up_type, player_id, target_player_id)
	return true

# Aplica o efeito do power-up
func apply_power_up(power_up_type, player_id, target_player_id):
	# Verifica se as referências são válidas
	if !player_grids.has(target_player_id) or !player_controllers.has(target_player_id):
		return
	
	# Referenciar a grade e controlador alvo
	var target_grid = player_grids[target_player_id]
	var target_controller = player_controllers[target_player_id]
	
	# Aplica o efeito com base no tipo de power-up
	match power_up_type:
		PowerUpType.CLEAR_LINE:
			_apply_clear_line(target_grid)
			
		PowerUpType.SPEED_UP:
			_apply_speed_up(target_controller, player_id, target_player_id)
			
		PowerUpType.SPEED_DOWN:
			_apply_speed_down(player_controllers[player_id], player_id, player_id)
			
		PowerUpType.BLOCK_ROTATION:
			_apply_block_rotation(target_controller, player_id, target_player_id)
			
		PowerUpType.BLOCK_MOVEMENT:
			_apply_block_movement(target_controller, player_id, target_player_id)
			
		PowerUpType.FLIP_CONTROLS:
			_apply_flip_controls(target_controller, player_id, target_player_id)
			
		PowerUpType.GARBAGE_LINES:
			_apply_garbage_lines(target_grid)
			
		PowerUpType.RANDOM_BLOCKS:
			_apply_random_blocks(target_grid)
			
		PowerUpType.INSTANT_DROP:
			_apply_instant_drop(target_controller)
	
	# Emitir sinal de ativação
	emit_signal("power_up_activated", power_up_type, player_id, target_player_id)

# Funções de aplicação dos power-ups
func _apply_clear_line(target_grid):
	# Encontra uma linha com mais blocos
	var grid_size = target_grid.get_grid_size()
	var best_line = -1
	var max_blocks = 0
	
	for y in range(grid_size.y):
		var block_count = 0
		for x in range(grid_size.x):
			if target_grid.is_cell_occupied(Vector2i(x, y)):
				block_count += 1
		
		if block_count > max_blocks:
			max_blocks = block_count
			best_line = y
	
	# Se encontrou uma linha com blocos, limpa-a
	if best_line >= 0:
		target_grid.clear_line(best_line)

func _apply_speed_up(target_controller, player_id, target_player_id):
	var tetromino = target_controller.get_active_tetromino()
	if tetromino:
		var original_speed = tetromino.fall_speed
		# Aumenta a velocidade em 2x
		tetromino.set_fall_speed(original_speed * 2.0)
		
		# Configura um timer para o fim do efeito
		var duration = POWER_UP_DURATIONS[PowerUpType.SPEED_UP]
		_setup_power_up_timer(PowerUpType.SPEED_UP, player_id, target_player_id, duration)

func _apply_speed_down(player_controller, player_id, target_player_id):
	var tetromino = player_controller.get_active_tetromino()
	if tetromino:
		var original_speed = tetromino.fall_speed
		# Reduz a velocidade para 0.5x
		tetromino.set_fall_speed(original_speed * 0.5)
		
		# Configura um timer para o fim do efeito
		var duration = POWER_UP_DURATIONS[PowerUpType.SPEED_DOWN]
		_setup_power_up_timer(PowerUpType.SPEED_DOWN, player_id, target_player_id, duration)

func _apply_block_rotation(target_controller, player_id, target_player_id):
	target_controller.set_rotation_blocked(true)
	
	# Configura um timer para o fim do efeito
	var duration = POWER_UP_DURATIONS[PowerUpType.BLOCK_ROTATION]
	_setup_power_up_timer(PowerUpType.BLOCK_ROTATION, player_id, target_player_id, duration)

func _apply_block_movement(target_controller, player_id, target_player_id):
	target_controller.set_movement_blocked(true)
	
	# Configura um timer para o fim do efeito
	var duration = POWER_UP_DURATIONS[PowerUpType.BLOCK_MOVEMENT]
	_setup_power_up_timer(PowerUpType.BLOCK_MOVEMENT, player_id, target_player_id, duration)

func _apply_flip_controls(target_controller, player_id, target_player_id):
	target_controller.set_controls_flipped(true)
	
	# Configura um timer para o fim do efeito
	var duration = POWER_UP_DURATIONS[PowerUpType.FLIP_CONTROLS]
	_setup_power_up_timer(PowerUpType.FLIP_CONTROLS, player_id, target_player_id, duration)

func _apply_garbage_lines(target_grid):
	# Adiciona 1-3 linhas de lixo (aleatório)
	var lines_count = 1 + randi() % 3
	target_grid.add_garbage_lines(lines_count)

func _apply_random_blocks(target_grid):
	# Adiciona 3-7 blocos aleatórios na grade
	var blocks_count = 3 + randi() % 5
	var grid_size = target_grid.get_grid_size()
	
	for _i in range(blocks_count):
		var x = randi() % grid_size.x
		var y = int(grid_size.y * 0.5) + randi() % int(grid_size.y * 0.5)  # Metade inferior da grade
		
		# Evita colocar em células já ocupadas
		if !target_grid.is_cell_occupied(Vector2i(x, y)):
			target_grid.set_cell(Vector2i(x, y), randi() % 7)  # Cor aleatória

func _apply_instant_drop(target_controller):
	var tetromino = target_controller.get_active_tetromino()
	if tetromino:
		tetromino.hard_drop()

# Configura um timer para o fim do efeito do power-up
func _setup_power_up_timer(power_up_type, player_id, target_player_id, duration):
	# Verifica se há um power-up do mesmo tipo já ativo
	if active_power_ups[player_id].has(power_up_type):
		var timer = active_power_ups[player_id][power_up_type].timer
		if timer and timer.time_left > 0:
			# Cancela o timer existente
			timer.stop()
			timer.queue_free()
	
	# Cria um novo timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_power_up_timer_timeout.bind(power_up_type, player_id, target_player_id))
	timer.start()
	
	# Armazena a informação do power-up ativo
	active_power_ups[player_id][power_up_type] = {
		"timer": timer,
		"target_player_id": target_player_id
	}

# Callback para o fim do efeito do power-up
func _on_power_up_timer_timeout(power_up_type, player_id, target_player_id):
	# Remove o timer e a entrada do dicionário
	if active_power_ups[player_id].has(power_up_type):
		var timer = active_power_ups[player_id][power_up_type].timer
		if timer:
			timer.queue_free()
		active_power_ups[player_id].erase(power_up_type)
	
	# Reverte o efeito do power-up
	match power_up_type:
		PowerUpType.SPEED_UP:
			_revert_speed_up(target_player_id)
			
		PowerUpType.SPEED_DOWN:
			_revert_speed_down(player_id)
			
		PowerUpType.BLOCK_ROTATION:
			_revert_block_rotation(target_player_id)
			
		PowerUpType.BLOCK_MOVEMENT:
			_revert_block_movement(target_player_id)
			
		PowerUpType.FLIP_CONTROLS:
			_revert_flip_controls(target_player_id)
	
	# Emitir sinal de fim do efeito
	emit_signal("power_up_ended", power_up_type, player_id, target_player_id)

# Funções para reverter efeitos dos power-ups
func _revert_speed_up(target_player_id):
	if player_controllers.has(target_player_id):
		var tetromino = player_controllers[target_player_id].get_active_tetromino()
		if tetromino:
			# Restaura a velocidade normal com base no nível
			var game_manager = get_node("/root/GameManager")
			if game_manager:
				var level = game_manager.player_data[target_player_id].level
				var normal_speed = game_manager.get_fall_speed_for_level(level)
				tetromino.set_fall_speed(normal_speed)

func _revert_speed_down(player_id):
	if player_controllers.has(player_id):
		var tetromino = player_controllers[player_id].get_active_tetromino()
		if tetromino:
			# Restaura a velocidade normal com base no nível
			var game_manager = get_node("/root/GameManager")
			if game_manager:
				var level = game_manager.player_data[player_id].level
				var normal_speed = game_manager.get_fall_speed_for_level(level)
				tetromino.set_fall_speed(normal_speed)

func _revert_block_rotation(target_player_id):
	if player_controllers.has(target_player_id):
		player_controllers[target_player_id].set_rotation_blocked(false)

func _revert_block_movement(target_player_id):
	if player_controllers.has(target_player_id):
		player_controllers[target_player_id].set_movement_blocked(false)

func _revert_flip_controls(target_player_id):
	if player_controllers.has(target_player_id):
		player_controllers[target_player_id].set_controls_flipped(false)

# Verifica se um power-up está ativo para um jogador
func is_power_up_active(power_up_type, player_id):
	return active_power_ups[player_id].has(power_up_type) and \
		   active_power_ups[player_id][power_up_type].timer and \
		   active_power_ups[player_id][power_up_type].timer.time_left > 0

# Obtém o tempo restante de um power-up
func get_power_up_time_left(power_up_type, player_id):
	if is_power_up_active(power_up_type, player_id):
		return active_power_ups[player_id][power_up_type].timer.time_left
	return 0.0

# Obtém os power-ups disponíveis para um jogador
func get_available_power_ups(player_id):
	return available_power_ups[player_id]

# Limpa todos os power-ups ativos quando o jogo termina
func clear_all_power_ups():
	for player_id in active_power_ups.keys():
		for power_up_type in active_power_ups[player_id].keys():
			var data = active_power_ups[player_id][power_up_type]
			if data.timer:
				data.timer.stop()
				data.timer.queue_free()
				
			# Reverte efeitos imediatamente
			match power_up_type:
				PowerUpType.SPEED_UP:
					_revert_speed_up(data.target_player_id)
				PowerUpType.SPEED_DOWN:
					_revert_speed_down(player_id)
				PowerUpType.BLOCK_ROTATION:
					_revert_block_rotation(data.target_player_id)
				PowerUpType.BLOCK_MOVEMENT:
					_revert_block_movement(data.target_player_id)
				PowerUpType.FLIP_CONTROLS:
					_revert_flip_controls(data.target_player_id)
	
	# Limpa os dicionários
	for player_id in active_power_ups.keys():
		active_power_ups[player_id].clear()
		available_power_ups[player_id].clear() 