extends Node2D
class_name NivelMultiBase

# --- ESTADO DE LA PARTIDA ---
var juego_terminado: bool = false
var partida_iniciada: bool = false

# --- SISTEMA DE PLAYLIST (NUEVO) ---
@export var playlist_arena: Array[AudioStream] = []
@onready var reproductor_musica: AudioStreamPlayer = $MusicaBatalla

# --- REFERENCIAS A LA UI ---
@onready var capa_victoria: CanvasLayer = $CapaVictoria
@onready var texto_ganador: Label = $CapaVictoria/ColorRect/TextoGanador
@onready var contenedor_botones: VBoxContainer = $CapaVictoria/ColorRect/ContenedorBotones
@onready var btn_reiniciar: Button = $CapaVictoria/ColorRect/ContenedorBotones/BtnReiniciar
@onready var btn_menu: Button = $CapaVictoria/ColorRect/ContenedorBotones/BtnMenu

func _ready() -> void:
	# 1. Aseguramos que la UI de victoria esté oculta al iniciar
	if capa_victoria:
		capa_victoria.visible = false
	
	# 2. Conectamos los botones
	if btn_reiniciar:
		btn_reiniciar.pressed.connect(_on_btn_reiniciar_pressed)
	if btn_menu:
		btn_menu.pressed.connect(volver_al_menu_principal)
		
	# 3. CONFIGURACIÓN DE MÚSICA (NUEVO)
	# Verificamos que el nodo exista y que hayas arrastrado canciones al Inspector
	if reproductor_musica and not playlist_arena.is_empty():
		# Conectamos la señal para que al terminar una canción, salte a otra
		reproductor_musica.finished.connect(reproducir_siguiente_aleatoria)
		# Iniciamos la primera canción de la partida
		reproducir_siguiente_aleatoria()
	
	# 4. ESPERA TÉCNICA: Damos 1 segundo para que los 4 robots aparezcan en el mapa
	await get_tree().create_timer(1.0).timeout
	
	# 5. SISTEMA DE EVENTOS: Conectamos al árbitro
	conectar_jugadores()
	partida_iniciada = true
	
	# Mensaje de diagnóstico para la consola
	var total_jugadores = get_tree().get_nodes_in_group("jugadores").size()
	print("Árbitro: Partida iniciada correctamente con ", total_jugadores, " jugadores.")

# --- LÓGICA DE LA PLAYLIST (NUEVO) ---

func reproducir_siguiente_aleatoria() -> void:
	if playlist_arena.is_empty():
		return
		
	var nueva_cancion = playlist_arena.pick_random()
	
	# Si hay varias canciones, evitamos que se repita la misma dos veces seguidas
	if playlist_arena.size() > 1 and reproductor_musica.stream == nueva_cancion:
		reproducir_siguiente_aleatoria()
		return
		
	reproductor_musica.stream = nueva_cancion
	reproductor_musica.play()
	print("DJ: Reproduciendo pista aleatoria: ", nueva_cancion.resource_path.get_file())

# Función preparada para tu futuro botón de "Saltar Canción"
func cambiar_a_siguiente_cancion() -> void:
	reproducir_siguiente_aleatoria()

# --- CONTROLADOR DE EVENTOS ---

func conectar_jugadores() -> void:
	var jugadores = get_tree().get_nodes_in_group("jugadores")
	for jugador in jugadores:
		# Conectamos la señal de muerte al árbitro
		if not jugador.tree_exited.is_connected(_on_jugador_eliminado):
			jugador.tree_exited.connect(_on_jugador_eliminado)

func _on_jugador_eliminado() -> void:
	if not partida_iniciada or juego_terminado:
		return
	verificar_estado_partida.call_deferred()

func verificar_estado_partida() -> void:
	if not partida_iniciada or juego_terminado:
		return
		
	var jugadores_vivos = get_tree().get_nodes_in_group("jugadores")
	
	if jugadores_vivos.size() == 1:
		var ganador = jugadores_vivos[0]
		var id = ganador.id_jugador if "id_jugador" in ganador else 1
		anunciar_victoria(id)
	elif jugadores_vivos.size() == 0:
		anunciar_empate()

# --- LÓGICA DE FINALIZACIÓN ---

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

# --- ACCIONES DE SALIDA ---

func _on_btn_reiniciar_pressed() -> void:
	get_tree().reload_current_scene()

func volver_al_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")