extends Control

const CONFIG_PATH := "res://ui/credits_screen/credits.cfg"
const MAIN_MENU_PATH := "res://ui/main_menu/main_menu.tscn"

@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var project_heading_label: Label = %ProjectHeadingLabel
@onready var project_name_label: Label = %ProjectNameLabel
@onready var project_description_label: Label = %ProjectDescriptionLabel
@onready var academic_heading_label: Label = %AcademicHeadingLabel
@onready var institution_label: Label = %InstitutionLabel
@onready var campus_label: Label = %CampusLabel
@onready var course_label: Label = %CourseLabel
@onready var author_label: Label = %AuthorLabel
@onready var advisor_label: Label = %AdvisorLabel
@onready var year_label: Label = %YearLabel
@onready var thanks_heading_label: Label = %ThanksHeadingLabel
@onready var thanks_groups_container: GridContainer = %ThanksGroupsContainer
@onready var thanks_message_label: Label = %ThanksMessageLabel
@onready var technologies_heading_label: Label = %TechnologiesHeadingLabel
@onready var technologies_items_label: Label = %TechnologiesItemsLabel
@onready var source_icon_label: Label = %SourceIconLabel
@onready var source_heading_label: Label = %SourceHeadingLabel
@onready var repository_button: Button = %RepositoryButton
@onready var closing_message_label: Label = %ClosingMessageLabel
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var scroll_caret: Label = %ScrollCaret

var _repository_url := ""


func _ready() -> void:
	_load_content()
	back_button.call_deferred("grab_focus")
	resized.connect(_update_responsive_layout)

	var scroll_bar := scroll_container.get_v_scroll_bar()
	scroll_bar.changed.connect(_update_scroll_caret)
	scroll_bar.value_changed.connect(_on_scroll_value_changed)
	call_deferred("_update_responsive_layout")
	call_deferred("_update_scroll_caret")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ClientNames.INPUT_UI_CANCEL):
		_return_to_main_menu()
		get_viewport().set_input_as_handled()


func _load_content() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if error != OK:
		push_error("Não foi possível carregar os créditos em %s (erro %s)." % [CONFIG_PATH, error])
		return

	title_label.text = config.get_value("screen", "title", "CRÉDITOS")
	back_button.text = config.get_value("screen", "back_button", "←  Voltar")
	scroll_caret.text = config.get_value("screen", "scroll_hint", "⌄")
	closing_message_label.text = config.get_value("screen", "closing_message", "Obrigado por jogar!")

	project_heading_label.text = config.get_value("project", "heading", "PROJETO")
	project_name_label.text = config.get_value("project", "name", "")
	project_description_label.text = config.get_value("project", "description", "")

	academic_heading_label.text = config.get_value("academic", "heading", "ACADÊMICO")
	institution_label.text = config.get_value("academic", "institution", "")
	campus_label.text = config.get_value("academic", "campus", "")
	course_label.text = config.get_value("academic", "course", "")
	author_label.text = "%s: %s" % [
		config.get_value("academic", "author_label", "Autor"),
		config.get_value("academic", "author", ""),
	]
	advisor_label.text = "%s: %s" % [
		config.get_value("academic", "advisor_label", "Orientador"),
		config.get_value("academic", "advisor", ""),
	]
	year_label.text = str(config.get_value("academic", "year", ""))

	thanks_heading_label.text = config.get_value("thanks", "heading", "AGRADECIMENTOS")
	_populate_thanks_groups(config)
	thanks_message_label.text = config.get_value("thanks", "message", "")
	technologies_heading_label.text = config.get_value("technologies", "heading", "TECNOLOGIAS E FERRAMENTAS")
	technologies_items_label.text = _format_inline_list(
		config.get_value("technologies", "items", PackedStringArray())
	)

	source_icon_label.text = config.get_value("source", "code_icon", "</>")
	source_heading_label.text = config.get_value("source", "heading", "CÓDIGO-FONTE")
	repository_button.text = config.get_value("source", "repository_label", "limaalan/TCC   ›")
	_repository_url = config.get_value(
		"source",
		"repository_url",
		"https://github.com/limaalan/TCC",
	)
	repository_button.tooltip_text = _repository_url


func _populate_thanks_groups(config: ConfigFile) -> void:
	for child in thanks_groups_container.get_children():
		child.queue_free()

	var group_sections: PackedStringArray = config.get_value(
		"thanks",
		"groups",
		PackedStringArray(),
	)
	for section_name in group_sections:
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 2)

		var group_title := Label.new()
		group_title.text = config.get_value(section_name, "title", "")
		group_title.add_theme_color_override("font_color", Color(0.82, 0.42, 0.01))
		group_title.add_theme_font_size_override("font_size", 16)
		group.add_child(group_title)

		var names_label := Label.new()
		var thankful_to: PackedStringArray = config.get_value(
			section_name,
			"thankful_to",
			PackedStringArray(),
		)
		names_label.text = "\n".join(thankful_to)
		names_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		group.add_child(names_label)

		thanks_groups_container.add_child(group)


func _update_responsive_layout() -> void:
	var compact_layout := size.x < 900.0
	thanks_groups_container.columns = 1 if compact_layout else 2

	var available_group_width := clampf(size.x - 180.0, 220.0, 400.0)
	for group in thanks_groups_container.get_children():
		group.custom_minimum_size.x = available_group_width

	repository_button.custom_minimum_size.x = clampf(size.x - 180.0, 240.0, 500.0)


func _format_inline_list(items: PackedStringArray) -> String:
	return "  •  ".join(items)


func _update_scroll_caret() -> void:
	var scroll_bar := scroll_container.get_v_scroll_bar()
	var end_value := scroll_bar.max_value - scroll_bar.page
	scroll_caret.visible = end_value > 1.0 and scroll_bar.value < end_value - 1.0


func _on_scroll_value_changed(_value: float) -> void:
	_update_scroll_caret()


func _on_back_button_pressed() -> void:
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)
	_return_to_main_menu()


func _on_repository_button_pressed() -> void:
	if _repository_url.is_empty():
		push_warning("O endereço do repositório não foi configurado.")
		return

	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)
	var error := OS.shell_open(_repository_url)
	if error != OK:
		push_warning("Não foi possível abrir o repositório (erro %s)." % error)


func _return_to_main_menu() -> void:
	get_tree().call_group(
		ClientNames.GROUP_LOCAL_GAME_SCENE_MANAGER,
		ClientNames.METHOD_CHANGE_SCENE,
		MAIN_MENU_PATH,
	)
