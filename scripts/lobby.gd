extends Control

# Referencias a los botones de selección en tu árbol de nodos
@onready var btn_p1: Button = $Panel/BtnP1
@onready var btn_p2: Button = $Panel/BtnP2
@onready var btn_p3: Button = $Panel/BtnP3
@onready var btn_p4: Button = $Panel/BtnP4

func _ready() -> void:
	# Sincronizamos el texto de los botones con el estado actual del Singleton
	actualizar_interfaz_botones()
	
	# Conectamos las señales usando funciones anónimas (lambdas) de forma limpia
	btn_p1.pressed.connect(func(): _alternar_slot(1))
	btn_p2.pressed.connect(func(): _alternar_slot(2))
	btn_p3.pressed.connect(func(): _alternar_slot(3))
	btn_p4.pressed.connect(func(): _alternar_slot(4))

func _alternar_slot(id_slot: int) -> void:
	# Cambia el estado cíclicamente entre HUMANO y CPU
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
	get_tree().change_scene_to_file("res://scenes/niveles/multijugador/nivel_multi.tscn")