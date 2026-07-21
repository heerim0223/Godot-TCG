extends CanvasLayer

const DISPLAY_TIME = 0.9
const FADE_TIME = 0.5

@onready var label: RichTextLabel = $StartLabel

func _ready() -> void:
	# 강제로 보이게 설정
	visible = true
	label.visible = true
	label.modulate = Color(1, 1, 1, 1)
	label.scale = Vector2(0.8, 0.8)
	label.pivot_offset = label.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(DISPLAY_TIME)
	tween.tween_property(label, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
	
	print("GameStartUI: 배틀 시작 UI 표시됨")  # 디버그용
