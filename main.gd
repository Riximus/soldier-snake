extends Node2D

@export var player_scene : PackedScene
@export var player_soldier_scene : PackedScene

@onready var viewport_size = get_viewport_rect().size

# game variables
var game_started : bool = false
var score : int

# neutral soldier variables
var neutral_soldier_pos : Vector2
var regen_neutral_soldier : bool = true

# grid variables
var tile_size : int = 16
var tile_size_center : int = tile_size / 2
@onready var grid_width : int = int(viewport_size.x / 16)
@onready var grid_height : int = int(viewport_size.y / 16)

# army variables
var old_data : Array
var army_data : Array
var army : Array

# movement variables
var direction = {"right": Vector2.RIGHT,
			"left": Vector2.LEFT,
			"up": Vector2.UP,
			"down": Vector2.DOWN}
var start_pos = Vector2(5, 5)
var move_direction : Vector2
var can_move: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()

func new_game():
	score = 0
	move_direction = direction.up
	can_move = true
	generate_army()
	move_neutral_soldier()

func generate_army():
	old_data.clear()
	army_data.clear()
	army.clear()
	# Add the king as the first segment
	add_segment(start_pos, true)
	# Starting with the start_pos, create soldier segments vertically down
	for i in range(1, 3):  # create two soldiers
		add_segment(start_pos + Vector2(0, i))

		
func add_segment(pos, is_king=false):
	var Segment
	army_data.append(pos)
	if is_king:
		Segment = player_scene.instantiate()
	else:
		Segment = player_soldier_scene.instantiate()
	Segment.position = (pos * tile_size) + Vector2(tile_size_center, tile_size_center)
	add_child(Segment)
	army.append(Segment)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_army()

func move_army():
	if can_move:
		if Input.is_action_just_pressed("move_down") and move_direction != direction.up:
			move_direction = direction.down
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_up") and move_direction != direction.down:
			move_direction = direction.up
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_left") and move_direction != direction.right:
			move_direction = direction.left
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_right") and move_direction != direction.left:
			move_direction = direction.right
			can_move = false
			if not game_started:
				start_game()

func start_game():
	game_started = true
	$MoveTimer.start()

func _on_move_timer_timeout():
	# allow army movement
	can_move = true
	
	# use the army's previous position to move the segments
	old_data = [] + army_data
	army_data[0] += move_direction
	for i in range(len(army_data)):
		# move all segments along by one
		if i > 0:
			army_data[i] = old_data[i - 1]
		army[i].position = (army_data[i] * tile_size) + Vector2(tile_size_center, tile_size_center)  # adjusted position
	check_out_of_bounds()
	check_self_eaten()
	check_soldier_hired()

func check_out_of_bounds():
	if army_data[0].x < 0 or army_data[0].x > grid_width - 1 or army_data[0].y < 0 or army_data[0].y > grid_height - 1:
		end_game()

func check_self_eaten():
	for i in range(1, len(army_data)):
		if army_data[0] == army_data[i]:
			end_game()
			
func check_soldier_hired():
	if army_data[0] == neutral_soldier_pos:
		add_segment(old_data[-1])
		move_neutral_soldier()
			
func move_neutral_soldier():
	while regen_neutral_soldier:
		regen_neutral_soldier = false
		neutral_soldier_pos = Vector2(randi_range(0, grid_width-1), randi_range(0, grid_height-1))
		for i in army_data:
			if neutral_soldier_pos == i:
				regen_neutral_soldier = true
	$NeutralSoldier.position = (neutral_soldier_pos * tile_size) + Vector2(tile_size_center, tile_size_center)
	regen_neutral_soldier = true

func end_game():
	pass
