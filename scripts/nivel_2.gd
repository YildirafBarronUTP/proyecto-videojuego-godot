extends Node2D

@onready var musica_fondo: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var cortocircuito: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	print("Nivel 1 iniciado correctamente")
	
	# 1. Configurar el tema principal (main_theme.wav)
	musica_fondo.stream = load("res://sounds/soundtrack/Nivel2/main_theme.wav")
	musica_fondo.volume_db = -9.0 # Ajusta el volumen
	add_child(musica_fondo)
	musica_fondo.play()
	
	# 2. Configurar el sonido ambiental (Cortocircuito.wav)
	cortocircuito.stream = load("res://sounds/soundtrack/Nivel2/cortocircuito.wav")
	cortocircuito.volume_db = -15.0 # para que no opaque la música
	add_child(cortocircuito)
	cortocircuito.play()


func _process(delta: float) -> void:
	pass
