extends CanvasLayer

signal start_game

# Shield HUD support pre-loading
onready var ShieldBar = $MarginContainer/HBoxContainer/ShieldBar
var red_bar = preload('res://assets/barHorizontal_red_mid 200.png')
var green_bar = preload('res://assets/barHorizontal_green_mid 200.png')
var yellow_bar = preload('res://assets/barHorizontal_yellow_mid 200.png')

# Array to hold the lives images
onready var lives_counter = [$MarginContainer/HBoxContainer/LivesCounter/L1,
							 $MarginContainer/HBoxContainer/LivesCounter/L2,
							 $MarginContainer/HBoxContainer/LivesCounter/L3]


# Updates the main message label
func show_message(message):
	$MessageLabel.text = message
	$MessageLabel.show()
	$MessageTimer.start()


# Updates the score label
func update_score(value):
	$MarginContainer/HBoxContainer/ScoreLabel.text = str(value)


# Updates lives
func update_lives(value):
	for item in range(3):
		lives_counter[item].visible = value > item


# Game over state
func game_over():
	show_message("Game Over")
	yield($MessageTimer, 'timeout')
	$StartButton.show()


# Start button pressed
func _on_StartButton_pressed():
	$StartButton.hide()
	emit_signal('start_game')


# Message timer expired
func _on_MessageTimer_timeout():
	$MessageLabel.hide()
	$MessageLabel.text = ''


# Updates shield bar color based on current value
func update_shield(value):
	value *= 100
	ShieldBar.texture_progress = green_bar
	if value < 40:
		ShieldBar.texture_progress = red_bar
	elif value < 70:
		ShieldBar.texture_progress = yellow_bar
	
	ShieldBar.value = value