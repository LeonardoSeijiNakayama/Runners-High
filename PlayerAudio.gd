extends Node

onready var audio: AudioStreamPlayer = $"../AudioPlayer"
onready var Player = get_parent()

const JOGGING_AUDIO : AudioStream = preload("res://audios/walking-sound-effect-272246.mp3")
const JUMPING_AUDIO : AudioStream = preload("res://audios/grunt-106134.mp3")
const SLIDING_AUDIO : AudioStream = preload("res://audios/sliding-sound-103631.ogg")
const SWINGING_AUDIO : AudioStream = preload("res://audios/wind-blowing-457954.mp3")

var last_state := -1
var last_slipped := false


func _ready():
	audio.stop()


func update(state: int, slipped: bool) -> void:
	if slipped != last_slipped:
		last_slipped = slipped
		if slipped:
			audio.stop()
		else:
			last_state = -1
	
	if slipped:
		return
	
	if state == last_state:
		return
	
	last_state = state
	
	match state:
		Player.JOGGING:
			audio.volume_db = -20
			_play_loop(JOGGING_AUDIO, 1.0)
		
		Player.RUNNING:
			audio.volume_db = -20
			_play_loop(JOGGING_AUDIO, 1.5)
		
		Player.JUMPING, Player.JOGGING_JUMP, Player.RUNNING_JUMP:
			audio.volume_db = -10
			_play_one_shot(JUMPING_AUDIO, 1.0)
	
		Player.WALLRUNNING_LEFT, Player.WALLRUNNING_RIGHT:
			audio.volume_db = -20
			_play_loop(SLIDING_AUDIO, 2.0)
	
		Player.SWINGING, Player.FALLING, Player.ASCENDING:
			audio.volume_db = -15
			_play_loop(SWINGING_AUDIO, 1.0)
		_:
			audio.stop()


func _play_loop(stream: AudioStream, pitch: float) -> void:
	if audio.stream == stream and audio.playing:
		audio.pitch_scale = pitch
		return
	
	audio.stop()
	audio.stream = stream
	_set_loop(audio.stream, true)
	audio.pitch_scale = pitch
	audio.play()



func _play_one_shot(stream: AudioStream, pitch:float) -> void:
	audio.stop()
	audio.stream = stream
	audio.pitch_scale = pitch
	_set_loop(audio.stream, false)
	audio.play()


func _set_loop(stream: AudioStream, enabled: bool) -> void:
	if stream != null and "loop" in stream:
		stream.loop = enabled
		if "loop_offset" in stream:
			stream.loop_offset = 0.0


