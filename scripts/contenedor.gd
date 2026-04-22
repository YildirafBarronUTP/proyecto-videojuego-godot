extends StaticBody2D

# --- ESTADO DEL CONTENEDOR ---
var hp: int = 1

# --- REFERENCIAS A LAS BONIFICACIONES (Loot) ---
# Podrás arrastrar las escenas de los power-ups aquí desde el Inspector
@export var escena_rango: PackedScene
@export var escena_velocidad: PackedScene
@export var escena_cargas: PackedScene

# --- SISTEMA DE DAÑO Y OCLUSIÓN ---
# La bomba buscará exactamente esta función cuando el radar toque el contenedor
func recibir_dano(cantidad: int) -> void:
	hp -= cantidad
	if hp <= 0:
		destruir()

# --- SISTEMA DE DESTRUCCIÓN Y RNG (Drop Rate) ---
func destruir() -> void:
	print("Contenedor destruido en: ", global_position)
	
	# FASE 1: 50% de probabilidad de soltar ALGO
	var roll_aparicion = randi() % 100 
	
	if roll_aparicion < 50: 
		generar_bonificacion()
	
	# Destruimos el contenedor físicamente del mapa
	queue_free() 

func generar_bonificacion() -> void:
	# FASE 2: Qué tipo de bonificación soltará (40% / 30% / 30%)
	var roll_tipo = randi() % 100 
	var nueva_bonificacion = null
	
	if roll_tipo < 40 and escena_rango != null:
		nueva_bonificacion = escena_rango.instantiate()
		print("Drop: Bonificación de Rango")
		
	elif roll_tipo < 70 and escena_velocidad != null:
		nueva_bonificacion = escena_velocidad.instantiate()
		print("Drop: Bonificación de Velocidad")
		
	elif escena_cargas != null:
		nueva_bonificacion = escena_cargas.instantiate()
		print("Drop: Bonificación de Cargas")
	
	# Si el RNG decidió soltar algo y la escena está asignada en el Inspector:
	if nueva_bonificacion != null:
		# Centramos el botín exactamente donde estaba la caja
		nueva_bonificacion.global_position = global_position
		
		# CRÍTICO: Usamos call_deferred para añadir el objeto al mapa de forma segura
		# sin interrumpir el frame de físicas del motor durante la explosión
		get_parent().call_deferred("add_child", nueva_bonificacion)