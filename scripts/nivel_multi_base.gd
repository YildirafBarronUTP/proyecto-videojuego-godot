extends Node2D
class_name NivelMultiBase

var juego_terminado: bool = false
var partida_iniciada: bool = false

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

	conectar_jugadores()
	partida_iniciada = true

	var total_jugadores = get_tree().get_nodes_in_group("jugadores").size()
	print("Árbitro: Partida iniciada correctamente con ", total_jugadores, " jugadores.")

func reproducir_siguiente_aleatoria() -> void:
	if playlist_arena.is_empty():
		return
		
	var nueva_cancion = playlist_arena.pick_random()
	
	if playlist_arena.size() > 1 and reproductor_musica.stream == nueva_cancion:
		reproducir_siguiente_aleatoria()
		return
		
	reproductor_musica.stream = nueva_cancion
	reproductor_musica.play()
	print("DJ: Reproduciendo pista aleatoria: ", nueva_cancion.resource_path.get_file())

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
	get_tree().reload_current_scene()

func volver_al_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")