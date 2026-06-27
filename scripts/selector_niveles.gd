extends Control

# Corrección de rutas: Primero entramos a 'Panel' y usamos los nombres exactos de tu imagen
@onready var btn_nivel_1: Button = $Panel/Button
@onready var btn_nivel_2: Button = $Panel/Button2
@onready var btn_nivel_3: Button = $Panel/Button3

# No veo un botón de volver en la imagen, así que lo manejamos como opcional para que no tire error
@onready var btn_volver: Button = $Panel/BtnVolver if has_node("Panel/BtnVolver") else null

func _ready() -> void:
	# Conectamos las señales 'pressed' usando funciones anónimas (lambdas)
	btn_nivel_1.pressed.connect(func(): _cargar_nivel("res://scenes/niveles/nivel1/nivel_1.tscn"))
	btn_nivel_2.pressed.connect(func(): _cargar_nivel("res://scenes/niveles/nivel2/nivel_2.tscn"))
	btn_nivel_3.pressed.connect(func(): _cargar_nivel("res://scenes/niveles/nivel3/nivel_3.tscn"))
	
	# Si en el futuro agregas un botón de volver dentro del panel, se conectará solo sin romper el juego
	if btn_volver:
		btn_volver.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn"))

func _cargar_nivel(ruta_escena: String) -> void:
	print("Selector: Cargando el escenario -> ", ruta_escena)
	get_tree().change_scene_to_file(ruta_escena)
