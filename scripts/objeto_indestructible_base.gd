extends StaticBody2D
class_name ObjetoIndestructibleBase # Esto registra el tipo en Godot

# Al ser indestructible, este objeto no necesita HP ni lógica de daño.
# Simplemente se asegura de estar en la capa de colisión correcta.

func _ready() -> void:
	# TODO: Configurar aquí la 'Collision Layer' para que sea detectada por las explosiones
	# pero no por el movimiento de los jugadores (que ya chocan por ser un StaticBody2D).
	print("Instanciado objeto indestructible de tipo base.")