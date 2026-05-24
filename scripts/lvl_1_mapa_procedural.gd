extends MapaProcedural # Heredar lógica

func _ready() -> void:
	# personalizar las dimensiones
	columnas = 15
	filas = 13
	probabilidad_contenedor = 0.7 # Más o menos obstáculos
	
	# Llama a la función del script que dibuja el mapa
	super._ready()
