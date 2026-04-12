extends Node

## Scammagram — full fake social media app. Scrollable feed, stories,
## DMs, comments, algorithm simulation. Central to the satire.

signal new_post_created(post: Dictionary)
signal follower_milestone(count: int, reward: String)
signal post_went_viral(post: Dictionary)
signal dm_received(from: String, message: String)
signal algorithm_event(event_type: String)

const VIRAL_THRESHOLD := 0.85  # score needed to go viral
const ALGORITHM_BIAS_BY_MOOD := {
	MarketMood.Mood.EXTREME_BULL: ["flex", "trading_screenshot", "motivation", "car_flex"],
	MarketMood.Mood.BULL: ["gym_selfie", "motivation", "trading_screenshot"],
	MarketMood.Mood.NEUTRAL: ["gym_selfie", "lifestyle", "food"],
	MarketMood.Mood.BEAR: ["real_talk", "vulnerability", "motivation"],
	MarketMood.Mood.EXTREME_BEAR: ["real_talk", "vulnerability", "accountability"],
}

const FOLLOWER_MILESTONES := {
	100: {"reward": "blue_tick_fake", "notification": "Congrats! You've been verified (it means nothing)."},
	1000: {"reward": "sponsorship_tier_1", "notification": "A protein powder brand wants to sponsor you!"},
	5000: {"reward": "sponsorship_tier_2", "notification": "You can now sell shoutouts."},
	10000: {"reward": "scammagram_live", "notification": "Scammagram Live unlocked!"},
	50000: {"reward": "sponsorship_tier_3", "notification": "Major brand deal available."},
	100000: {"reward": "algorithm_boost", "notification": "The algorithm favours you now."},
	500000: {"reward": "verified_real", "notification": "You're actually famous. Was it worth it?"},
}

enum PostType { GYM_SELFIE, CAR_FLEX, MOTIVATION, TRADING_SCREENSHOT, REAL_TALK, LIFESTYLE, FOOD, VULNERABILITY, ACCOUNTABILITY }

# Feed state
var feed_posts: Array[Dictionary] = []
var player_posts: Array[Dictionary] = []
var stories: Array[Dictionary] = []
var dms: Dictionary = {}  # npc_id -> Array of {from, message, timestamp, read}
var notifications: Array[Dictionary] = []

# NPC post generation
var npc_post_timer: float = 0.0
const NPC_POST_INTERVAL := 60.0  # new NPC post every minute of game time


func _ready() -> void:
	_generate_initial_feed()


func _process(delta: float) -> void:
	npc_post_timer += delta
	if npc_post_timer >= NPC_POST_INTERVAL:
		npc_post_timer = 0.0
		_generate_npc_post()
	_expire_stories()


func create_player_post(post_type: PostType, caption: String, location: String = "") -> Dictionary:
	var post := {
		"id": "player_%d" % Time.get_ticks_msec(),
		"author": "player",
		"author_name": GameState.player_name,
		"type": PostType.keys()[post_type].to_lower(),
		"caption": caption,
		"location": location,
		"region": GameState.Region.keys()[GameState.current_region],
		"timestamp": Time.get_unix_time_from_system(),
		"likes": 0,
		"comments": [],
		"engagement_score": 0.0,
		"is_viral": false,
	}

	post["engagement_score"] = _calculate_engagement(post)

	if post["engagement_score"] >= VIRAL_THRESHOLD:
		post["is_viral"] = true
		post["likes"] = randi_range(5000, 50000)
		var clout_gain := randi_range(500, 5000)
		GameState.add_clout(clout_gain)
		post_went_viral.emit(post)
	else:
		post["likes"] = int(post["engagement_score"] * GameState.scammagram_followers * 0.1)
		var clout_gain := int(post["engagement_score"] * 10)
		GameState.add_clout(clout_gain)

	post["comments"] = _generate_comments(post)

	player_posts.append(post)
	feed_posts.insert(0, post)
	new_post_created.emit(post)

	_check_follower_milestones()
	return post


func _calculate_engagement(post: Dictionary) -> float:
	var score := 0.0

	# Algorithm bias: does the post type match what the current mood favours?
	var favoured: Array = ALGORITHM_BIAS_BY_MOOD.get(MarketMood.current_mood, ["gym_selfie"])
	if post["type"] in favoured:
		score += 0.3

	# Follower multiplier
	score += clampf(GameState.scammagram_followers / 100000.0, 0.0, 0.2)

	# Clout stat bonus
	score += clampf(GameState.clout / 10000.0, 0.0, 0.15)

	# Time-of-day bonus (posting at peak hours)
	if GameState.game_hour >= 18 and GameState.game_hour <= 21:
		score += 0.1
	elif GameState.game_hour >= 7 and GameState.game_hour <= 9:
		score += 0.05

	# Random viral chance
	score += randf_range(0.0, 0.25)

	# Location bonus (famous locations score higher)
	if post["location"] != "":
		score += 0.05

	return clampf(score, 0.0, 1.0)


func _generate_comments(post: Dictionary) -> Array[Dictionary]:
	var comments: Array[Dictionary] = []
	var num_comments := int(post["engagement_score"] * 20)

	var positive_comments := [
		"King behaviour", "This is the grindset", "Link in bio?",
		"Hard work pays off", "Sigma male detected", "W",
	]
	var negative_comments := [
		"Cringe", "Touch grass", "The car's rented lol",
		"This is embarrassing", "Your mum's worried about you",
		"Is this satire?", "Please seek help",
	]
	var neutral_comments := [
		"First", "Fire", "Mid", "Thoughts?",
	]

	for i in num_comments:
		var pool: Array
		if post["is_viral"]:
			pool = positive_comments if randf() > 0.3 else negative_comments
		elif MarketMood.current_mood <= MarketMood.Mood.BEAR:
			pool = negative_comments if randf() > 0.4 else neutral_comments
		else:
			pool = positive_comments if randf() > 0.5 else neutral_comments

		comments.append({
			"author": "npc_%d" % randi_range(1000, 9999),
			"text": pool[randi_range(0, pool.size() - 1)],
			"likes": randi_range(0, 100),
		})

	return comments


func send_dm(to_npc: String, message: String) -> void:
	if not dms.has(to_npc):
		dms[to_npc] = []
	dms[to_npc].append({
		"from": "player",
		"message": message,
		"timestamp": Time.get_unix_time_from_system(),
		"read": true,
	})


func receive_dm(from_npc: String, message: String) -> void:
	if not dms.has(from_npc):
		dms[from_npc] = []
	dms[from_npc].append({
		"from": from_npc,
		"message": message,
		"timestamp": Time.get_unix_time_from_system(),
		"read": false,
	})
	dm_received.emit(from_npc, message)


func _generate_npc_post() -> void:
	var mood_tags: Array = MarketMood.get_dialogue_tags()
	var region_name: String = GameState.Region.keys()[GameState.current_region]

	var npc_names := ["FedNatty_Official", "GrindsetGuru", "CryptoKing_%d" % randi_range(1,99),
		"AlphaWolf_%s" % region_name, "SigmaMindset", "HustleBabe", "MotivationDaily",
		"BitConBillionaire", "TheRealOne_%d" % randi_range(1,50)]

	# TODO: replace with AI-generated posts when online
	var templates := {
		"extreme_bull": ["Just made £%d in one trade. You're still sleeping.", "EVERYONE'S A GENIUS IN A BULL MARKET. But I'm a genius always."],
		"bull": ["Another green day. The grind doesn't stop.", "My portfolio is up %d%% this week. What's yours doing?"],
		"neutral": ["Consistency is key. Every. Single. Day.", "Gym at 5am. Chart at 6am. Content at 7am."],
		"bear": ["Hold the line. Diamond hands. This is where boys become men.", "If you're selling now you never deserved to make it."],
		"extreme_bear": ["I'm fine. Everything is fine. My portfolio is just resting.", "Anyone know if Nandos is hiring?"],
	}

	var mood_key: String = MarketMood.Mood.keys()[MarketMood.current_mood].to_lower()
	var captions: Array = templates.get(mood_key, templates["neutral"])
	var caption: String = captions[randi_range(0, captions.size() - 1)]
	if "%d" in caption:
		caption = caption % randi_range(100, 50000)

	var post := {
		"id": "npc_%d" % Time.get_ticks_msec(),
		"author": npc_names[randi_range(0, npc_names.size() - 1)],
		"author_name": "",
		"type": "motivation",
		"caption": caption,
		"region": region_name,
		"timestamp": Time.get_unix_time_from_system(),
		"likes": randi_range(10, 5000),
		"comments": [],
		"engagement_score": randf_range(0.1, 0.7),
		"is_viral": false,
	}

	feed_posts.insert(0, post)
	if feed_posts.size() > 200:
		feed_posts.resize(200)


func _generate_initial_feed() -> void:
	for i in 20:
		_generate_npc_post()


func _expire_stories() -> void:
	var now := Time.get_unix_time_from_system()
	stories = stories.filter(func(s): return now - s.get("timestamp", 0) < 86400)


func _check_follower_milestones() -> void:
	for threshold in FOLLOWER_MILESTONES:
		if GameState.scammagram_followers >= threshold:
			var milestone: Dictionary = FOLLOWER_MILESTONES[threshold]
			if not milestone.get("claimed", false):
				milestone["claimed"] = true
				follower_milestone.emit(threshold, milestone["reward"])


func get_feed(count: int = 20, offset: int = 0) -> Array[Dictionary]:
	var end_idx := mini(offset + count, feed_posts.size())
	if offset >= feed_posts.size():
		return []
	return feed_posts.slice(offset, end_idx)


func get_unread_dm_count() -> int:
	var count := 0
	for npc_id in dms:
		for msg in dms[npc_id]:
			if not msg["read"] and msg["from"] != "player":
				count += 1
	return count
