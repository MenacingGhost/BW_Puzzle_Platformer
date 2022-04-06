extends KinematicBody2D

export var gravity = 1500
export var acceleration = 2000
export var deacceleration = 2000
export var friction = 2000
export var current_friction = 2000
export var max_horizontal_speed = 400
export var max_fall_speed = 1000
export var jump_height = -600

var vSpeed = 0
var hSpeed = 0
var count = 0

var motion = Vector2.ZERO
var UP : Vector2 = Vector2(0,-1)

onready var ani = $AnimatedSprite

var recorded_data = [] # this is our array we update when moving, check when recording
var is_rewinding = false # we'll use this to disable this object when true. so we can add recorded data to it
var rewind_length = (60 * 500) # 180 this is 3seconds running at 60fps
var rewind_ghost = load("res://objects/rewind_ghost.tscn") # direct to a sprite we'll use as a ghost
var do_rewind = false
var jump_counter = 0
var anti_gravity = false
var equid = false
var jetpack_boost = false
var movable = true

onready var tween_out = get_node("Tween")

export var transition_duration = 1.00
export var transition_type = 1 

func fade_out(stream_player):
	tween_out.interpolate_property(stream_player, "volume_db", -7.5, -80, transition_duration, transition_type, Tween.EASE_IN, 0)
	tween_out.start()

func _on_TweenOut_tween_completed(object, key):
	object.stop()

func handle_rewind_function():
	var ani_number = ani.get_index()
	var dir_number = 0

	if(do_rewind): # DO REWIND
		is_rewinding = true

		if(recorded_data.size() > 0):
			var current_frame = recorded_data[0]
			
			#Set our values to the first frame of the array
			if(current_frame != null):
				ani.animation = current_frame[0]
				global_position = current_frame[1]
				ani.flip_h = current_frame[2]
				
				var ghost : Sprite = rewind_ghost.instance()
				ghost.texture = ani.frames.get_frame(ani.animation,ani.frame)
				ghost.global_position = global_position
				ghost.flip_h = ani.flip_h
				get_parent().add_child(ghost)
				
			#remove thet first frame as we've just used it
			recorded_data.pop_front()
			
	else: # WE are recording
		is_rewinding = false
		
		if(ani.flip_h):
			dir_number = 1
		else:
			dir_number = 0
		
		recorded_data.push_front([ani.animation,global_position,ani.flip_h])
		if(recorded_data.size() > rewind_length): #our record is longer than 3 secs, remove last frame
			recorded_data.pop_back()

func _physics_process(delta):
	handle_rewind_function()
	if(is_rewinding):
		Engine.time_scale = 0.5
	if(!is_rewinding):
		Engine.time_scale = 1
		check_ground_logic()
		if(movable):
			handle_movement(delta)
		do_physics(delta)
	else:
		hSpeed = 0
		vSpeed = 0
	pass
		
func check_ground_logic():
	pass
	
func do_physics(delta):
	if(is_on_ceiling()):
		motion.y = 10
		vSpeed = 10
		
	vSpeed += (gravity * delta) # apply gravity downwards
	vSpeed = min(vSpeed,max_fall_speed) # limit how fast we can fall
	
	#update our motion vector
	motion.y = vSpeed
	motion.x = hSpeed
	
	
		
	
	#apply our motion vectgor to move and slide
	motion = move_and_slide(motion,UP)
	
	pass
	
func handle_movement(var delta):
	if(movable):
		if(anti_gravity):
			gravity = -1500
			ani.flip_v = true
		else:
			gravity = 1500
			ani.flip_v = false
			
		if(is_on_wall()):
			hSpeed = 0
			motion.x = 0
		if is_on_floor():
			jump_counter = 0
			vSpeed = 0
			motion.y = 0
		else:
			if(!anti_gravity):
				
				ani.play("JUMP")
		#controller right/keyboard right
		if(Input.is_action_just_pressed("c")):
			if(ani.flip_h == false):
				hSpeed = 700
			else:
				hSpeed = -700
				
		if(Input.get_joy_axis(0,0) > 0.3 or Input.is_action_pressed("ui_right")):
			if(hSpeed <-100):
				hSpeed += (deacceleration * delta)
				#if(touching_ground):
			#		ani.play("TURN")
			elif(hSpeed < max_horizontal_speed):
				hSpeed += (acceleration * delta)
				ani.flip_h = false
				if(anti_gravity):
					if(is_on_ceiling()):
						ani.play("RUN")
					
				if is_on_floor():
					ani.play("RUN")
			else:
				if is_on_floor():
					ani.play("RUN")
		elif(Input.get_joy_axis(0,0) < -0.3 or Input.is_action_pressed("ui_left")):
			if(hSpeed > 100):
				hSpeed -= (deacceleration * delta)
				#if(touching_ground):
			#		ani.play("TURN")
			elif(hSpeed > -max_horizontal_speed):
				hSpeed -= (acceleration * delta)
				ani.flip_h = true
				if is_on_floor():
					ani.play("RUN")
			else:
				if is_on_floor():
					ani.play("RUN")
		else:
			if is_on_floor():
				ani.play("IDLE")
			if anti_gravity:
				if(is_on_ceiling()):
					ani.play("IDLE")
			hSpeed -= min(abs(hSpeed),current_friction * delta) * sign(hSpeed)
			
		
		if not jetpack_boost:
			if(Input.is_action_just_pressed("ui_accept")) && jump_counter < 1 || Input.is_action_just_pressed("ui_up") and jump_counter < 1:
					vSpeed = jump_height
					jump_counter += 1
		else:
			if (Input.is_action_just_pressed("ui_accept")) && jump_counter < 2 || Input.is_action_just_pressed("ui_up") and jump_counter < 2:
				vSpeed = jump_height
				jump_counter += 1
			
		
		if(equid):
			if Input.is_action_just_pressed("e"):
				anti_gravity = not anti_gravity
	else:
		ani.play("IDLE")

func _on_Timer_timeout():
	do_rewind = true
	$AudioStreamPlayer.play()

func _on_Norewind_body_entered(body):
	do_rewind = false
	anti_gravity = false

func _on_anti_gravity_boots_body_entered(body):
	if "player" in body.name:
		equid = true
		anti_gravity = true


func _on_detector_body_entered(body):
	if "flying enemy" in body.name:
		$DeathTimer.start()
		fade_out($theme)
		movable = false
		hSpeed = 0
		ani.play("IDLE")
		




func _on_DeathTimer_timeout():
	get_tree().reload_current_scene()
