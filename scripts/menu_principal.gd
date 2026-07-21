extends Control

# Carga de recursos del cursor
const CURSOR_BOMBA = preload("res://assets/ui/maus_bomb.png")
const CURSOR_EXPLOSION = preload("res://assets/ui/maus_explotion.png")

# Nodos de sonido
@onready var sonido_click: AudioStreamPlayer = $SonidoClick if has_node("SonidoClick") else null
@onready var sonido_hover: AudioStreamPlayer = $SonidoHover if has_node("SonidoHover") else null

func _ready() -> void:
	# Inicializamos el cursor con la bomba
	Input.set_custom_mouse_cursor(CURSOR_BOMBA, Input.CURSOR_ARROW, Vector2(16, 16))
	
	# Conectamos automáticamente el sonido de mecha a TODOS los botones
	_conectar_efectos_botones(self)

func _process(delta: float) -> void:
	pass

# --- Botón 1: Selector de Niveles ---
func _on_button_pressed() -> void:
	_reproducir_y_cambiar_escena("res://scenes/ui/SelectorNiveles.tscn")

# --- Botón 2: Lobby ---
func _on_button_2_pressed() -> void:
	_reproducir_y_cambiar_escena("res://scenes/ui/lobby.tscn")

# --- Botón 3: Menú de Conexión Multijugador ---
func _on_button_3_pressed() -> void:
	_reproducir_y_cambiar_escena("res://modo_multijugador/scenes/menu_conexion.tscn")

# === FUNCIONES AUXILIARES ===

func _reproducir_y_cambiar_escena(ruta_escena: String) -> void:
	_efecto_explosion_cursor()
	
	if sonido_click != null:
		sonido_click.play()
		await sonido_click.finished 
		
	get_tree().change_scene_to_file(ruta_escena)

func _efecto_explosion_cursor() -> void:
	Input.set_custom_mouse_cursor(CURSOR_EXPLOSION, Input.CURSOR_ARROW, Vector2(16, 16))
	await get_tree().create_timer(0.15).timeout
	Input.set_custom_mouse_cursor(CURSOR_BOMBA, Input.CURSOR_ARROW, Vector2(16, 16))

func _conectar_efectos_botones(nodo: Node) -> void:
	if nodo is BaseButton:
		# 1. Ajustamos el pivote al centro del botón para que escale parejo
		nodo.pivot_offset = nodo.size / 2
		
		# --- HOVER (Mouse entra al botón) ---
		nodo.mouse_entered.connect(func():
			# Reproducir sonido de la mecha
			if sonido_hover != null:
				sonido_hover.stop()
				sonido_hover.play()
			
			# Animación Pop-Up: Agranda el botón a 108% en 0.1 segundos
			var tween = create_tween()
			tween.tween_property(nodo, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var tween_color = create_tween()
			tween_color.tween_property(nodo, "self_modulate", Color("f1c40f"), 0.1) # Amarillo chispa
		)
		
		# --- LEAVE (Mouse sale del botón) ---
		nodo.mouse_exited.connect(func():
			# Regresa el botón a su tamaño normal (100%)
			var tween = create_tween()
			tween.tween_property(nodo, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var tween_color = create_tween()
			tween_color.tween_property(nodo, "self_modulate", Color.WHITE, 0.1) # Vuelve al color original
		)
		
		# AUTOMATIZACIÓN DE CLICS (Para menu_principal.gd si aplica)
		if nodo.has_method("_on_button_pressed"): # Ajustar según tus métodos manuales
			pass
			
	# Recorrido de nodos hijos
	for hijo in nodo.get_children():
		_conectar_efectos_botones(hijo)
