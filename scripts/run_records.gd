extends Node

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "RunRecords"
const KEY_BEST := "best_survival_seconds"


func format_mm_ss(total_seconds: float) -> String:
	if total_seconds < 0.0:
		return "--:--"
	var t := int(floor(total_seconds))
	var mm := t / 60
	var ss := t % 60
	return "%d:%02d" % [mm, ss]


func load_best_survival_seconds() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return -1.0
	if not cfg.has_section_key(SECTION, KEY_BEST):
		return -1.0
	return float(cfg.get_value(SECTION, KEY_BEST))


func record_best_if_better(run_seconds: float) -> void:
	var run := float(int(floor(run_seconds)))
	var current := load_best_survival_seconds()
	if current >= 0.0 and run <= current:
		return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SECTION, KEY_BEST, run)
	cfg.save(SETTINGS_PATH)


## Alias used by `main.gd` / pause flow (same persistence as `record_best_if_better`).
func commit_best_if_greater(run_seconds: float) -> void:
	record_best_if_better(run_seconds)
