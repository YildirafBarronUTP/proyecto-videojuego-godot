extends "res://scripts/contenedor.gd"

func _ready() -> void:
	hp = 1 
	print("Contenedor del Nivel 1 listo con ", hp, " HP")

# porcentaje de drops diferentes, 
func generar_bonificacion() -> void:
	var roll_tipo = randi() % 100 
	var nueva_bonificacion = null

	# Antes Rango era < 40 (40% de probabilidad). Ahora lo bajamos a 20%.
	if roll_tipo < 20 and escena_rango != null:
		nueva_bonificacion = escena_rango.instantiate()
		print("Drop Nivel 1: Bonificación de Rango (20% p)")
		
	# Antes Velocidad era entre 40 y 70 (30% p). Ahora entre 20 y 45 (25% p).
	elif roll_tipo < 45 and escena_velocidad != null:
		nueva_bonificacion = escena_velocidad.instantiate()
		print("Drop Nivel 1: Bonificación de Velocidad (25% p)")
		
	# Antes Cargas era el resto (30% p). Ahora si cae entre 45 y 60 (15% p).
	# Añadimos un límite para que el 40% restante de las veces (de 60 a 100) NO suelte nada.
	elif roll_tipo < 60 and escena_cargas != null:
		nueva_bonificacion = escena_cargas.instantiate()
		print("Drop Nivel 1: Bonificación de Cargas (15% p)")
	else:
		print("Drop Nivel 1: El contenedor estaba vacío (40% p de no drop)")
	
	# Si se seleccionó una bonificación, la posicionamos e instanciamos
	if nueva_bonificacion != null:
		nueva_bonificacion.global_position = global_position
		get_parent().call_deferred("add_child", nueva_bonificacion)
