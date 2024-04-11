extends CharacterBody2D

## 跑步速度
const RUN_SPEED := 160.0
## 跳跃高度
const JUMP_VELOCITY := -350
## 地面加速度
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
## 空中加速度
const AIR_ACCELERATION := RUN_SPEED / 0.02
## 重力
var gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('jump'):
		jump_request_timer.start()
	if event.is_action_released('jump') and velocity.y < JUMP_VELOCITY / 2:
		# 松开跳跃键时，如果还没有到达 跳跃高度的一半 那么就只跳一半的高度
		velocity.y = JUMP_VELOCITY / 2


func _physics_process(delta: float) -> void:
	# 获取按下的方向 （move_left：-1  move_right：1）
	var dirction := Input.get_axis('move_left', 'move_right')
	# x 轴每秒移动 RUN_SPEED 像素点
	#velocity.x = dirction * RUN_SPEED
	# 运动
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, dirction * RUN_SPEED, acceleration * delta)
	# y 轴每秒移动 （重力 * 每帧的间隔时间）持续累加（越来越快） 像素点
	velocity.y +=  gravity * delta
	
	# 跳跃 当角色站在地板上且按下了跳跃键
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()
		jump_request_timer.stop()
		
	# 动画播放 当玩家站在地面上
	if is_on_floor():
		# 当方向变量为空时说明并没有按下方向键 播放站立动画
		if is_zero_approx(dirction) and velocity.x == 0:
			animation_player.play("idle")
		else:
			# 否则就是有按下方向键 播放跑动动画
			animation_player.play("running")
	else:
		# 如果没有站在地面上 那么就是在天上 播放跳跃动画
		animation_player.play("jump")
	# 更改角色面朝向 水平翻转 当方向键不为空时
	if not is_zero_approx(dirction):
		sprite_2d.flip_h = dirction < 0
	
	# coyoteTimer 当前是在地面上，移动后不在地面上 就开始计时
	var was_on_floor := is_on_floor()

	move_and_slide()
	
	# 判断移动前与移动后是否不同
	if is_on_floor() != was_on_floor:
		# 如果移动前站在地板上且不是主动按下跳跃键，上面if 就说明移动后已经不站在地板上 开启 coyoteTimer
		if was_on_floor and not should_jump:
			coyote_timer.start()
		else:
			coyote_timer.stop()
