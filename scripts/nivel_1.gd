extends Node2D

# Creamos los reproductores de audio dinámicamente apuntando a tus archivos
@onready var musica_fondo: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sonido_lava: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	print("Nivel 1 iniciado correctamente")
	
	# 1. Configurar el tema principal (main_theme.wav)
	musica_fondo.stream = load("res://sounds/soundtrack/Nivel1/main_theme.wav")
	musica_fondo.volume_db = -5.0 # Ajusta el volumen si suena muy fuerte
	add_child(musica_fondo)
	musica_fondo.play() # Inicia la música de fondo
	
	# 2. Configurar el sonido ambiental de la lava (lava_flow.wav)
	sonido_lava.stream = load("res://sounds/soundtrack/Nivel1/lava_flow.wav")
	sonido_lava.volume_db = -17.0 # Un poco más bajo para que no opaque la música
	add_child(sonido_lava)
	sonido_lava.play() # Inicia el sonido de la lava

func _process(_delta: float) -> void:
	pass
