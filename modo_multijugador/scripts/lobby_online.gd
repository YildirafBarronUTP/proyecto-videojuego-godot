extends Control

@onready var label_estado: Label = $LabelEstado
@onready var btn_empezar: Button = $BtnEmpezar
@onready var btn_salir: Button = $BtnSalir

func _ready() -> void:
	btn_empezar.pressed.connect(_on_btn_empezar_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	
	# Configuración de privilegios según el rol de red
	if multiplayer.is_server():
		label_estado.text = "Sala activa. Rol: HOST (Servidor). Esperando jugadores..."
		btn_empezar.disabled = false
	else:
		label_estado.text = "Conectado a la sala. Rol: CLIENTE. Esperando al Host..."
		btn_empezar.disabled = true

func _on_btn_empezar_pressed() -> void:
	# El Host ejecuta la función a través de la red para todas las máquinas conectadas
	iniciar_partida_red.rpc()

# Definimos el canal de transmisión de red para el cambio de escena
@rpc("call_local", "any_peer", "reliable")
func iniciar_partida_red() -> void:
	get_tree().change_scene_to_file("res://modo_multijugador/scenes/escenario_prueba_online.tscn")

func _on_btn_salir_pressed() -> void:
	GestorRed.limpiar_red()
	get_tree().change_scene_to_file("res://modo_multijugador/scenes/menu_conexion.tscn")