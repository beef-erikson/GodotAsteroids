extends Area2D

signal shoot

export (PackedScene) var Bullet
export (int) var speed
export (int) var health

# Pathing variables
var follow
var target = null


# Selects from the 3 enemy paths and adds one to path container
func _ready():
	$Sprite.frame == randi() % 3
	var path = $EnemyPaths.get_children()[randi() % $EnemyPaths.get_child_count()]
	follow = PathFollow2D.new()
	path.add_child(follow)
	follow.loop = false


# Move the enemy along the path
func _process(delta):
	follow.offset += speed * delta
	position = follow.global_position
	
	# Enemy has completed path, delete
	if follow.unit_offset > 1:
		queue_free()


# Explosion animation finished, delete enemy
func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()


# Gun timer expired, start firing pulse shot
func _on_GunTimer_timeout():
	shoot_pulse(3, 0.15)


# Finds players position and fires a bullet, randomly offset a little for variety
func shoot():
	var dir = target.global_position - global_position
	dir = dir.rotated(rand_range(-0.1, 0.1)).angle()
	emit_signal('shoot', Bullet, global_position, dir)


# Multiple rapid shots at player, n number of shots with a delay
func shoot_pulse(n, delay):
	for i in range(n):
		$ShootSound.play()
		shoot()
		yield(get_tree().create_timer(delay), 'timeout')


# Enemy hit, take away health and play hit animation, exploding if dead
func take_damage(amount):
	health -= amount
	$AnimationPlayer.play('flash')
	if health <= 0:
		explode()
	yield($AnimationPlayer, 'animation_finished')
	$AnimationPlayer.play('rotate')


# Enemy is dead, play explosion animation and clear enemy
func explode():
	$ExplodeSound.play()
	speed = 0
	$GunTimer.stop()
	$CollisionShape2D.disabled = true
	$Sprite.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play('explosion')
	#$ExplodeSound.play()


# If player runs into enemy, explode enemy
func _on_Enemy_body_entered(body):
	if body.name == 'Player':
		body.shield -= 50
		explode()
