extends Node

# Sinal emitido quando um power-up é ativado
signal power_up_activated(player_id, power_up_type, target_player_id)
# Sinal emitido quando um power-up termina
signal power_up_ended(player_id, power_up_type, target_player_id)
# Sinal emitido quando um power-up está disponível para o jogador
signal power_up_available(player_id, power_up_type)

# Tipos de power-ups disponíveis
enum PowerUpType {
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

# Nomes descritivos dos power-ups
const POWER_UP_NAMES = {
	PowerUpType.CLEAR_LINE: "Limpar Linha",
	PowerUpType.SPEED_UP: "Acelerar",
	PowerUpType.SPEED_DOWN: "Desacelerar",
	PowerUpType.BLOCK_ROTATION: "Bloquear Rotação",
	PowerUpType.BLOCK_MOVEMENT: "Bloquear Movimento",
	PowerUpType.FLIP_CONTROLS: "Inverter Controles",
	PowerUpType.GARBAGE_LINES: "Linhas de Lixo",
	PowerUpType.RANDOM_BLOCKS: "Blocos Aleatórios",
	PowerUpType.INSTANT_DROP: "Queda Instantânea"
}

# Duração dos power-ups em segundos
const POWER_UP_DURATION = {
	PowerUpType.CLEAR_LINE: 0,       # Efeito instantâneo
	PowerUpType.SPEED_UP: 10.0,
	PowerUpType.SPEED_DOWN: 10.0,
	PowerUpType.BLOCK_ROTATION: 5.0,
	PowerUpType.BLOCK_MOVEMENT: 5.0,
	PowerUpType.FLIP_CONTROLS: 8.0,
	PowerUpType.GARBAGE_LINES: 0,    # Efeito instantâneo
	PowerUpType.RANDOM_BLOCKS: 10.0,
	PowerUpType.INSTANT_DROP: 0      # Efeito instantâneo
}

# Frequência de geração de power-ups (a cada X linhas limpas)
const POWER_UP_FREQUENCY = 3

# Chance de cada power-up (de 0 a 1)
const POWER_UP_CHANCES = {
	PowerUpType.CLEAR_LINE: 0.1,
	PowerUpType.SPEED_UP: 0.15,
	PowerUpType.SPEED_DOWN: 0.1,
	PowerUpType.BLOCK_ROTATION: 0.1,
	PowerUpType.BLOCK_MOVEMENT: 0.1,
	PowerUpType.FLIP_CONTROLS: 0.1,
	PowerUpType.GARBAGE_LINES: 0.15,
	PowerUpType.RANDOM_BLOCKS: 0.1,
	PowerUpType.INSTANT_DROP: 0.1
}

# Rastreia power-ups ativos por jogador
var active_power_ups = {
	0: [],  # Jogador 1
	1: []   # Jogador 2
}

# Rastreia power-ups disponíveis por jogador
var available_power_ups = {
	0: [],  # Jogador 1
	1: []   # Jogador 2
}

# Rastreia contadores de linhas para geração de power-ups
var lines_cleared_counter = {
	0: 0,  # Jogador 1
	1: 0   # Jogador 2
}

# Rastreia timers para efeitos temporários
var power_up_timers = {}
var timer_id_counter = 0

# Configura o sistema
func _ready():
	randomize()  # Inicializa o gerador de números aleatórios

# Função chamada quando um jogador limpa linhas
func on_lines_cleared(player_id, num_lines):
	lines_cleared_counter[player_id] += num_lines
	
	# Verifica se o jogador deve receber um power-up
	if lines_cleared_counter[player_id] >= POWER_UP_FREQUENCY:
		lines_cleared_counter[player_id] = 0
		generate_power_up(player_id)

# Gera um power-up aleatório para o jogador
func generate_power_up(player_id):
	# Limita o número máximo de power-ups disponíveis
	if available_power_ups[player_id].size() >= 3:
		return
	
	# Seleciona um power-up com base nas probabilidades
	var power_up = _select_random_power_up()
	
	# Adiciona à lista de disponíveis
	available_power_ups[player_id].append(power_up)
	
	# Notifica que um power-up está disponível
	emit_signal("power_up_available", player_id, power_up)

# Ativa um power-up para o jogador
func activate_power_up(player_id, power_up_index):
	if power_up_index < 0 or power_up_index >= available_power_ups[player_id].size():
		return false
	
	var power_up_type = available_power_ups[player_id][power_up_index]
	
	# Remove da lista de disponíveis
	available_power_ups[player_id].remove_at(power_up_index)
	
	# Determina o alvo (normalmente o oponente)
	var target_player_id = 1 if player_id == 0 else 0
	
	# Para power-ups que afetam o próprio jogador
	if power_up_type == PowerUpType.SPEED_DOWN:
		target_player_id = player_id
	
	# Aplica o efeito
	apply_power_up_effect(player_id, target_player_id, power_up_type)
	
	return true

# Aplica o efeito do power-up
func apply_power_up_effect(player_id, target_player_id, power_up_type):
	# Registra o power-up ativo se tiver duração
	if POWER_UP_DURATION[power_up_type] > 0:
		active_power_ups[target_player_id].append(power_up_type)
		
		# Cria um timer para finalizar o efeito
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = POWER_UP_DURATION[power_up_type]
		timer.timeout.connect(func(): _on_power_up_timeout(player_id, target_player_id, power_up_type, timer))
		add_child(timer)
		timer.start()
		
		var timer_id = timer_id_counter
		timer_id_counter += 1
		power_up_timers[timer_id] = timer
	
	# Notifica sobre a ativação
	emit_signal("power_up_activated", player_id, power_up_type, target_player_id)

# Manipula o fim de um power-up baseado em tempo
func _on_power_up_timeout(player_id, target_player_id, power_up_type, timer):
	# Remove o power-up da lista de ativos
	var index = active_power_ups[target_player_id].find(power_up_type)
	if index != -1:
		active_power_ups[target_player_id].remove_at(index)
	
	# Remove o timer
	for id in power_up_timers:
		if power_up_timers[id] == timer:
			power_up_timers.erase(id)
			break
	
	timer.queue_free()
	
	# Notifica sobre o fim do power-up
	emit_signal("power_up_ended", player_id, power_up_type, target_player_id)

# Verifica se um jogador está sob efeito de um power-up específico
func is_power_up_active(player_id, power_up_type):
	return active_power_ups[player_id].has(power_up_type)

# Retorna todos os power-ups ativos para um jogador
func get_active_power_ups(player_id):
	return active_power_ups[player_id]

# Retorna todos os power-ups disponíveis para um jogador
func get_available_power_ups(player_id):
	return available_power_ups[player_id]

# Seleciona um power-up aleatório com base nas probabilidades
func _select_random_power_up():
	var total_chance = 0.0
	for power_up in POWER_UP_CHANCES:
		total_chance += POWER_UP_CHANCES[power_up]
	
	var roll = randf() * total_chance
	var current_sum = 0.0
	
	for power_up in POWER_UP_CHANCES:
		current_sum += POWER_UP_CHANCES[power_up]
		if roll <= current_sum:
			return power_up
	
	# Fallback para o primeiro power-up (não deveria chegar aqui)
	return PowerUpType.CLEAR_LINE

# Cancela todos os power-ups ativos
func cancel_all_power_ups():
	# Limpa todos os timers
	for timer_id in power_up_timers:
		power_up_timers[timer_id].queue_free()
	
	power_up_timers.clear()
	
	# Limpa os power-ups ativos
	for player_id in active_power_ups:
		for power_up_type in active_power_ups[player_id].duplicate():
			var index = active_power_ups[player_id].find(power_up_type)
			if index != -1:
				emit_signal("power_up_ended", 1 - player_id, power_up_type, player_id)
				active_power_ups[player_id].remove_at(index)
	
	# Limpa os power-ups disponíveis
	for player_id in available_power_ups:
		available_power_ups[player_id].clear()

# Retorna o nome descritivo de um tipo de power-up
func get_power_up_name(power_up_type):
	return POWER_UP_NAMES[power_up_type] 