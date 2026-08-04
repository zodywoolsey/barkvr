extends Control
class_name SettingsMenu

# general settings
@onready var restart_in_vr_button: Button = $ScrollContainer/VBoxContainer/GeneralSettingsMargin/GeneralSettings/RestartInVR/RestartInVR/Button
@onready var laser_smoothing_enabled: Bool_Attribute = %"laser smoothing enabled"
@onready var laser_smoothing_speed: Number_Attribute = %"laser smoothing speed"
@onready var desktop_laser_origin: Enum_Attribute = %"laser origin"

# vr settings
@onready var passthrough_button: Button = $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/Passthrough/Passthrough/Toggle
@onready var passthrough_rect: ColorRect = $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/Passthrough/Passthrough/Toggle/ColorRect
@onready var hand_tracking_button: Button = $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/HandTracking/HandTracking/Toggle
@onready var hand_tracking_rect: ColorRect = $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/HandTracking/HandTracking/Toggle/ColorRect

# ui settings
@onready var local_menu_lookat_x_button: Button = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/XVBox/XVal
@onready var local_menu_lookat_x_rect: ColorRect = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/XVBox/XVal/ColorRect
@onready var local_menu_lookat_y_button: Button = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/YVbox/YVal
@onready var local_menu_lookat_y_rect: ColorRect = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/YVbox/YVal/ColorRect
@onready var local_menu_lookat_z_button: Button = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/ZVbox/ZVal
@onready var local_menu_lookat_z_rect: ColorRect = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/ZVbox/ZVal/ColorRect
@onready var inspector_as_singleton: Bool_Attribute = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/InspectorAsSingleton
@onready var inspector_update_interval_spinbox: SpinBox = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/InspectorUpdateInterval/SpinBox
@onready var vr_notification_size_value: SpinBox = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/VRNotificationSize/VRNotificationSizeValue
@onready var vr_notification_offset: Vector2_Attribute = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/VRNotificationOffset/VRNotificationOffset
@onready var vr_notification_test: Button = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/VRNotificationTest/VRNotificationTest
@onready var interface_scaling_factor: Number_Attribute = $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/InterfaceScalingFactor
@onready var screen_space_anti_aliasing: Enum_Attribute = $ScrollContainer/VBoxContainer/GraphicsMargin/Graphics/ScreenSpaceAntiAliasing
@onready var viewport_disable_3d: Bool_Attribute = %ViewportDisable3d

# chat settings
@onready var ctrl_enter_button: Button = $ScrollContainer/VBoxContainer/ChatSettingsMargin/ChatSettings/CtrlEnter/Toggle

# graphics settings
@onready var scaling_slider: HSlider = $ScrollContainer/VBoxContainer/GraphicsMargin/Graphics/ViewportScaling/HSlider
@onready var anti_aliasing_dropdown: OptionButton = ($ScrollContainer/VBoxContainer/GraphicsMargin/Graphics/AntiAliasing as Enum_Attribute).val
@onready var anti_aliasing_control: Enum_Attribute = $ScrollContainer/VBoxContainer/GraphicsMargin/Graphics/AntiAliasing

func set_button(button_ref: Button, rect_ref: ColorRect, toggled_on: bool, on_color: Color) -> void:
	button_ref.button_pressed = toggled_on
	button_ref.text = "is enabled" if toggled_on else "is disabled"
	rect_ref.color = on_color if toggled_on else Color.GRAY

func tween_button(button_ref: Button, rect_ref: ColorRect, toggled_on: bool, on_color: Color) -> void:
	create_tween().tween_property(button_ref, ^"text", "is enabled" if toggled_on else "is disabled", 0.5)
	create_tween().tween_property(rect_ref, ^"color", on_color if toggled_on else Color.GRAY, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _ready() -> void:
	#anti_aliasing_control.set_data("3d anti aliasing", get_window(), "msaa_3d", {})
	anti_aliasing_control.label.text = "Anti Aliasing"
	anti_aliasing_control.property_name = "msaa_3d"
	anti_aliasing_control.val.add_item("MSAA_DISABLED")
	anti_aliasing_control.val.add_item("MSAA_2X")
	anti_aliasing_control.val.add_item("MSAA_4X")
	anti_aliasing_control.val.add_item("MSAA_8X")
	anti_aliasing_control.val.add_item("MSAA_MAX")
	anti_aliasing_control.target = get_window()
	
	if LocalGlobals.vr_supported:
		($ScrollContainer/VBoxContainer/GeneralSettingsMargin/GeneralSettings/RestartInVR as VBoxContainer).hide()
	var settings_singleton: SettingsSingleton = Engine.get_singleton("settings_manager")
	if settings_singleton:
		set_button(passthrough_button, passthrough_rect, settings_singleton.vr_passthrough, Color.GREEN)
		set_button(hand_tracking_button, hand_tracking_rect, settings_singleton.hand_tracking_enabled, Color.GREEN)
		set_button(local_menu_lookat_x_button, local_menu_lookat_x_rect, settings_singleton.ui_local_menu_lookat_x, Color.RED)
		set_button(local_menu_lookat_y_button, local_menu_lookat_y_rect, settings_singleton.ui_local_menu_lookat_y, Color.GREEN)
		set_button(local_menu_lookat_z_button, local_menu_lookat_z_rect, settings_singleton.ui_local_menu_lookat_z, Color.BLUE)
		ctrl_enter_button.button_pressed = settings_singleton.send_messages_with_ctrl_enter
		ctrl_enter_button.text = "is enabled" if settings_singleton.send_messages_with_ctrl_enter else "is disabled"
		inspector_update_interval_spinbox.value = settings_singleton.inspector_update_interval
		vr_notification_size_value.value = settings_singleton.vr_notification_size
		vr_notification_offset.set_data("VR Notification Offset", settings_singleton, "vr_notification_offset")
		interface_scaling_factor.set_data("Interface Scaling Factor", settings_singleton, "interface_scaling_factor")
		screen_space_anti_aliasing.set_data("Scren Space Anti Aliasing", settings_singleton, "screen_space_anti_aliasing", {"hint_string":"Disabled, FXAA_Enabled"})
		(viewport_disable_3d as Bool_Attribute).set_data("Disable 3D", settings_singleton, "viewport_disable_3d")
		inspector_as_singleton.call_deferred("set_data","Inspector As Singleton", settings_singleton, "inspector_as_singleton")
		laser_smoothing_enabled.set_data("Laser Smoothing Enabled", settings_singleton, "laser_smoothing")
		laser_smoothing_speed.set_data("Laser Smoothing Speed", settings_singleton, "laser_smoothing_speed")
		desktop_laser_origin.set_data("Laser Origin", settings_singleton, "desktop_laser_origin", {"hint_string":"Left Hand, Right Hand, Head"})
		vr_notification_test.pressed.connect(test_vr_notification)
		scaling_slider.value = settings_singleton.viewport_scaling
		anti_aliasing_dropdown.selected = settings_singleton.anti_aliasing
	
	restart_in_vr_button.pressed.connect(restart_in_vr)
	passthrough_button.toggled.connect(toggle_vr_passthrough)
	hand_tracking_button.toggled.connect(toggle_hand_tracking)
	local_menu_lookat_x_button.toggled.connect(toggle_local_menu_lookat_x)
	local_menu_lookat_y_button.toggled.connect(toggle_local_menu_lookat_y)
	local_menu_lookat_z_button.toggled.connect(toggle_local_menu_lookat_z)
	inspector_update_interval_spinbox.value_changed.connect(inspector_update_interval_changed)
	vr_notification_size_value.value_changed.connect(vr_notification_size_changed)
	
	ctrl_enter_button.toggled.connect(toggle_ctrl_enter)
	scaling_slider.value_changed.connect(viewport_scaling_slider_changed)
	anti_aliasing_dropdown.item_selected.connect(anti_aliasing_changed)

func test_vr_notification():
	Notifyvr.send_notification("what would you do if your crush walked up to you and barked *cutely* and then stared at you lovingly")

func restart_in_vr() -> void:
	var args := OS.get_cmdline_args()
	args.append("--xr-mode on")
	OS.set_restart_on_exit(true, PackedStringArray(args))
	if OS.is_restart_on_exit_set():
		get_tree().quit(0)

func toggle_vr_passthrough(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).vr_passthrough = toggled_on
		tween_button(passthrough_button, passthrough_rect, toggled_on, Color.GREEN)

func toggle_hand_tracking(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).hand_tracking_enabled = toggled_on
		tween_button(hand_tracking_button, hand_tracking_rect, toggled_on, Color.GREEN)

func toggle_local_menu_lookat_x(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).ui_local_menu_lookat_x = toggled_on
		tween_button(local_menu_lookat_x_button, local_menu_lookat_x_rect, toggled_on, Color.RED)

func toggle_local_menu_lookat_y(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).ui_local_menu_lookat_y = toggled_on
		tween_button(local_menu_lookat_y_button, local_menu_lookat_y_rect, toggled_on, Color.GREEN)

func toggle_local_menu_lookat_z(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).ui_local_menu_lookat_z = toggled_on
		tween_button(local_menu_lookat_z_button, local_menu_lookat_z_rect, toggled_on, Color.BLUE)

func toggle_ctrl_enter(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).send_messages_with_ctrl_enter = toggled_on
		create_tween().tween_property(ctrl_enter_button, ^"text", "is enabled" if toggled_on else "is disabled", 0.5)

func inspector_update_interval_changed(value: float) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).inspector_update_interval = value
		

func vr_notification_size_changed(value: float) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).vr_notification_size = value
		

func vr_notification_offset_changed(value: Vector2) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).vr_notification_offset = value
		

func anti_aliasing_changed(index: int) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).anti_aliasing = index

func viewport_scaling_slider_changed(value: float) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).viewport_scaling = value
