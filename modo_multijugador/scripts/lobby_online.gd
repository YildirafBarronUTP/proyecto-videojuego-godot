extends Control

@onready var label_estado: Label = $LabelEstado
@onready var btn_empezar: Button = $BtnEmpezar
@onready var btn_salir: Button = $BtnSalir

func _ready() -> void:
	btn_empezar.pressed.connect(_on_btn_empezar_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	
	# Verificamos el rol de internet de esta ventana para configurar el botón
	if multiplayer.is_server():
		label_estado.text = "Sala activa. Rol: HOST (Servidor). Esperando jugadores..."
		btn_empezar.disabled = false # El Host puede iniciar la partida
	else:
		label_estado.text = "Conectado a la sala. Rol: CLIENTE. Esperando al Host..."
		btn_empezar.disabled = true # Los clientes tienen el botón apagado

func _on_btn_empezar_pressed() -> void:
	# [FASE 4] Aquí enviaremos la señal de inicio de juego en red
	print("El host ha presionado iniciar partida...")

func _on_btn_salir_pressed() -> void:
	GestorRed.limpiar_red()
	get_tree().change_scene_to_file("res://modo_multijugador/scenes/menu_conexion.tscn")