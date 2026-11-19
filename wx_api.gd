extends Node
## 微信小游戏能力桥接（自动加载单例：Wx）
##
## 接口由小游戏工程里的 `wx-bridge.js` 提供（`game.js` 第一行 import），
## GDScript 这边通过 `JavaScriptBridge.get_interface("__GodotWx")` 拿到它，
## 和模板里访问 `GODOTSDK` 是同一套方式。
##
## 为什么不用 eval 自注入：微信小游戏的 `window` 是 weapp-adapter 伪造的对象，
## 和真正的全局（`GameGlobal` / `globalThis`）不是同一个，eval 里挂上去的接口
## 和 get_interface 查找的对象对不上，实测会报 "No interface '__GodotWx' registered"。
##
## 用法：
##   Wx.login()
##   Wx.login_succeeded.connect(func(code): print(code))

signal login_succeeded(code: String)
signal login_failed(message: String)

var _api = null
var _last_code := ""


## 是否运行在微信小游戏环境（Web 平台、桥接就绪、且宿主提供了 wx）
func is_wechat_environment() -> bool:
	if not OS.has_feature("web"):
		return false
	var info := probe()
	return bool(info.get("hasWx", false))


## 诊断信息：hasWx / hasGameGlobal / windowIsGlobal / rootIsGlobal
func probe() -> Dictionary:
	var api = _ensure_api()
	if api == null:
		return { "error": "no-interface" }
	var parsed = _parse(str(api.probe()))
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return { "raw": str(parsed) }


## 上次登录拿到的 code（需要后端调用 code2session 换取 openid）
func get_last_code() -> String:
	return _last_code


## 拉起微信登录：成功时发出 login_succeeded(code)，失败时发出 login_failed(message)
func login() -> void:
	if not OS.has_feature("web"):
		_simulate_login()
		return

	var api = _ensure_api()
	if api == null:
		login_failed.emit("找不到 __GodotWx 接口：确认小游戏工程 game.js 第一行是 import './wx-bridge'")
		return

	var info := probe()
	print("[Wx] probe = ", info)

	if not bool(info.get("hasWx", false)):
		login_failed.emit("当前宿主没有 wx，无法调用微信登录（probe=%s）" % JSON.stringify(info))
		return

	print("[Wx] login -> ", str(api.login()))
	await _poll_login(api)


## 轻提示，非微信环境只在控制台打印
func show_toast(text: String) -> void:
	if not OS.has_feature("web"):
		print("[Wx] toast: ", text)
		return
	var api = _ensure_api()
	if api != null:
		api.toast(text)


## 拿到宿主注入的 __GodotWx 接口（wx-bridge.js 提供）
func _ensure_api():
	if _api != null:
		return _api
	if not OS.has_feature("web"):
		return null
	_api = JavaScriptBridge.get_interface("__GodotWx")
	if _api == null:
		push_warning("[Wx] get_interface('__GodotWx') 返回空，wx-bridge.js 可能没有加载")
	return _api


func _parse(raw: String):
	if raw.is_empty():
		return null
	return JSON.parse_string(raw)


func _poll_login(api) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.15).timeout
		var parsed = _parse(str(api.poll()))
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var status := str(parsed.get("status", ""))
		if status == "ok":
			_last_code = str(parsed.get("code", ""))
			print("[Wx] wx.login 成功，code = ", _last_code)
			login_succeeded.emit(_last_code)
			return
		if status == "fail":
			var message := str(parsed.get("errMsg", "wx.login 失败"))
			push_warning("[Wx] wx.login 失败：%s" % message)
			login_failed.emit(message)
			return
	login_failed.emit("wx.login 超时，10 秒内没有回调")


## 编辑器 / 桌面环境的模拟登录，保证本地也能把流程走通
func _simulate_login() -> void:
	print("[Wx] 当前不是微信小游戏环境，使用模拟登录")
	await get_tree().create_timer(0.3).timeout
	_last_code = "mock_code_%d" % Time.get_unix_time_from_system()
	login_succeeded.emit(_last_code)
