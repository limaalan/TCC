extends Control

const DAMAGE_ICON := preload("res://ui/hud/icons/mine-explosion.png")
const FIRE_RATE_ICON := preload("res://ui/hud/icons/supersonic-bullet.png")

@onready var icon: TextureRect = $Icon
@onready var countdown: TextureProgressBar = $Countdown
@onready var time_label: Label = $TimeLabel

var duration_sec := 0.0
var ends_at_ms := 0


func start_buff(powerup_type: int, new_duration_sec: float) -> void:
	var powerup_icon := get_powerup_icon(powerup_type)
	if powerup_icon == null:
		return

	icon.texture = powerup_icon
	countdown.texture_progress = powerup_icon
	duration_sec = maxf(new_duration_sec, 0.01)
	ends_at_ms = Time.get_ticks_msec() + roundi(duration_sec * 1000.0)
	visible = true
	update_countdown()
	set_process(true)


func _process(_delta: float) -> void:
	update_countdown()


func update_countdown() -> void:
	var remaining_sec := maxf((ends_at_ms - Time.get_ticks_msec()) / 1000.0, 0.0)
	countdown.value = (remaining_sec / duration_sec) * countdown.max_value
	time_label.text = "%.1fs" % remaining_sec

	if remaining_sec <= 0.0:
		set_process(false)


func get_powerup_icon(powerup_type: int) -> Texture2D:
	match powerup_type:
		GameEnums.PowerupType.DAMAGE:
			return DAMAGE_ICON
		GameEnums.PowerupType.FIRE_RATE:
			return FIRE_RATE_ICON

	return null
