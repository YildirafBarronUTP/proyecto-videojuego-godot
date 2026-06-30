extends MapaProcedural # Heredar logica

# 1. AGREGAMOS LA SEÑAL AQUÍ ARRIBA
signal mapa_generado_lvl2

func _ready() -> void:
	# personalizar las dimensiones
	columnas = 15
	filas = 13
	probabilidad_contenedor = 0.7 # Más o menos obstáculos
	
	# Llama a la función del script que dibuja el mapa
	super._ready()
	
	# 2. AGREGAMOS EL AVISO AQUÍ ABAJO
	print("Lvl2_Mapa: Estructura procedural completada. Emitiendo señal...")
	mapa_generado_lvl2.emit()
