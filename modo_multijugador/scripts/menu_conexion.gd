extends Control

@onready var btn_crear: Button = $BtnCrearSala
@onready var btn_unirse: Button = $BtnUnirse
@onready var input_ip: LineEdit = $InputIP
@onready var btn_volver: Button = $BtnVolver

func _ready() -> void:
	btn_crear.pressed.connect(_on_btn_crear_pressed)
	btn_unirse.pressed.connect(_on_btn_unirse_pressed)
	btn_volver.pressed.connect(_on_btn_volver_pressed)
	
	# Escuchamos los eventos del GestorRed antes de cambiar de pantalla
	GestorRed.sala_creada.connect(_on_conexion_exitosa)
	GestorRed.conexion_ok.connect(_on_conexion_exitosa)
	GestorRed.conexion_error.connect(_on_conexion_fallida)

func _on_btn_crear_pressed() -> void:
	_bloquear_interfaz()
	GestorRed.crear_sala()

func _on_btn_unirse_pressed() -> void:
	var ip = input_ip.text
	if ip == "":
		ip = "127.0.0.1"
	_bloquear_interfaz()
	GestorRed.unirse_a_sala(ip)

func _on_conexion_exitosa() -> void:
	# Cambiamos al lobby solo cuando la red esté lista
	get_tree().change_scene_to_file("res://modo_multijugador/scenes/lobby_online.tscn")

func _on_conexion_fallida() -> void:
	btn_crear.disabled = false
	btn_unirse.disabled = false
	print("No se pudo establecer la conexión de red.")

func _bloquear_interfaz() -> void:
	btn_crear.disabled = true
	btn_unirse.disabled = true

func _on_btn_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")