extends Node2D

@onready var login_button: Button = $CanvasLayer/UI/VBox/LoginButton
@onready var status_label: Label = $CanvasLayer/UI/VBox/StatusLabel


func _ready() -> void:
	login_button.pressed.connect(_on_login_button_pressed)
	Wx.login_succeeded.connect(_on_login_succeeded)
	Wx.login_failed.connect(_on_login_failed)

	if Wx.is_wechat_environment():
		status_label.text = "检测到微信小游戏环境，点击按钮登录"
	else:
		status_label.text = "非微信环境（编辑器/桌面），点击按钮走模拟登录"


func _on_login_button_pressed() -> void:
	print("hello")

	login_button.disabled = true
	login_button.text = "登录中..."
	status_label.text = "正在调用 wx.login ..."

	Wx.login()


func _on_login_succeeded(code: String) -> void:
	print("登录成功，code = ", code)
	login_button.text = "已登录"
	status_label.text = "登录成功\ncode: %s" % code
	Wx.show_toast("登录成功")


func _on_login_failed(message: String) -> void:
	push_warning("登录失败：%s" % message)
	login_button.disabled = false
	login_button.text = "重新登录"
	status_label.text = "登录失败：%s" % message
	Wx.show_toast("登录失败")
