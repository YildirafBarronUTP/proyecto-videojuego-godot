extends Area2D

# --- CONFIGURACIÓN DESDE EL INSPECTOR ---
# Esto creará un menú desplegable en Godot para elegir el tipo sin errores de tipeo
@export_enum("rango", "velocidad", "cargas") var tipo_bonificacion: String = "rango"

# Cuánto suma (ej. +1 bomba, +1 rango, o +100 de velocidad)
@export var valor_bonificacion: float = 1.0

func _ready() -> void:
	# Conectamos el sensor para detectar cuando alguien lo pisa
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos que quien lo pisó sea un Jugador y tenga la función lista
	if body is CharacterBody2D and body.has_method("aplicar_bonificacion"):
		
		# Le inyectamos el tipo y el valor al jugador
		body.aplicar_bonificacion(tipo_bonificacion, valor_bonificacion)
		
		# Desaparecemos la bonificación del mapa
		queue_free()