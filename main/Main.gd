extends Node2D

export (PackedScene) var Rock
export (PackedScene) var Enemy

# HUD support
var level = 0
var score = 0
var playing = false

# Screensize forward declare
var screensize = Vector2()


# Gets screensize, passes to player, and spawns 3 rocks of size 3
func _ready():
	$Player.set_shield(100)
	randomize()
	screensize = get_viewport().get_visible_rect().size
	$Player.screensize = screensize
	for i in range(3):
		spawn_rock(3)


# Checks every frame whether rocks are cleared; proceeds to new level if so
func _process(delta):
	if playing and $Rocks.get_child_count() == 0:
		new_level()


# Game has been paused / unpaused; changes label accordingly
func _input(event):
	if event.is_action_pressed('pause'):
		if not playing:
			return
		
		get_tree().paused = not get_tree().paused
		
		if get_tree().paused:
			$HUD/MessageLabel.text = 'Paused'
			$HUD/MessageLabel.show()
		else:
			$HUD/MessageLabel.text = ''
			$HUD/MessageLabel.hide()


# Starts a new game
func new_game():
	$Music.play()
	
	# Clears any old rocks
	for rock in $Rocks.get_children():
		rock.queue_free()
	
	# Sets game variables back to their starting values
	level = 0
	score  = 0
	$HUD.update_score(score)
	$Player.start()
	$HUD.show_message("Get Ready!")
	yield($HUD/MessageTimer, 'timeout')
	playing = true
	new_level()


# Starts level, increasing rocks spawned based on level
func new_level():
	$LevelupSound.play()
	level += 1
	$HUD.show_message("Wave %s" % level)
	for i in range(level):
		spawn_rock(3)
	
	# Start timer from a random range to spawn enemy ship(s)
	$EnemyTimer.wait_time = rand_range(5, 10)
	$EnemyTimer.start()


# Game over
func game_over():
	$Music.stop()
	playing = false
	$HUD.game_over()


# Spawns rock and connects exploded signal
func spawn_rock(size, pos=null, vel=null):
	# Sets random position within the window
	if !pos:
		$RockPath/RockSpawn.set_offset(randi())
		pos = $RockPath/RockSpawn.position

	# Sets velocity
	if !vel:
		vel = Vector2(1, 0).rotated(rand_range(0, 2 * PI)) * rand_range(100, 150)
	
	# Instantiate rock and add to Rocks container
	var r = Rock.instance()
	r.screensize = screensize
	r.start(pos, vel, size)
	$Rocks.add_child(r)
	
	# Connects exploded signal
	r.connect('exploded', self, '_on_Rock_exploded')


# Fires bullet
func _on_Player_shoot(bullet, pos, dir):
	var b = bullet.instance()
	b.start(pos, dir)
	add_child(b)


# Rock has exploded; spawn smaller rocks unless rock is smallest size it can be and adds to score
func _on_Rock_exploded(size, radius, pos, vel):
	$ExplodeSound.play()
	score += size * 10
	$HUD.update_score(score)
	
	if size <= 1:
		return
	# Splits rock into two rocks going at an opposing tangent to the player, 
	# setting and passing new positions and velocities
	for offset in [-1, 1]:
		var dir = (pos - $Player.position).normalized().tangent() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newvel)


# Timer ends, spawn an enemy
func _on_EnemyTimer_timeout():
	# Instantiate enemy
	var e = Enemy.instance()
	add_child(e)
	
	# Enemy targets the player, firing the same shot the player does
	e.target = $Player
	e.connect('shoot', self, '_on_Player_shoot')
	
	# Start enemy timer again
	$EnemyTimer.wait_time = rand_range(20, 40)
	$EnemyTimer.start()
