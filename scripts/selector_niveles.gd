extends Control

# Carga de recursos del cursor
const CURSOR_BOMBA = preload("res://assets/ui/maus_bomb.png")
const CURSOR_EXPLOSION = preload("res://assets/ui/maus_explotion.png")

# Corrección de rutas del Panel
@onready var btn_nivel_1: Button = $Panel/Button
@onready var btn_nivel_2: Button = $Panel/Button2
@onready var btn_nivel_3: Button = $Panel/Button3
@onready var btn_volver: Button = $Panel/BtnVolver if has_node("Panel/BtnVolver") else null

# Nodos de audio
@onready var sonido_click: AudioStreamPlayer = $SonidoClick if has_node("SonidoClick") else null
@onready var sonido_hover: AudioStreamPlayer = $SonidoHover if has_node("SonidoHover") else null

func _ready() -> void:
	# Mantenemos el cursor de la bomba activado al entrar al selector
	Input.set_custom_mouse_cursor(CURSOR_BOMBA, Input.CURSOR_ARROW, Vector2(16, 16))
	
	# Conectamos automáticamente el sonido, escala y color rojo a todos los botones
	_conectar_efectos_botones(self)
	
	# Conectamos las señales 'pressed'
	btn_nivel_1.pressed.connect(func(): _cargar_nivel("res://scenes/niveles/nivel1/nivel_1.tscn"))
	btn_nivel_2.pressed.connect(func(): _cargar_nivel("res://scenes/niveles/nivel2/nivel_2.tscn"))
	btn_nivel_3.pressed.connect(func(): _cargar_nivel("res://scenes/niveles/nivel3/nivel_3.tscn"))
	
	if btn_volver:
		btn_volver.pressed.connect(func(): _cargar_nivel("res://scenes/ui/menu_principal.tscn"))

func _cargar_nivel(ruta_escena: String) -> void:
	print("Selector: Cargando el escenario -> ", ruta_escena)
	
	_efecto_explosion_cursor()
	
	if sonido_click != null:
		sonido_click.play()
		await sonido_click.finished
		
	get_tree().change_scene_to_file(ruta_escena)

# === FUNCIONES AUXILIARES ===

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
			
			# Animación Pop-Up (Escala) + Cambio a Rojo Fuego
			var tween = create_tween().set_parallel(true)
			tween.tween_property(nodo, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(nodo, "self_modulate", Color(1.0, 0.25, 0.25), 0.1) # Rojo encendido
		)
		
		# --- LEAVE (Mouse sale del botón) ---
		nodo.mouse_exited.connect(func():
			# Regresa el botón a su tamaño normal y a su color original
			var tween = create_tween().set_parallel(true)
			tween.tween_property(nodo, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(nodo, "self_modulate", Color.WHITE, 0.1) # Blanco/Normal
		)
			
	# Recorrido de nodos hijos
	for hijo in nodo.get_children():
		_conectar_efectos_botones(hijo)
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("volver_menu"):
		# Evitamos que la entrada siga propagándose
		get_viewport().set_input_as_handled()
		
		# Opción A: Si estás en un selector o lobby y quieres regresar al Menú Principal
		_cargar_nivel("res://scenes/ui/menu_principal.tscn")
		
