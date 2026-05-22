extends Node

# Diccionario global para definir el tipo de entidad por cada ranura (Slot)
# Valores permitidos: "HUMANO" o "CPU"
var configuracion_jugadores: Dictionary = {
	1: "HUMANO",
	2: "CPU",
	3: "CPU",
	4: "CPU"
}

# Puedes usar este diccionario para definir qué color o textura inyectar a cada uno
var texturas_asignadas: Dictionary = {}