extends "res://scripts/contenedor.gd"

# Puedes darle más vida o propiedades únicas para tu nivel
func _ready() -> void:
	hp = 1 
	print("Contenedor del Nivel 1 listo con ", hp, " HP")

# Si quieres que en tu nivel los drops sean diferentes, 
# puedes sobrescribir la función generar_bonificacion:
func generar_bonificacion() -> void:
	# Aquí podrías cambiar las probabilidades o llamar a la lógica original
	super.generar_bonificacion()
	super.generar_bonificacion()
