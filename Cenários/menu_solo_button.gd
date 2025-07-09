extends Button

@onready var solo = $"." as Button
@onready var quit = $"../Quit" as Button
@onready var ajuda = $"../../../Ajuda" as Button

@onready var start_board = preload("res://Cenários/tabuleiro.tscn") as PackedScene
@onready var ajuda_scene = preload("res://Cenários/ajuda.tscn")

@onready var anim_ajuda = $"../../../Ajuda/anim_ajuda"
@onready var ajuda_button = $"../../../Ajuda"

func animar_ajuda() -> void:
	ajuda_button.position -= Vector2(-25, 25)
	anim_ajuda.play("anim_scale")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animar_ajuda()
	solo.button_down.connect(on_solo_pressed)
	quit.button_down.connect(on_quit_pressed)

func on_solo_pressed() -> void:
	get_tree().change_scene_to_packed(start_board)

func on_quit_pressed() -> void:
	get_tree().quit()

func _on_ajuda_pressed() -> void:
	get_tree().change_scene_to_packed(ajuda_scene)
