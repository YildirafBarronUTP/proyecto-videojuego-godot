extends Control

# Carga de recursos del cursor
const CURSOR_BOMBA = preload("res://assets/ui/maus_bomb.png")
const CURSOR_EXPLOSION = preload("res://assets/ui/maus_explotion.png")

# Referencias a los botones de selección en tu árbol de nodos
@onready var btn_p1: Button = $Panel/BtnP1
@onready var btn_p2: Button = $Panel/BtnP2
@onready var btn_p3: Button = $Panel/BtnP3
@onready var btn_p4: Button = $Panel/BtnP4

# Nodos de audio
@onready var sonido_click: AudioStreamPlayer = $SonidoClick if has_node("SonidoClick") else null
@onready var sonido_hover: AudioStreamPlayer = $SonidoHover if has_node("SonidoHover") else null

func _ready() -> void:
	# Aseguramos el cursor de la bomba al abrir este menú
	Input.set_custom_mouse_cursor(CURSOR_BOMBA, Input.CURSOR_ARROW, Vector2(16, 16))
	
	# Sincronizamos el texto de los botones con el estado actual del Singleton
	actualizar_interfaz_botones()
	
	# Conectamos automáticamente el sonido de hover/mecha a todos los botones
	_conectar_efectos_botones(self)
	
	# Conectamos las señales ejecutando la animación y el sonido por cada slot
	btn_p1.pressed.connect(func(): _alternar_slot(1))
	btn_p2.pressed.connect(func(): _alternar_slot(2))
	btn_p3.pressed.connect(func(): _alternar_slot(3))
	btn_p4.pressed.connect(func(): _alternar_slot(4))

func _alternar_slot(id_slot: int) -> void:
	# Efecto visual y sonoro al cambiar entre HUMANO y CPU
	_efecto_explosion_cursor()
	if sonido_click != null:
		sonido_click.play()
		
	# Cambia el estado cíclicamente
	if GameManager.configuracion_jugadores[id_slot] == "HUMANO":
		GameManager.configuracion_jugadores[id_slot] = "CPU"
	else:
		GameManager.configuracion_jugadores[id_slot] = "HUMANO"
	
	actualizar_interfaz_botones()

func actualizar_interfaz_botones() -> void:
	btn_p1.text = "P1: " + GameManager.configuracion_jugadores[1]
	btn_p2.text = "P2: " + GameManager.configuracion_jugadores[2]
	btn_p3.text = "P3: " + GameManager.configuracion_jugadores[3]
	btn_p4.text = "P4: " + GameManager.configuracion_jugadores[4]

# Conecta esta señal desde el inspector para tu botón de "Jugar"
func _on_btn_iniciar_partida_pressed() -> void:
	_efecto_explosion_cursor()
	
	if sonido_click != null:
		sonido_click.play()
		await sonido_click.finished
		
	get_tree().change_scene_to_file("res://scenes/niveles/multijugador/nivel_multi.tscn")

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
			
			# Animación Pop-Up: Agranda el botón a 108% en 0.1 segundos
			var tween = create_tween()
			tween.tween_property(nodo, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		
		# --- LEAVE (Mouse sale del botón) ---
		nodo.mouse_exited.connect(func():
			# Regresa el botón a su tamaño normal (100%)
			var tween = create_tween()
			tween.tween_property(nodo, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		
		# AUTOMATIZACIÓN DE CLICS (Para menu_principal.gd si aplica)
		if nodo.has_method("_on_button_pressed"): # Ajustar según tus métodos manuales
			pass
			
	# Recorrido de nodos hijos
	for hijo in nodo.get_children():
		_conectar_efectos_botones(hijo)
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("volver_menu"):
		get_viewport().set_input_as_handled()
		
		# Efecto visual y sonoro antes de salir
		_efecto_explosion_cursor()
		if sonido_click != null:
			sonido_click.play()
			await sonido_click.finished
		
		# Cambiamos directamente de escena al Menú Principal
		get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")
