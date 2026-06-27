extends Node2D

@export var escena_jefe: PackedScene = preload("res://scenes/entidades/jefe1.tscn")
@onready var musica_fondo: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sonido_lava: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	print("Nivel 1 iniciado correctamente")
	
	# 1. Configurar y reproducir audios
	musica_fondo.stream = load("res://sounds/soundtrack/Nivel1/main_theme.wav")
	musica_fondo.volume_db = -5.0
	add_child(musica_fondo)
	musica_fondo.play()
	
	sonido_lava.stream = load("res://sounds/soundtrack/Nivel1/lava_flow.wav")
	sonido_lava.volume_db = -17.0
	add_child(sonido_lava)
	sonido_lava.play()
	
	# 2. SOLUCIÓN AL ORDEN DE SEÑALES:
	# Damos una breve espera de tiempo para asegurar que el mapa termine su bucle procedural
	await get_tree().create_timer(0.1).timeout
	
	if has_node("lvl1_MapaProcedural"):
		var mapa = $lvl1_MapaProcedural
		print("Mapa detectado con éxito. Procediendo a instanciar al Jefe directamente...")
		
		# Esperamos un frame de procesamiento para que la matriz A* esté asentada
		await get_tree().process_frame
		spawnear_jefe(mapa)
	else:
		print("ERROR CRÍTICO: No se encontró el nodo lvl1_MapaProcedural en la raíz del nivel.")
		spawnear_jefe(null)

func spawnear_jefe(mapa: Node) -> void:
	if escena_jefe:
		var jefe = escena_jefe.instantiate()
		
		var cols = 15
		var fils = 13
		var tam_celda = Vector2(128, 128)
		
		var desplaza = Vector2(384, 0) 
		if mapa and "desplazamiento_mapa" in mapa and mapa.desplazamiento_mapa != Vector2.ZERO:
			desplaza = mapa.desplazamiento_mapa
		
		# Fórmula matemática de la cuadrícula procedural
		var offset_x = -((cols * tam_celda.x) / 2.0) + (tam_celda.x / 2.0) + desplaza.x
		var offset_y = -((fils * tam_celda.y) / 2.0) + (tam_celda.y / 2.0) + desplaza.y
		var compensacion_pivote = tam_celda / 2.0
		
		var destino_x = cols - 2
		var destino_y = fils - 2
		
		jefe.global_position = Vector2(
			offset_x + (destino_x * tam_celda.x), 
			offset_y + (destino_y * tam_celda.y)
		) + compensacion_pivote
		
		if jefe.global_position == Vector2.ZERO or jefe.global_position == compensacion_pivote:
			jefe.global_position = Vector2(1200, 500)
			print("Fallback activo: Posicionando al jefe en coordenada fija segura.")

		add_child(jefe)
		print("¡Jefe aparecido con éxito! Coordenadas reales en: ", jefe.global_position)
		
# Regresar al menu con la tecla ESC
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("volver_menu"):
		print("Nivel: Regresando al Selector de Niveles...")
		get_tree().change_scene_to_file("res://scenes/ui/SelectorNiveles.tscn")
