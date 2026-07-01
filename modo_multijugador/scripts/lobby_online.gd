extends Control

@onready var label_estado: Label = $LabelEstado
@onready var btn_empezar: Button = $BtnEmpezar
@onready var btn_salir: Button = $BtnSalir

@onready var btn_azul: Button = $ContenedorColores/BtnAzul
@onready var btn_rojo: Button = $ContenedorColores/BtnRojo
@onready var btn_morado: Button = $ContenedorColores/BtnMorado
@onready var btn_verde: Button = $ContenedorColores/BtnVerde

@onready var btn_listo: Button = $BtnListo
@onready var preview_personaje: Sprite2D = $PreviewPersonaje
@onready var animador_preview: AnimationPlayer = $AnimationPlayer

@export var textura_azul: Texture2D
@export var textura_rojo: Texture2D
@export var textura_morado: Texture2D
@export var textura_verde: Texture2D

var mi_color_elegido: int = 1 
var estoy_listo: bool = false

func _ready() -> void:
	btn_empezar.pressed.connect(_on_btn_empezar_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	
	btn_azul.pressed.connect(func(): _cambiar_color_local(1))
	btn_rojo.pressed.connect(func(): _cambiar_color_local(2))
	btn_morado.pressed.connect(func(): _cambiar_color_local(3))
	btn_verde.pressed.connect(func(): _cambiar_color_local(4))
	
	btn_listo.pressed.connect(_on_btn_listo_pressed)
	
	GestorRed.lista_actualizada.connect(_actualizar_interfaz_colores)
	GestorRed.todos_listos.connect(_on_todos_listos)
	
	if multiplayer.is_server():
		label_estado.text = "Sala activa. Rol: HOST. Esperando que todos confirmen..."
		btn_empezar.disabled = true 
	else:
		label_estado.text = "Conectado a la sala. Rol: CLIENTE. Elige y presiona Confirmar."
		btn_empezar.disabled = true
		
	_cambiar_color_local(1)
	
	# === SOLUCIÓN AL DESFASE DE CARGA ===
	# Forzamos una lectura manual del estado de la red apenas entramos a la escena
	# por si nos perdimos de alguna señal mientras cargábamos.
	_actualizar_interfaz_colores()
	GestorRed._verificar_listos()

func _cambiar_color_local(id_color: int) -> void:
	if estoy_listo:
		return 
		
	mi_color_elegido = id_color
	
	match id_color:
		1: preview_personaje.texture = textura_azul
		2: preview_personaje.texture = textura_rojo
		3: preview_personaje.texture = textura_morado
		4: preview_personaje.texture = textura_verde
		
	if preview_personaje.texture != null:
		animador_preview.play("caminar_frente")

func _on_btn_listo_pressed() -> void:
	estoy_listo = true
	btn_listo.disabled = true
	btn_listo.text = "Esperando a los demás..."
	
	btn_azul.disabled = true
	btn_rojo.disabled = true
	btn_morado.disabled = true
	btn_verde.disabled = true
	
	var mi_id = multiplayer.get_unique_id()
	GestorRed.sincronizar_eleccion.rpc(mi_id, mi_color_elegido, true)

func _actualizar_interfaz_colores() -> void:
	if estoy_listo: return 
	
	btn_azul.disabled = false
	btn_rojo.disabled = false
	btn_morado.disabled = false
	btn_verde.disabled = false
	
	var mi_id = multiplayer.get_unique_id()
	
	for id in GestorRed.lista_jugadores:
		if id != mi_id:
			var color_ocupado = GestorRed.lista_jugadores[id]["color"]
			match color_ocupado:
				1: btn_azul.disabled = true
				2: btn_rojo.disabled = true
				3: btn_morado.disabled = true
				4: btn_verde.disabled = true

	var mi_boton_actual: Button = null
	match mi_color_elegido:
		1: mi_boton_actual = btn_azul
		2: mi_boton_actual = btn_rojo
		3: mi_boton_actual = btn_morado
		4: mi_boton_actual = btn_verde
		
	if mi_boton_actual != null and mi_boton_actual.disabled:
		if not btn_azul.disabled: _cambiar_color_local(1)
		elif not btn_rojo.disabled: _cambiar_color_local(2)
		elif not btn_morado.disabled: _cambiar_color_local(3)
		elif not btn_verde.disabled: _cambiar_color_local(4)

func _on_todos_listos(listos: bool) -> void:
	if multiplayer.is_server():
		if listos:
			label_estado.text = "¡Todos listos! Puedes empezar la partida."
			btn_empezar.disabled = false
		else:
			label_estado.text = "Sala activa. Rol: HOST. Esperando que todos confirmen..."
			btn_empezar.disabled = true

func _on_btn_empezar_pressed() -> void:
	iniciar_partida_red.rpc()

@rpc("call_local", "any_peer", "reliable")
func iniciar_partida_red() -> void:
	get_tree().change_scene_to_file("res://modo_multijugador/scenes/escenario_prueba_online.tscn")

func _on_btn_salir_pressed() -> void:
	GestorRed.limpiar_red()
	get_tree().change_scene_to_file("res://modo_multijugador/scenes/menu_conexion.tscn")