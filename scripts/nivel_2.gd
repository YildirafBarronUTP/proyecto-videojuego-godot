extends Node2D

@export var escena_jefe: PackedScene = preload("res://scenes/entidades/boss_alfil.tscn")
@onready var musica_fondo: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sonido_ambiente: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	print("Nivel 2 iniciado, ¡preparen la artillería!")
	
	# Asegúrate de que este archivo sí exista
	var stream_musica = load("res://sounds/soundtrack/Nivel2/main_theme.wav")
	if stream_musica:
		musica_fondo.stream = stream_musica 
		musica_fondo.volume_db = -5.0
		add_child(musica_fondo)
		musica_fondo.play()
	
	# Asegúrate de que este archivo sí exista
	var stream_ambiente = load("res://sounds/soundtrack/Nivel2/cortocircuito.wav")
	if stream_ambiente:
		sonido_ambiente.stream = stream_ambiente 
		sonido_ambiente.volume_db = -17.0
		add_child(sonido_ambiente)
		sonido_ambiente.play()
	
	await get_tree().create_timer(0.1).timeout
	
	if has_node("MapaProcedural"): 
		var mapa = $MapaProcedural
		print("Mapa detectado. Spawneando al Tanque Alfil...")
		await get_tree().process_frame
		spawnear_jefe(mapa)
	else:
		print("ERROR CRÍTICO: No se encontró el nodo MapaProcedural.")
		spawnear_jefe(null)

func spawnear_jefe(mapa: Node) -> void:
	if escena_jefe:
		var jefe = escena_jefe.instantiate()
		var cols = 15
		var fils = 13
		var tam_celda = Vector2(128, 128)
		
		var desplaza = Vector2.ZERO 
		if mapa and "desplazamiento_mapa" in mapa:
			desplaza = mapa.desplazamiento_mapa
		
		var offset_x = -((cols * tam_celda.x) / 2.0) + (tam_celda.x / 2.0) + desplaza.x
		var offset_y = -((fils * tam_celda.y) / 2.0) + (tam_celda.y / 2.0) + desplaza.y
		var compensacion_pivote = tam_celda / 2.0
		
		var destino_x = cols - 2
		var destino_y = fils - 2
		
		jefe.global_position = Vector2(
			offset_x + (destino_x * tam_celda.x), 
			offset_y + (destino_y * tam_celda.y)
		) + compensacion_pivote

		add_child(jefe)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("volver_menu"):
		get_tree().change_scene_to_file("res://scenes/ui/SelectorNiveles.tscn")
