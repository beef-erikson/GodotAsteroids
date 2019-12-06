extends Area2D

export (int) var speed
var velocity = Vector2()


# Firing start position
func start(pos, dir):
	position = pos
	rotation = dir
	velocity = Vector2(speed, 0).rotated(dir)


# Updates position every frame based on velocity
func _process(delta):
	position += velocity * delta


# Destroys bullet when it leaves the screen
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()


# Destroy rocks when collision occurs
func _on_Bullet_body_entered(body):
	if body.is_in_group('rocks'):
		body.explode()
		queue_free()
