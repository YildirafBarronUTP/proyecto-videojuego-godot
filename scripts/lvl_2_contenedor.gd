extends "res://scripts/contenedor.gd"

func _ready() -> void:
	hp = 1 
	print("Contenedor del Nivel 2 listo con ", hp, " HP")

func generar_bonificacion() -> void:
	var roll_tipo = randi() % 100 
	var nueva_bonificacion = null

	if roll_tipo < 20 and escena_rango != null:
		nueva_bonificacion = escena_rango.instantiate()
		print("Drop Nivel 2: Bonificación de Rango (20% p)")
		
	elif roll_tipo < 45 and escena_velocidad != null:
		nueva_bonificacion = escena_velocidad.instantiate()
		print("Drop Nivel 2: Bonificación de Velocidad (25% p)")
		
	elif roll_tipo < 60 and escena_cargas != null:
		nueva_bonificacion = escena_cargas.instantiate()
		print("Drop Nivel 2: Bonificación de Cargas (15% p)")
	else:
		print("Drop Nivel 2: El contenedor estaba vacío (40% p de no drop)")
	
	if nueva_bonificacion != null:
		nueva_bonificacion.global_position = global_position
		get_parent().call_deferred("add_child", nueva_bonificacion)
