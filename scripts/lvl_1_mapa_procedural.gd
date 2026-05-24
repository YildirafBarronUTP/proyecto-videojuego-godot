extends MapaProcedural # Hereda toda la lógica de tu compañero

func _ready() -> void:
	# Aquí puedes personalizar las dimensiones de TU nivel antes de que se genere
	columnas = 15
	filas = 13
	probabilidad_contenedor = 0.7 # Más o menos obstáculos según prefieras
	
	# Llama a la función del script de tu compañero para que dibuje el mapa
	super._ready()
