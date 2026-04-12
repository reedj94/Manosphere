extends Node

## Global game state singleton. Tracks player stats, quest progress,
## region unlocks, and pyramid tier across the entire session.

signal pyramid_tier_changed(new_tier: int)
signal region_unlocked(region_name: String)
signal stat_changed(stat_name: String, new_value: float)
signal game_time_advanced(new_hour: int)

enum Region { CONSETT, LONDON, MIAMI, DUBAI }
enum PyramidTier {
	WAGE_SLAVE = 1,
	SIDE_HUSTLER = 2,
	GRINDSET_APPRENTICE = 3,
	SIGMA_IN_TRAINING = 4,
	CONTENT_CREATOR = 5,
	HUSTLE_MERCHANT = 6,
	INTERNATIONAL_PLAYER = 7,
	ALPHA_PROSPECT = 8,
	CRYPTO_LORD = 9,
	KING_OF_MANOSPHERE = 10
}

# Player identity
var player_name: String = ""
var player_appearance: Dictionary = {}
var real_one_gender: String = "female"  # player-selected at start
var real_one_romance: bool = false

# Core stats
var cash: float = 0.0
var respect: int = 0
var clout: int = 0
var testosterone_level: float = 0.0
var hustle_knowledge: int = 0
var pyramid_tier: int = PyramidTier.WAGE_SLAVE

# Debt system
var debt: float = 0.0
var grotty_bailouts_used: int = 0
const MAX_GROTTY_BAILOUTS: int = 3

# Region state
var current_region: Region = Region.CONSETT
var unlocked_regions: Array[Region] = [Region.CONSETT]

# Time system (real-time with skip)
var game_hour: int = 8  # 0-23
var game_day: int = 1
var is_day: bool = true

# Quest tracking
var active_quests: Array[String] = []
var completed_quests: Array[String] = []
var quest_choices: Dictionary = {}  # quest_id -> choice_id for branching

# Skill trees
var hustle_tree_points: int = 0
var clout_tree_points: int = 0
var alpha_tree_points: int = 0
var unlocked_skills: Array[String] = []

# Awareness (hidden stat — affected by library books, The Real One, etc.)
var awareness: int = 0

# Scammagram
var scammagram_followers: int = 0
var scammagram_posts: Array[Dictionary] = []

# Ending trackers
var karma: int = 0  # positive = ethical, negative = exploitative
var grotty_trust: int = 50  # 0-100
var real_one_relationship: int = 0  # 0-100

# Co-op
var is_host: bool = true
var co_op_mode: String = "shared_journey"  # or "parallel_hustles"
var connected_players: Array[int] = []


func _ready() -> void:
	pass


func add_cash(amount: float) -> void:
	cash += amount
	if cash < 0:
		_handle_bankruptcy()
	stat_changed.emit("cash", cash)


func add_respect(amount: int) -> void:
	respect += amount
	stat_changed.emit("respect", respect)
	_check_pyramid_advancement()


func add_clout(amount: int) -> void:
	clout += amount
	scammagram_followers += amount * 10
	stat_changed.emit("clout", clout)


func _handle_bankruptcy() -> void:
	if grotty_bailouts_used < MAX_GROTTY_BAILOUTS:
		grotty_bailouts_used += 1
		cash = 500.0
		debt += 500.0
		# TODO: trigger Grotty Green bailout cutscene
	else:
		debt += abs(cash)
		cash = 0.0
		# TODO: trigger debt collector chase / forced odd jobs


func _check_pyramid_advancement() -> void:
	var new_tier := pyramid_tier
	# Tier requirements from GDD
	if cash >= 5_000_000 and respect >= 25_000:
		new_tier = PyramidTier.CRYPTO_LORD
	elif cash >= 1_000_000 and respect >= 10_000:
		new_tier = PyramidTier.ALPHA_PROSPECT
	elif cash >= 250_000 and respect >= 5_000:
		new_tier = PyramidTier.INTERNATIONAL_PLAYER
	elif cash >= 100_000 and respect >= 2_500:
		new_tier = PyramidTier.HUSTLE_MERCHANT
	elif cash >= 25_000 and respect >= 1_000 and clout >= 5_000:
		new_tier = PyramidTier.CONTENT_CREATOR
	elif cash >= 10_000 and respect >= 500:
		new_tier = PyramidTier.SIGMA_IN_TRAINING
	elif cash >= 2_000 and respect >= 200:
		new_tier = PyramidTier.GRINDSET_APPRENTICE
	elif cash >= 500 and respect >= 50:
		new_tier = PyramidTier.SIDE_HUSTLER

	if new_tier > pyramid_tier:
		pyramid_tier = new_tier
		pyramid_tier_changed.emit(new_tier)
		_check_region_unlock()


func _check_region_unlock() -> void:
	if pyramid_tier >= PyramidTier.SIGMA_IN_TRAINING and Region.LONDON not in unlocked_regions:
		unlocked_regions.append(Region.LONDON)
		region_unlocked.emit("London")
	if pyramid_tier >= PyramidTier.INTERNATIONAL_PLAYER and Region.MIAMI not in unlocked_regions:
		unlocked_regions.append(Region.MIAMI)
		region_unlocked.emit("Miami")
	if pyramid_tier >= PyramidTier.CRYPTO_LORD and Region.DUBAI not in unlocked_regions:
		unlocked_regions.append(Region.DUBAI)
		region_unlocked.emit("Dubai")


func advance_time(hours: int = 1) -> void:
	game_hour = (game_hour + hours) % 24
	if game_hour < 6 or game_hour >= 22:
		is_day = false
	else:
		is_day = true
	game_time_advanced.emit(game_hour)


func get_save_data() -> Dictionary:
	return {
		"player_name": player_name,
		"cash": cash,
		"respect": respect,
		"clout": clout,
		"testosterone_level": testosterone_level,
		"hustle_knowledge": hustle_knowledge,
		"pyramid_tier": pyramid_tier,
		"debt": debt,
		"grotty_bailouts_used": grotty_bailouts_used,
		"current_region": current_region,
		"unlocked_regions": unlocked_regions,
		"game_hour": game_hour,
		"game_day": game_day,
		"active_quests": active_quests,
		"completed_quests": completed_quests,
		"quest_choices": quest_choices,
		"unlocked_skills": unlocked_skills,
		"awareness": awareness,
		"scammagram_followers": scammagram_followers,
		"karma": karma,
		"grotty_trust": grotty_trust,
		"real_one_relationship": real_one_relationship,
		"real_one_gender": real_one_gender,
		"real_one_romance": real_one_romance,
	}


func load_save_data(data: Dictionary) -> void:
	for key in data.keys():
		if key in self:
			set(key, data[key])
