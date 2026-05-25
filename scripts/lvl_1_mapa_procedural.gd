extends MapaProcedural # Heredar lógica de tu compañero

# NUEVO: Declaramos la señal específica para tu nivel 1
signal mapa_generado_lvl1

func _ready() -> void:
	# Personalizar las dimensiones para tu nivel
	columnas = 15
	filas = 13
	probabilidad_contenedor = 0.7 
	
	# Llama a la función del script padre que dibuja TODO el mapa
	super._ready()
	
	# NUEVO: Como super._ready() ya terminó, el mapa ya existe en pantalla.
	# Emitimos la señal justo ahora.
	print("Lvl1_Mapa: Estructura procedural completada. Emitiendo señal...")
	mapa_generado_lvl1.emit()
