extends Node2D
class_name NivelMultiBase

@export var escena_humano: PackedScene
@export var escena_cpu: PackedScene
@export var texturas_jugadores: Array[Texture2D] = []
@export var texturas_bombas: Array[Texture2D] = []

var juego_terminado: bool = false
var partida_iniciada: bool = false
var astar_grid: AStarGrid2D

var posiciones_spawn: Dictionary = {
	1: Vector2(-320, -576),
	2: Vector2(1216, -576),
	3: Vector2(-320, 704),
	4: Vector2(1216, 704)
}

@export var playlist_arena: Array[AudioStream] = []
@onready var reproductor_musica: AudioStreamPlayer = $MusicaBatalla

@onready var capa_victoria: CanvasLayer = $CapaVictoria
@onready var texto_ganador: Label = $CapaVictoria/ColorRect/TextoGanador
@onready var contenedor_botones: VBoxContainer = $CapaVictoria/ColorRect/ContenedorBotones
@onready var btn_reiniciar: Button = $CapaVictoria/ColorRect/ContenedorBotones/BtnReiniciar
@onready var btn_menu: Button = $CapaVictoria/ColorRect/ContenedorBotones/BtnMenu

func _ready() -> void:
	if capa_victoria:
		capa_victoria.visible = false
	
	if btn_reiniciar:
		btn_reiniciar.pressed.connect(_on_btn_reiniciar_pressed)
	if btn_menu:
		btn_menu.pressed.connect(volver_al_menu_principal)
		
	if reproductor_musica and not playlist_arena.is_empty():
		reproductor_musica.finished.connect(reproducir_siguiente_aleatoria)
		reproducir_siguiente_aleatoria()
		
	await get_tree().create_timer(1.0).timeout
	
	inicializar_navegacion()
	inyectar_participantes()
	conectar_jugadores()
	
	partida_iniciada = true
	var total_jugadores = get_tree().get_nodes_in_group("jugadores").size()
	print("Árbitro: Partida iniciada correctamente con ", total_jugadores, " jugadores.")

func inicializar_navegacion() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, 15, 13)
	astar_grid.cell_size = Vector2(128, 128)
	astar_grid.offset = Vector2(-512, -768)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	var muros = get_tree().get_nodes_in_group("indestructibles")
	if muros.is_empty():
		muros = get_tree().get_nodes_in_group("indestructible")
	for muro in muros:
		var celda = pos_a_celda(muro.global_position)
		astar_grid.set_point_solid(celda, true)

	var contenedores = get_tree().get_nodes_in_group("contenedores")
	for caja in contenedores:
		var celda = pos_a_celda(caja.global_position)
		astar_grid.set_point_solid(celda, true)

# --- FUNCIONES MATEMÁTICAS DEL MAPA ---
func pos_a_celda(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor((pos.x - astar_grid.offset.x) / astar_grid.cell_size.x)),
		int(floor((pos.y - astar_grid.offset.y) / astar_grid.cell_size.y))
	)

func celda_a_pos(celda: Vector2i) -> Vector2:
	return Vector2(
		(celda.x * astar_grid.cell_size.x) + astar_grid.offset.x + (astar_grid.cell_size.x / 2.0),
		(celda.y * astar_grid.cell_size.y) + astar_grid.offset.y + (astar_grid.cell_size.y / 2.0)
	)
# --------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		volver_al_menu_principal()

func inyectar_participantes() -> void:
	# El diccionario con los colores para cada ID
	var colores_por_id = {
		1: Color.WHITE,          # J1 (Voltio original)
		2: Color(1.0, 0.2, 0.2), # J2 Rojo
		3: Color(0.2, 1.0, 0.2), # J3 Verde
		4: Color(1.0, 0.9, 0.2)  # J4 Amarillo
	}

	for id in GameManager.configuracion_jugadores.keys():
		var tipo_control = GameManager.configuracion_jugadores[id]
		var nuevo_personaje: CharacterBody2D

		if tipo_control == "HUMANO" and escena_humano != null:
			nuevo_personaje = escena_humano.instantiate()
		elif escena_cpu != null:
			nuevo_personaje = escena_cpu.instantiate()
		else:
			continue 

		nuevo_personaje.id_jugador = id
		nuevo_personaje.global_position = posiciones_spawn[id]

		# AQUÍ LE MANDAMOS EL COLOR A LA CPU
		if tipo_control != "HUMANO" and "color_robot" in nuevo_personaje:
			nuevo_personaje.color_robot = colores_por_id[id]

		if texturas_jugadores.size() >= id:
			if "sprite_personalizado" in nuevo_personaje:
				nuevo_personaje.sprite_personalizado = texturas_jugadores[id - 1]

		if texturas_bombas.size() >= id:
			if "textura_bomba" in nuevo_personaje:
				nuevo_personaje.textura_bomba = texturas_bombas[id - 1]

		add_child(nuevo_personaje)

func reproducir_siguiente_aleatoria() -> void:
	if playlist_arena.is_empty():
		return
		
	var nueva_cancion = playlist_arena.pick_random()
	
	if playlist_arena.size() > 1 and reproductor_musica.stream == nueva_cancion:
		reproducir_siguiente_aleatoria()
		return
		
	reproductor_musica.stream = nueva_cancion
	reproductor_musica.play()

func cambiar_a_siguiente_cancion() -> void:
	reproducir_siguiente_aleatoria()

func conectar_jugadores() -> void:
	var jugadores = get_tree().get_nodes_in_group("jugadores")
	for jugador in jugadores:
		if not jugador.tree_exited.is_connected(_on_jugador_eliminado):
			jugador.tree_exited.connect(_on_jugador_eliminado)

func _on_jugador_eliminado() -> void:
	if not partida_iniciada or juego_terminado:
		return
	verificar_estado_partida.call_deferred()

func verificar_estado_partida() -> void:
	if not is_inside_tree() or get_tree() == null:
		return
		
	if not partida_iniciada or juego_terminado:
		return
		
	var jugadores_vivos = get_tree().get_nodes_in_group("jugadores")
	
	if jugadores_vivos.size() == 1:
		var ganador = jugadores_vivos[0]
		var id = ganador.id_jugador if "id_jugador" in ganador else 1
		anunciar_victoria(id)
	elif jugadores_vivos.size() == 0:
		anunciar_empate()

func anunciar_victoria(id: int) -> void:
	juego_terminado = true
	mostrar_pantalla_final("¡GANA EL JUGADOR " + str(id) + "!")

func anunciar_empate() -> void:
	juego_terminado = true
	mostrar_pantalla_final("¡EMPATE!\nNADIE SOBREVIVIÓ")

func mostrar_pantalla_final(mensaje: String) -> void:
	if not capa_victoria:
		return
		
	capa_victoria.visible = true
	texto_ganador.text = mensaje
	
	contenedor_botones.visible = false 
	await get_tree().create_timer(2.5).timeout
	contenedor_botones.visible = true

func _on_btn_reiniciar_pressed() -> void:
	juego_terminado = true
	get_tree().reload_current_scene()

func volver_al_menu_principal() -> void:
	juego_terminado = true 
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")
