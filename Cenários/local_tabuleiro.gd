extends Sprite2D

# A função sign(num) serve para retornar o sinal de um número:
# O sinal pode ser positivo, negativo ou zero.
# É uma excelente maneira de detetar peças inimigas enquanto economizo código.

# TODO:

# Constantes do tabuleiro
const TABULEIRO_SIZE = 8
const LARGURA_CASA = 18
const OFFSET = 3.5 # Ajuste lógico necessário devido à escala
const ROQUE_CONST = 2
const WHITE = "white"
const BLACK = "black"

# Carregamento de texturas
const TEXTURE_HOLDER = preload("res://Cenários/texture_holder.tscn")

# Dicionário de peças
const PECA = {
	"BLACK_BISHOP": -3,
	"BLACK_KING": -6,
	"BLACK_KNIGHT": -2,
	"BLACK_PAWN": -1,
	"BLACK_QUEEN": -5,
	"BLACK_ROOK": -4,
	"WHITE_BISHOP": 3,
	"WHITE_KING": 6,
	"WHITE_KNIGHT": 2,
	"WHITE_PAWN": 1,
	"WHITE_QUEEN": 5,
	"WHITE_ROOK": 4,
	"EMPTY": 0,
	"CAPTURE": 999,
	"MOVABLE": 998,
	"CHEQUE": 997
}

# Mapeamento de peças para texturas
const TEXTURE_MAP = {
	PECA.BLACK_BISHOP: preload("res://Imagens/black_bishop.png"),
	PECA.BLACK_KING: preload("res://Imagens/black_king.png"),
	PECA.BLACK_KNIGHT: preload("res://Imagens/black_knight.png"),
	PECA.BLACK_PAWN: preload("res://Imagens/black_pawn.png"),
	PECA.BLACK_QUEEN: preload("res://Imagens/black_queen.png"),
	PECA.BLACK_ROOK: preload("res://Imagens/black_rook.png"),
	PECA.WHITE_BISHOP: preload("res://Imagens/white_bishop.png"),
	PECA.WHITE_KING: preload("res://Imagens/white_king.png"),
	PECA.WHITE_KNIGHT: preload("res://Imagens/white_knight.png"),
	PECA.WHITE_PAWN: preload("res://Imagens/white_pawn.png"),
	PECA.WHITE_QUEEN: preload("res://Imagens/white_queen.png"),
	PECA.WHITE_ROOK: preload("res://Imagens/white_rook.png"),
	PECA.MOVABLE: preload("res://Imagens/move_dot.png"),
	PECA.CAPTURE: preload("res://Imagens/captura.png"),
	PECA.CHEQUE: preload("res://Imagens/check.png")
}

# Dicionário para deteção de movimentação do rei
var king_moved = {
	"white": false,
	"black": false
}

# Dicionário para deteção de movimentação da torre
var dir_torre_moved = {
	"white": null, # (int)
	"black": null # (int)
}

# Dicionário para armazenar a cache das peças que estão a dar "check" no rei.
var check_pieces = {
	"double_check": false,
	"pecas": { }, # (int)
	"pecas_pos": { } # (Vector2)
}

# Dicionário que controla estados do jogo no lado do servidor
var server_game_status = {
	"game_id": null, # ID do jogo
	"color_play": WHITE, # Cor das peças da jogada atual
	"win": null, # (String) Cache da "cor" que ganhou
	"draw": false, # Determina se o jogo terminou num empate
}

# Dicionário que controla estados locais do jogo
var local_game_status = {
	"color_play": WHITE, # (String) Cor das peças do jogador
	"mouse_cell": null, # (Vector2) Posição do click do jogador
	"select_pos": null, # (Vector2) Posição atual da peça movida
	"promotion": false # Ativa menu de promoção
}

# Referências
@onready var tabuleiro_sprite = $"." # Tabuleiro principal
@onready var pieces = $Pecas # Nó onde as peças são adicionadas
@onready var tabuleiro_pos = tabuleiro_sprite.global_position # Posição real do tabuleiro
@onready var white_pieces = $Promoção/white_pieces
@onready var black_pieces = $Promoção/black_pieces
@onready var brancas = $Brancas
@onready var pretas = $Pretas
@onready var contador_branco = $timer_branco
@onready var contador_preto = $timer_preto
@onready var timer_texto = $Contagem
@onready var vitoria = $Vitoria
@onready var restart = $"Restart" as Button
@onready var menu = $"Menu" as Button
@onready var pisca_button = $pisca_board as Button

@onready var anim_vitoria = $Vitoria/anim_vitoria

@onready var start_board = preload("res://Cenários/tabuleiro.tscn") as PackedScene
@onready var menu_scene = load("res://Cenários/main.tscn") as PackedScene

# Lista que armazena as posições das peças no tabuleiro (num momento presente)
var tabuleiro = [
	[PECA.BLACK_ROOK, PECA.BLACK_KNIGHT, PECA.BLACK_BISHOP, PECA.BLACK_QUEEN, PECA.BLACK_KING, PECA.BLACK_BISHOP, PECA.BLACK_KNIGHT, PECA.BLACK_ROOK],
	[], [], [], [], [], [],
	[PECA.WHITE_ROOK, PECA.WHITE_KNIGHT, PECA.WHITE_BISHOP, PECA.WHITE_QUEEN, PECA.WHITE_KING, PECA.WHITE_BISHOP, PECA.WHITE_KNIGHT, PECA.WHITE_ROOK]
]

# Cache do tabuleiro
var tabuleiro_original = []

# Cache (valores temporários) da interação do jogador
var peca_selecionada = null
var posicao_selecionada = null
var mouse_pos = null
var adjusted_x = null
var adjusted_y = null
var snapped_x = null
var snapped_y = null

var minutos : int
var segundos : int

# 0 = nenhum marcador, 1 = móvel, 2 = capturar
var highlight = []

var direcoes_rei = [
Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
Vector2(1,1), Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1)
]

var direcoes_diagonais = [Vector2(1, 1), Vector2(1, -1), 
Vector2(-1, 1), Vector2(-1, -1)]

var direcoes_ortogonais = [Vector2(1, 0), Vector2(-1, 0),
 Vector2(0, 1), Vector2(0, -1)]

var direcoes_cavalo = [Vector2(2, 1), Vector2(2, -1), Vector2(-2, 1),
 Vector2(-2, -1), Vector2(1, 2), Vector2(-1, 2),
 Vector2(1, -2), Vector2(-1, -2)]

func tamanho_dinamico() -> void:
	var tamanho_ecra = get_viewport().size
	var base_res = Vector2(320, 180)
	
	var x = tamanho_ecra.x / base_res.x
	var y = tamanho_ecra.y / base_res.y
	var fator = min(x, y)

	tabuleiro_sprite.scale = Vector2(fator, fator)

# Inicializa o tabuleiro e exibe as peças
func _ready() -> void:
	tamanho_dinamico()
	
	$Promoção.visible = false
	white_pieces.visible = false
	black_pieces.visible = false
	pretas.visible = false
	vitoria.visible = false
	vitoria["theme_override_colors/font_color"] = Color.WHITE
	
	contador_branco.start()
	contador_preto.paused = true
	
	restart.button_down.connect(on_restart_pressed)
	menu.button_down.connect(on_menu_pressed)
	
	# Preenche as linhas corretamente
	for i in range(TABULEIRO_SIZE):
		tabuleiro[1].append(PECA.BLACK_PAWN)  # Peões pretos
		for n in range (2,6):  
			tabuleiro[n].append(PECA.EMPTY)   # Casas vazias
		tabuleiro[6].append(PECA.WHITE_PAWN)  # Peões brancos
	call_deferred("_ligar_botoes_promocao")
	
	highlight.clear()
	for y in range(TABULEIRO_SIZE):
		var linha = []
		for x in range(TABULEIRO_SIZE):
			linha.append(0)
		highlight.append(linha)
	display_tabuleiro()

# Função para updates em cada frame
func _process(_delta):
	# Centralizar dinâmicamente o tabuleiro
	var posx = get_viewport().size.x - tabuleiro_sprite.scale.x
	var posy = get_viewport().size.y - tabuleiro_sprite.scale.y
	tabuleiro_sprite.position = Vector2(posx, posy) / 2
	
	if server_game_status.draw:
		display_tabuleiro()
		return
	
	var brancas_min = int(contador_branco.time_left / 60)
	var brancas_seg = int(contador_branco.time_left) % 60
	
	var pretas_min = int(contador_preto.time_left / 60)
	var pretas_seg = int(contador_preto.time_left) % 60
	
	if not server_game_status.win:
		if server_game_status.color_play == WHITE:
			minutos = brancas_min
			segundos = brancas_seg
		else:
			minutos = pretas_min
			segundos = pretas_seg
	
	if brancas_min == 0 and brancas_seg == 0:
		if pretas_min == 0 and pretas_seg == 0:
			server_game_status.draw = true
			
	if brancas_min == 0 and brancas_seg == 0:
		trocar_turno()
		if server_game_status.color_play == WHITE:
			server_game_status.win = true
			trocar_turno(true)
	elif pretas_min == 0 and pretas_seg == 0:
		trocar_turno()
		if server_game_status.color_play == BLACK:
			server_game_status.win = true
			trocar_turno(true)
	
	if server_game_status.draw:
		limpar_dots()
		trocar_turno()
	
	timer_texto.text = "Tempo: " + str(minutos) + "m" + str(segundos) + "s"
	
	limpar_cheque()
	var server_cor = 1 if server_game_status.color_play == WHITE else -1
	var rei_pos = search_peca(PECA.WHITE_KING * server_cor)
	if rei_pos != null:
		cell_on_check(rei_pos, true)
	
	if local_game_status.promotion and not $Promoção.visible \
	and peca_selecionada:
		$Promoção.visible = true
		if sign(peca_selecionada) > 0:
			white_pieces.visible = true
			black_pieces.visible = false
		else:
			white_pieces.visible = false
			black_pieces.visible = true
	# Update do tabuleiro
	display_tabuleiro()

func on_restart_pressed() -> void:
	get_tree().change_scene_to_packed(start_board)
	
func on_menu_pressed() -> void:
	get_tree().change_scene_to_packed(menu_scene)

func _on_pisca_board_toggled(toggled_on: bool) -> void:
	if toggled_on:
		tabuleiro_sprite.self_modulate = Color("ee000088")
	else:
		tabuleiro_sprite.self_modulate = Color("#ffffff")

# Limita um valor para não crashar o jogo
func dentro_limites(valor):
	return valor >= 0 and valor < TABULEIRO_SIZE

func _ligar_botoes_promocao():
	if white_pieces != null and black_pieces != null: 
		white_pieces.get_node("Rainha").pressed.connect(func(): promover_para(PECA.WHITE_QUEEN))
		white_pieces.get_node("Torre").pressed.connect(func(): promover_para(PECA.WHITE_ROOK))
		white_pieces.get_node("Bispo").pressed.connect(func(): promover_para(PECA.WHITE_BISHOP))
		white_pieces.get_node("Cavalo").pressed.connect(func(): promover_para(PECA.WHITE_KNIGHT))

		black_pieces.get_node("Rainha").pressed.connect(func(): promover_para(PECA.BLACK_QUEEN))
		black_pieces.get_node("Torre").pressed.connect(func(): promover_para(PECA.BLACK_ROOK))
		black_pieces.get_node("Bispo").pressed.connect(func(): promover_para(PECA.BLACK_BISHOP))
		black_pieces.get_node("Cavalo").pressed.connect(func(): promover_para(PECA.BLACK_KNIGHT))


# Movimentos de peão
func peao_moves(cell_x, cell_y, select_pos):
	var peao = tabuleiro[select_pos.y][select_pos.x]
	var direcao = -sign(peao)
	var linha_inicial = 6 if peao == PECA.WHITE_PAWN else 1
	var valid_dir = cell_y < select_pos.y if peao == PECA.WHITE_PAWN else \
	cell_y > select_pos.y
	var dist_y = abs(cell_y - select_pos.y)
	var dist_x = abs(cell_x - select_pos.x)
	
	var destino = tabuleiro[cell_y][cell_x]
	var mid = tabuleiro[select_pos.y + direcao][cell_x]
	
	if dist_y > 2:
		return false
		
	# Impede capturar peça da mesma cor
	if sign(tabuleiro[cell_y][cell_x]) == sign(peao):
		return false
	
	# Avanço ascendente
	if valid_dir:
		if dist_x == 0:
			# Movimento duplo
			if select_pos.y == linha_inicial \
			and dist_y == 2:
				if (mid == PECA.EMPTY or mid == PECA.MOVABLE) and\
				(destino == PECA.EMPTY or destino == PECA.MOVABLE):
					return true
			elif tabuleiro[cell_y][cell_x] == PECA.EMPTY \
			and dist_y == 1:
				return true
		# Captura diagonal
		elif dist_x == 1 and dist_y == 1:
			if tabuleiro[cell_y][cell_x] != PECA.EMPTY \
			and tabuleiro[cell_y][cell_x] != PECA.MOVABLE\
			and tabuleiro[cell_y][cell_x] != PECA.CAPTURE:
				return true

func cavalo_moves(cell_x, cell_y, select_pos):
	var cavalo = tabuleiro[select_pos.y][select_pos.x]
	var destino = Vector2(cell_x, cell_y)
	
	# Garantir que o destino está dentro dos limites do tabuleiro
	if not dentro_limites(cell_x) or not dentro_limites(cell_y):
		return false

	for dir in direcoes_cavalo:
		var pos = select_pos + dir
		if pos == destino:
			# Não pode capturar peça da mesma cor
			if sign(tabuleiro[cell_y][cell_x]) == sign(cavalo):
				return false
			return true

	return false

# Movimentos de bispo
func bispo_moves(cell_x, cell_y, select_pos):
	var bispo = tabuleiro[select_pos.y][select_pos.x]
	var cell = Vector2(cell_x, cell_y)
	
	# Garantir que não ultrapassamos os limites do tabuleiro
	if not dentro_limites(cell_x) or not dentro_limites(cell_y):
		return false
	
	# Só queremos movimentos diagonais
	if abs(cell_x - select_pos.x) != abs(cell_y - select_pos.y):
		return false
		
	# Impossibilita a ação de comer peças da mesma cor
	if sign(tabuleiro[cell.y][cell.x]) == sign(bispo):
		return false
	
	# Calcula a direção do movimento
	var direcao_x = sign(cell_x - select_pos.x)  # -1 = esquerda, 1 = direita
	var direcao_y = sign(cell_y - select_pos.y)  # -1 = cima, 1 = baixo
	var n = select_pos
	
	while n != cell:
		n += Vector2(direcao_x, direcao_y) # Avanço diagonal
		
		# Se encontramos uma peça antes do destino, movimento inválido
		if n != cell and tabuleiro[n.y][n.x] != PECA.EMPTY:
			return false
	
	return true

# Movimento de torre
func torre_moves(cell_x, cell_y, select_pos):
	var torre = tabuleiro[select_pos.y][select_pos.x]
	var cell = Vector2(cell_x, cell_y)
	
	# Garantir que não ultrapassamos os limites do tabuleiro
	if not dentro_limites(cell_x) or not dentro_limites(cell_y):
		return false
	
	# Só queremos movimentos verticais ou horizontais
	if cell_x != select_pos.x and cell_y != select_pos.y:
		return false
		
	# Impossibilita a ação de comer peças da mesma cor
	if sign(tabuleiro[cell.y][cell.x]) == sign(torre):
		return false
		
	
	# Calcula a direção do movimento
	var direcao_x = sign(cell_x - select_pos.x)  # -1 = esquerda, 1 = direita
	var direcao_y = sign(cell_y - select_pos.y)  # -1 = cima, 1 = baixo
	var n = select_pos
	
	# No momento em que a torre mexe, perde o direito ao roque nessa direção
	if torre == PECA.WHITE_ROOK:
		dir_torre_moved.white = direcao_x
	elif torre == PECA.BLACK_ROOK:
		dir_torre_moved.black = direcao_x
	
	while n != cell:
		n += Vector2(direcao_x, direcao_y) # Avanço vertical/horizontal
		
		# Se encontramos uma peça antes do destino, movimento inválido
		if n != cell and tabuleiro[n.y][n.x] != PECA.EMPTY:
			return false
	
	return true

# Movimento de rainha
func rainha_moves(cell_x, cell_y, select_pos):
	var rainha = tabuleiro[select_pos.y][select_pos.x]
	var cell = Vector2(cell_x, cell_y)
	
	# Garantir que não ultrapassamos os limites do tabuleiro
	if not dentro_limites(cell_x) or not dentro_limites(cell_y):
		return false
	
	# Só queremos movimentos verticais, horizontais e diagonais
	if cell_x != select_pos.x and cell_y != select_pos.y: # Não é vertical ou horizontal
		if abs(cell_x - select_pos.x) != abs(cell_y - select_pos.y): # Nem diagonal
			return false
		
	# Impossibilita a ação de comer peças da mesma cor
	if sign(tabuleiro[cell.y][cell.x]) == sign(rainha):
		return false
	
	# Calcula a direção do movimento
	var direcao_x = sign(cell_x - select_pos.x)  # -1 = esquerda, 1 = direita
	var direcao_y = sign(cell_y - select_pos.y)  # -1 = cima, 1 = baixo
	var n = select_pos
	
	while n != cell:
		n += Vector2(direcao_x, direcao_y) # Avanço vertical/horizontal ou diagonal
		
		# Se encontramos uma peça antes do destino, movimento inválido
		if n != cell and tabuleiro[n.y][n.x] != PECA.EMPTY:
			return false
	
	return true

# Movimento especial de roque
func roque_moves(cell_x, cell_y, select_pos, rei):
	var direcao_x = sign(cell_x - select_pos.x)  # -1 = esquerda, 1 = direita
	var cor_rei = sign(rei)  # Branco = 1, Preto = -1
	
	# Garantir que não ultrapassamos os limites do tabuleiro
	if not dentro_limites(cell_x) or not dentro_limites(cell_y):
		return false
	
	# Só queremos movimentos horizontais
	if cell_y != select_pos.y:
		return false
	
	# O rei já se moveu? Então não pode fazer roque.
	if (cor_rei > 0 and king_moved.white) or (cor_rei < 0 and king_moved.black):
		return false
	
	# A torre já se moveu? Então não pode fazer roque nessa direção.
	if (cor_rei > 0 and dir_torre_moved.white == direcao_x) or (cor_rei < 0 and dir_torre_moved.black == direcao_x):
		return false
	
	var rook_x = 0 if direcao_x < 0 else 7  # Torre no lado correspondente
	
	# Verificar se há peças entre o rei e a torre
	for x in range(min(select_pos.x, rook_x) + 1, max(select_pos.x, rook_x)):
		if tabuleiro[cell_y][x] != PECA.EMPTY or processing_rei(rei, Vector2(x, cell_y), select_pos):
			return false  # Não pode fazer roque se houver peças no meio
	
	# Verificar se a torre ainda está na posição inicial
	if tabuleiro[cell_y][rook_x] != PECA.WHITE_ROOK * cor_rei:
		return false  # A torre já se moveu ou foi capturada
	
	# Executar o Roque
	tabuleiro[select_pos.y][select_pos.x] = PECA.EMPTY  # Apagar o rei da posição inicial
	tabuleiro[select_pos.y][cell_x] = rei
	tabuleiro[select_pos.y][cell_x - direcao_x] = PECA.WHITE_ROOK * cor_rei
	
	# Remover a torre da posição original
	tabuleiro[cell_y][rook_x] = PECA.EMPTY
	
	return true

func verifica_check(select_pos, direcoes, pecas_validas, is_cavalo=false):
	var rei = tabuleiro[select_pos.y][select_pos.x]

	if is_cavalo:
		for dir in direcoes:
			var n = select_pos + dir
			if dentro_limites(n.x) and dentro_limites(n.y):
				var cur_loop_piece = tabuleiro[n.y][n.x]
				if cur_loop_piece in pecas_validas and sign(cur_loop_piece) != sign(rei):
					check_pieces.pecas_pos[check_pieces.pecas.size()] = n
					check_pieces.pecas[check_pieces.pecas.size()] = cur_loop_piece
					return true
		return false

	for dir in direcoes:
		var n = select_pos
		while true:
			n += dir
			if not dentro_limites(n.x) or not dentro_limites(n.y):
				break
			var cur_loop_piece = tabuleiro[n.y][n.x]
			if cur_loop_piece == PECA.EMPTY:
				continue
			if cur_loop_piece in pecas_validas and sign(cur_loop_piece) != sign(rei):
					check_pieces.pecas_pos[check_pieces.pecas.size()] = n
					check_pieces.pecas[check_pieces.pecas.size()] = cur_loop_piece
					return true
			break
	return false

func verifica_peao_check(select_pos):
	var cor_rei = 1 if server_game_status.color_play == WHITE else -1
	var dir_peao = -cor_rei
	var pos_esq = select_pos + Vector2(-1, dir_peao)
	var pos_dir = select_pos + Vector2(1, dir_peao)
	
	var peao_inimigo = PECA.WHITE_PAWN * dir_peao
	
	for pos in [pos_esq, pos_dir]:
		if dentro_limites(pos.x) and dentro_limites(pos.y):
			if tabuleiro[pos.y][pos.x] == peao_inimigo:
				check_pieces.pecas_pos[check_pieces.pecas.size()] = pos
				check_pieces.pecas[check_pieces.pecas.size()] = peao_inimigo
				return true
	return false

# Validação de movimentos legais do rei, ou seja, se existe cheque numa posição
func cell_on_check(select_pos, desenhar=false):
	var peca = tabuleiro[select_pos.y][select_pos.x]
	var cor_rei = sign(peca)
	
	# Garantir que a cache esteja limpa antes de verificar
	check_pieces.pecas.clear()
	check_pieces.double_check = false
	
	# Categorização das peças
	var pecas_diagonal = [PECA.WHITE_QUEEN * sign(-cor_rei), PECA.WHITE_BISHOP * sign(-cor_rei)]
	var pecas_ortogonais = [PECA.WHITE_QUEEN * sign(-cor_rei), PECA.WHITE_ROOK * sign(-cor_rei)]
	var pecas_cavalo = [PECA.WHITE_KNIGHT * sign(-cor_rei)]
	
	var check_diagonal = verifica_check(select_pos, direcoes_diagonais, pecas_diagonal)
	var check_ortogonal = verifica_check(select_pos, direcoes_ortogonais, pecas_ortogonais)
	var check_cavalo = verifica_check(select_pos, direcoes_cavalo, pecas_cavalo, true)
	var check_peao = verifica_peao_check(select_pos)
	
	var total_checks = int(check_diagonal) + int(check_ortogonal) + int(check_cavalo) + int(check_peao)
	
	check_pieces.double_check = total_checks > 1
	
	if desenhar and total_checks > 0:
			desenhar_check()
			
	return total_checks > 0
	
# Simulação do movimento do rei na casa clicada
func processing_rei(rei, cell, select_pos):
	# Cache de peças e posições
	var old_pos = select_pos
	var old_peca = tabuleiro[cell.y][cell.x]
	
	# Simulação de movimento até casa clicada
	tabuleiro[select_pos.y][select_pos.x] = PECA.EMPTY
	tabuleiro[cell.y][cell.x] = rei
	
	var on_check = cell_on_check(cell)
	
	# Fim da simulação (Reposição das peças)
	tabuleiro[cell.y][cell.x] = old_peca
	tabuleiro[old_pos.y][old_pos.x] = rei
	
	return on_check
	

# Procura peças que possam bloquear o check
func processing_check(king_piece, local_sign):
	var can_block_check = false
	var can_eat_piece = false
		
	for check_pieces_pos in check_pieces.pecas_pos.values():
		for y in range(TABULEIRO_SIZE):
			for x in range(TABULEIRO_SIZE):
				var peca = tabuleiro[y][x]
				if sign(peca) == local_sign and peca != king_piece:
					for dest_y in range(TABULEIRO_SIZE):
						for dest_x in range(TABULEIRO_SIZE):
							if gerir_moves(check_pieces_pos.x, check_pieces_pos.y, Vector2(x, y)):  # Parece correta, mas depende da assinatura
								can_block_check = true
								break
						if can_block_check:
							break
				if can_block_check:
					break
			if can_block_check:
				break

	for check_pieces_pos in check_pieces.pecas_pos.values():
		for y in range(TABULEIRO_SIZE):
			for x in range(TABULEIRO_SIZE):
				var peca = tabuleiro[y][x]
				if sign(peca) == local_sign and peca != king_piece:
					# Tentar mover da peça (x,y) até à posição atacante
					if gerir_moves(check_pieces_pos.x, check_pieces_pos.y, Vector2(x, y)):  # Parece correta, mas depende da assinatura
						can_eat_piece = true
						break
			if can_eat_piece:
				break
		if can_eat_piece:
			break

	return can_block_check or can_eat_piece

# Verifica se há checkmate ou stalemate para o jogador atual
func mate_or_stale(local_sign):
	var king_piece = PECA.WHITE_KING * local_sign
	var local_king = search_peca(king_piece)
	if local_king == null:
		return false

	var can_move = false

	# Verificar se qualquer peça da cor atual tem jogadas legais
	for y in range(TABULEIRO_SIZE):
		for x in range(TABULEIRO_SIZE):
			if sign(tabuleiro[y][x]) != local_sign:
				continue
			for dest_y in range(TABULEIRO_SIZE):
				for dest_x in range(TABULEIRO_SIZE):
					if gerir_moves(dest_x, dest_y, Vector2(x, y)):
						can_move = true
						break
				if can_move:
					break
			if can_move:
				break
		if can_move:
			break
	
	if not can_move:
		if cell_on_check(local_king) and not processing_check(king_piece, local_sign):
			server_game_status.win = true
			return true
		else:
			server_game_status.draw = true
			return true
	return false

# Percorrer o tabuleiro até encontrar a posição da peça desejada
func search_peca(piece):
	var lista_pos = null
	for y in range(TABULEIRO_SIZE):
		for x in range(TABULEIRO_SIZE):
			if tabuleiro[y][x] == piece:
				lista_pos = Vector2(x,y)
				return lista_pos
	return lista_pos

# Desenha o cheque no tabuleiro de highlights
func desenhar_check():
	var cor = 1 if server_game_status.color_play == WHITE else -1
	var cur_rei = PECA.WHITE_KING * cor
	var pos_rei = search_peca(cur_rei)
	
	if pos_rei == null:
		return

	highlight[pos_rei.y][pos_rei.x] = PECA.CHEQUE

# Movimento de rei
func rei_moves(cell_x, cell_y, select_pos):
	var rei = tabuleiro[select_pos.y][select_pos.x]
	var enemy_rei = search_peca(-rei)
	var cell = Vector2(cell_x, cell_y)
	
	# Garantir que não ultrapassamos os limites do tabuleiro
	if not dentro_limites(cell_x) or not dentro_limites(cell_y):
		return false
		
	if enemy_rei == null or cell == null:
		return false
		
	# Limitar movimentos a uma casa em cada direção
	if abs(cell_x - select_pos.x) > 1 or abs(cell_y - select_pos.y) > 1:
		return roque_moves(cell_x, cell_y, select_pos, rei)
	
	# No momento em que o rei mexe, perde o direito ao roque
	if tabuleiro[select_pos.y][select_pos.x] == PECA.WHITE_KING:
		king_moved.white = true
	elif tabuleiro[select_pos.y][select_pos.x] == PECA.BLACK_KING:
		king_moved.black = true
		
	if check_pieces.double_check:
		return false
	
	# Impossibilita a ação de comer peças da mesma cor
	if sign(tabuleiro[cell.y][cell.x]) == sign(rei):
		return false
	
	# Reis adjacentes devem ter 1 casa de intervalo entre sí
	if enemy_rei.distance_to(cell) < 2:
		return false
	
	# Verificar se a casa de destino do rei está sob ataque
	if processing_rei(rei, cell, select_pos):
		return false
		
	return true

# Deteção de cravadas
func is_cravada(select_pos, cell):
	var cur_peca = tabuleiro[select_pos.y][select_pos.x]
	var cell_peca = tabuleiro[cell.y][cell.x]
	var rei = PECA.WHITE_KING * sign(cur_peca)
	var pos_rei = search_peca(rei)
	
	tabuleiro[select_pos.y][select_pos.x] = PECA.EMPTY
	tabuleiro[cell.y][cell.x] = cur_peca
	if cell_on_check(pos_rei):
		tabuleiro[cell.y][cell.x] = cell_peca
		tabuleiro[select_pos.y][select_pos.x] = cur_peca
		return true
	tabuleiro[cell.y][cell.x] = cell_peca
	tabuleiro[select_pos.y][select_pos.x] = cur_peca	
	return false

# Esta função atribui a movimentação de cada peça
func gerir_moves(cell_x, cell_y, select_pos):
	var cell = Vector2(cell_x, cell_y)
	var cur_sign = sign(tabuleiro[select_pos.y][select_pos.x])
	
	local_game_status.promotion = false
	
	if is_cravada(select_pos, cell):
		return false
	
	if check_pieces.double_check and tabuleiro[select_pos.y][select_pos.x] != PECA.WHITE_KING and tabuleiro[select_pos.y][select_pos.x] != PECA.BLACK_KING:
		return false
		
	if tabuleiro[cell.y][cell.x] == PECA.WHITE_KING * -cur_sign:
		return false
		
	match tabuleiro[select_pos.y][select_pos.x]:
		PECA.WHITE_PAWN, PECA.BLACK_PAWN:
			return peao_moves(cell.x, cell.y, select_pos)
		PECA.WHITE_KNIGHT, PECA.BLACK_KNIGHT:
			return cavalo_moves(cell.x, cell.y, select_pos)
		PECA.WHITE_BISHOP, PECA.BLACK_BISHOP:
			return bispo_moves(cell.x, cell.y, select_pos)
		PECA.WHITE_ROOK, PECA.BLACK_ROOK:
			return torre_moves(cell.x, cell.y, select_pos)
		PECA.WHITE_QUEEN, PECA.BLACK_QUEEN:
			return rainha_moves(cell.x, cell.y, select_pos)
		PECA.WHITE_KING, PECA.BLACK_KING:
			var rei = tabuleiro[select_pos.y][select_pos.x]
			var valid_cell = not processing_rei(rei, cell, select_pos)
			
			# O rei não pode ir/ficar em casas que estão atacadas
			return valid_cell and rei_moves(cell.x, cell.y, select_pos)
		_:
			return false

# Back-end do menu de promoção
func promover_para(nova_peca):
	if local_game_status.mouse_cell == null or local_game_status.select_pos == null:
		return
	
	var pos = local_game_status.mouse_cell
	tabuleiro[local_game_status.select_pos.y][local_game_status.select_pos.x] = PECA.EMPTY
	tabuleiro[pos.y][pos.x] = nova_peca
	
	local_game_status.promotion = false
	$Promoção.visible = false
	white_pieces.visible = false
	black_pieces.visible = false
	
	peca_selecionada = null
	local_game_status.mouse_cell = null
	trocar_turno()
	display_tabuleiro()

func limpar_cheque():
	for y in range(TABULEIRO_SIZE):
		for x in range(TABULEIRO_SIZE):
			if highlight[y][x] == PECA.CHEQUE:
				highlight[y][x] = PECA.EMPTY

func limpar_dots():
	for y in range(TABULEIRO_SIZE):
		for x in range(TABULEIRO_SIZE):
			if highlight[y][x] == PECA.MOVABLE \
			or highlight[y][x] == PECA.CAPTURE or highlight[y][x] == PECA.CHEQUE:
				highlight[y][x] = PECA.EMPTY

func mostrar_movimentos_legais(select_pos: Vector2):
	
	var peca = tabuleiro[select_pos.y][select_pos.x]
	
	for y in range(TABULEIRO_SIZE):
		for x in range(TABULEIRO_SIZE):
			var valido = gerir_moves(x, y, select_pos)
			if valido:
				if tabuleiro[y][x] == PECA.EMPTY:
					highlight[y][x] = PECA.MOVABLE
				elif sign(tabuleiro[y][x]) != \
				sign(peca):
					highlight[y][x] = PECA.CAPTURE
	display_tabuleiro()

func trocar_turno(win=false):
	var cor = null
	
	if server_game_status.win:
		contador_branco.paused = true
		contador_preto.paused = true
		vitoria.visible = true
		
		anim_vitoria.play("piscar_vitoria")
		
		brancas.visible = !brancas.visible
		pretas.visible = !pretas.visible
		
		cor = Color.WHITE \
		if brancas.visible else Color.BLACK
		
		server_game_status.win = WHITE \
		if brancas.visible else BLACK

		vitoria["theme_override_colors/font_color"] = cor
		timer_texto["theme_override_colors/font_color"] = cor
		return
		
	elif server_game_status.draw:
		contador_branco.paused = true
		contador_preto.paused = true
		vitoria.visible = true
		
		brancas.visible = !brancas.visible
		pretas.visible = !pretas.visible
		
		cor = Color.WHITE \
		if brancas.visible else Color.BLACK
		
		server_game_status.win = WHITE \
		if brancas.visible else BLACK
		
		vitoria.text = "EMPATE"
		vitoria["theme_override_colors/font_color"] = Color.YELLOW
		timer_texto["theme_override_colors/font_color"] = Color.YELLOW
		return
	
	if not win:
		server_game_status.color_play = BLACK if server_game_status.color_play == WHITE else WHITE
		cor = Color.WHITE \
		if server_game_status.color_play == WHITE else Color.BLACK
		
		contador_branco.paused = !contador_branco.paused
		contador_preto.paused = !contador_branco.paused
		
		brancas.visible = !brancas.visible
		pretas.visible = !pretas.visible
		timer_texto["theme_override_colors/font_color"] = cor

# Esta função é o coração do código, faz a gestão dos inputs do jogador
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out() or server_game_status.win:
				return
				
			limpar_dots()
			
			# Calcular a célula clicada
			mouse_pos = (get_global_mouse_position() - tabuleiro_sprite.global_position) / tabuleiro_sprite.scale
			adjusted_x = mouse_pos.x + (OFFSET + 0.5) * LARGURA_CASA
			adjusted_y = mouse_pos.y + (OFFSET + 0.5) * LARGURA_CASA
			snapped_x = clamp(int(adjusted_x / LARGURA_CASA), 0, TABULEIRO_SIZE - 1)
			snapped_y = clamp(int(adjusted_y / LARGURA_CASA), 0, TABULEIRO_SIZE - 1)
	
			if not (dentro_limites(snapped_x) and dentro_limites(snapped_y)):
				return
	
			var clicked_piece = tabuleiro[snapped_y][snapped_x]
			var clicked_sign = sign(clicked_piece)
			var expected_sign = 1 if server_game_status.color_play == "white" else -1
	
			# Se uma peça já está selecionada, tentar mover
			if peca_selecionada != null and posicao_selecionada != null:
				var local_sign = sign(peca_selecionada)
				
				if server_game_status.draw:
					return
				
				if mate_or_stale(local_sign) or server_game_status.win:
					trocar_turno()
					return
					
				if gerir_moves(snapped_x, snapped_y, posicao_selecionada):
					if local_game_status.promotion:
						return
	
					tabuleiro[snapped_y][snapped_x] = peca_selecionada
					tabuleiro[posicao_selecionada.y][posicao_selecionada.x] = PECA.EMPTY
					
					if peca_selecionada == PECA.WHITE_PAWN and snapped_y == 0 \
					or peca_selecionada == PECA.BLACK_PAWN and snapped_y == TABULEIRO_SIZE - 1:
						local_game_status.promotion = true
						local_game_status.select_pos = posicao_selecionada
						local_game_status.mouse_cell = Vector2(snapped_x, snapped_y)
						return
						
					if not server_game_status.win:
						trocar_turno()
					
					if mate_or_stale(-local_sign):
						trocar_turno()
						return
	
					display_tabuleiro()
	
				# Após tentar mover (sucesso ou não), limpar seleção
				peca_selecionada = null
				posicao_selecionada = null
	
			# Se nenhuma peça estiver selecionada, e clicaste numa peça da tua cor
			elif clicked_piece != PECA.EMPTY and clicked_sign == expected_sign:
				peca_selecionada = clicked_piece
				posicao_selecionada = Vector2(snapped_x, snapped_y)
				mostrar_movimentos_legais(posicao_selecionada)

# Verifica se o rato está fora dos limites do tabuleiro
func is_mouse_out():
	mouse_pos = (get_global_mouse_position() - tabuleiro_sprite.global_position) / tabuleiro_sprite.scale
	
	# Limites horizontais
	if mouse_pos.x < (-OFFSET - 0.5) * LARGURA_CASA or mouse_pos.x > (OFFSET + 0.5) * LARGURA_CASA:
		return true
	# Limites verticais
	if mouse_pos.y < (-OFFSET - 0.5) * LARGURA_CASA or mouse_pos.y > (OFFSET + 0.5) * LARGURA_CASA:
		return true
	
	return false

# Exibe o tabuleiro e posiciona as peças
func display_tabuleiro():
	# Limpar
	for child in pieces.get_children():
		child.queue_free()
		
	for y in range(TABULEIRO_SIZE):
		for x in range(TABULEIRO_SIZE):
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.global_position = tabuleiro_sprite.global_position \
				- Vector2(tabuleiro_sprite.scale.x * LARGURA_CASA * OFFSET, tabuleiro_sprite.scale.y * LARGURA_CASA * OFFSET) \
				+ Vector2(x * LARGURA_CASA * tabuleiro_sprite.scale.x, y * LARGURA_CASA * tabuleiro_sprite.scale.y)
			holder.texture = TEXTURE_MAP.get(tabuleiro[y][x], null)
	
	for y in range(TABULEIRO_SIZE):
		for x in range(TABULEIRO_SIZE):
			match highlight[y][x]:
				PECA.MOVABLE:
					# moves
					var dot = TEXTURE_HOLDER.instantiate()
					pieces.add_child(dot)
					dot.global_position = tabuleiro_sprite.global_position \
				- Vector2(tabuleiro_sprite.scale.x * LARGURA_CASA * OFFSET, tabuleiro_sprite.scale.y * LARGURA_CASA * OFFSET) \
				+ Vector2(x * LARGURA_CASA * tabuleiro_sprite.scale.x, y * LARGURA_CASA * tabuleiro_sprite.scale.y)
					dot.texture = TEXTURE_MAP[PECA.MOVABLE]
				PECA.CAPTURE:
					# captura
					var cap = TEXTURE_HOLDER.instantiate()
					pieces.add_child(cap)
					cap.global_position = tabuleiro_sprite.global_position \
				- Vector2(tabuleiro_sprite.scale.x * LARGURA_CASA * OFFSET, tabuleiro_sprite.scale.y * LARGURA_CASA * OFFSET) \
				+ Vector2(x * LARGURA_CASA * tabuleiro_sprite.scale.x, y * LARGURA_CASA * tabuleiro_sprite.scale.y)
					cap.texture = TEXTURE_MAP[PECA.CAPTURE]
				PECA.CHEQUE:
					var cheque = TEXTURE_HOLDER.instantiate()
					pieces.add_child(cheque)
					cheque.global_position = tabuleiro_sprite.global_position \
						- Vector2(tabuleiro_sprite.scale.x * LARGURA_CASA * OFFSET, tabuleiro_sprite.scale.y * LARGURA_CASA * OFFSET) \
						+ Vector2(x * LARGURA_CASA * tabuleiro_sprite.scale.x, y * LARGURA_CASA * tabuleiro_sprite.scale.y)
					cheque.texture = TEXTURE_MAP[PECA.CHEQUE]
				_:
					pass
