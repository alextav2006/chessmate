extends Node

@onready var start_board = preload("res://Cenários/tabuleiro.tscn") as PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().change_scene_to_packed(start_board)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
