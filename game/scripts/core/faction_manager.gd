extends Node

## Antagonist faction system. Each region has a local faction running
## businesses that escalate in sophistication as the player progresses.
## Factions are fictional composites — the satire targets the *stereotypes*
## themselves, not any real group. Every culture in the game, including
## the player's own manosphere bubble, is equally roasted.

signal faction_hostility_changed(faction_id: String, new_level: int)
signal faction_encounter(faction_id: String, npc_id: String, encounter_type: String)
signal territory_contested(poi_id: String, faction_id: String)

enum EncounterType { VERBAL, SHAKEDOWN, AMBUSH, TURF_WAR, BOSS_FIGHT }


# ---------------------------------------------------------------------------
# Faction definitions per region
# ---------------------------------------------------------------------------
# Each faction has:
#   name          - display name (fictional)
#   business_type - what they run in this region
#   barks         - random shouts during encounters (all fictional/parodied)
#   leader        - named boss NPC
#   base_hostility - starting aggro (0-100)
#   difficulty     - combat scaling modifier
#   colour         - UI / map tint for their territory
#   lore           - one-liner shown in the codex
# ---------------------------------------------------------------------------

const FACTIONS: Dictionary = {
	GameState.Region.CONSETT: [
		{
			"id": "bazaar_brothers_consett",
			"name": "The Bazaar Brothers",
			"business_type": "vape_shop",
			"shop_name": "Cloud 9½ Vapes",
			"leader": "Big Kaz",
			"barks": [
				"RD4 brutha, you know the code!",
				"Oi, vapeman pays his debts!",
				"You talk to Grotty again, we talk to your face!",
				"She owes us THREE holy sessions!",
				"Mango ice, 50mg, no questions brutha!",
				"This is OUR corner of the high street!",
				"My cousin's cousin will hear about this, brutha!",
				"RD4 for LIFE! You don't even know what that means!",
				"Wallahi this vape shop is a FAMILY institution!",
				"You want beef? We do lamb too, brutha!",
			],
			"lore": "Vape merchants who funded their empire one disposable at a time. Furious you're cutting into Grotty Green's 'spiritual massage' revenue stream.",
			"base_hostility": 30,
			"difficulty": 1.0,
			"colour": Color(0.6, 0.85, 0.55),
		},
		{
			"id": "trim_kings_consett",
			"name": "The Trim Kings",
			"business_type": "barbers",
			"shop_name": "Turdish Delights Barbers",
			"leader": "Uncle Fadez",
			"barks": [
				"Wallahi she promised a thousand-man session!",
				"You want a trim or a slap, bro?",
				"Nobody talks to our spiritual consultant!",
				"Skin fade AND a life lesson, free of charge!",
				"My cousin's cousin says you're chatting to Green!",
				"Bro I will LINE YOU UP and I don't mean your hair!",
				"Sit in the chair or sit on the FLOOR, your choice bro!",
				"We've been here since before the Greggs opened!",
				"My uncle owns three shops on this street, bro. THREE!",
				"I'll blend your fade AND your face if you don't watch it!",
				"The clippers are BUZZING and so am I, bro!",
				"You call that a beard? That's a DISGRACE to facial hair!",
				"Hot towel to the face! Complimentary! Whether you WANT it or not!",
				"Bro, my razor is sharper than your chat!",
			],
			"lore": "Barbers who do more networking than trimming. Their chairs are thrones and their waiting room is a war room.",
			"base_hostility": 25,
			"difficulty": 0.9,
			"colour": Color(0.55, 0.75, 0.9),
		},
	],

	GameState.Region.LONDON: [
		{
			"id": "the_firm_london",
			"name": "The Firm",
			"business_type": "property_scam",
			"shop_name": "Sterling & Sons Property Group",
			"leader": "Tommy Bricks",
			"barks": [
				"You're in the WRONG postcode, son!",
				"This manor's been OURS since your nan was in nappies!",
				"I know geezers who know geezers, you get me?",
				"Grotty Green? She's on OUR books now, innit!",
				"I'll have your gaff repossessed by TUESDAY!",
				"You mug! I've got solicitors on SPEED DIAL!",
				"My old man ran these streets, and I run the BUILDINGS!",
				"Think you're a big man? I OWN big men's HOUSES!",
				"Don't come round here without a deposit, sunshine!",
				"I'll sell your flat while you're still IN it, mate!",
				"This is LONDON, not some northern village!",
				"My portfolio's worth more than your entire POSTCODE!",
			],
			"lore": "East End property spivs who graduated from market stalls to million-pound flips. They measure respect in square footage.",
			"base_hostility": 45,
			"difficulty": 1.5,
			"colour": Color(0.85, 0.75, 0.3),
		},
		{
			"id": "yard_mandem_london",
			"name": "The Yard Mandem",
			"business_type": "chicken_shop_empire",
			"shop_name": "Cluckin' Investments Ltd",
			"leader": "Big Dex",
			"barks": [
				"Wagwan! You're moving MAD out here, fam!",
				"This is MY ends, don't get it twisted!",
				"Grotty Green's doing holy sessions for US now, still!",
				"You know how many wings I shift a DAY? Do you?!",
				"Fam, I turned a meal deal into a FRANCHISE!",
				"My chicken shop is worth more than your LIFE goals!",
				"Don't watch that! Watch THIS empire, yeah!",
				"I was on road before road was a LIFESTYLE BRAND!",
				"You're moving like a civilian, fam!",
				"Man's got FOURTEEN shops and a PODCAST!",
				"Say wallahi you didn't just disrespect my BRAND!",
				"My young gs will run you out of zone THREE, fam!",
			],
			"lore": "A chicken shop empire that's secretly a networking hub for every hustle in South London. The meal deal comes with a side of intimidation.",
			"base_hostility": 40,
			"difficulty": 1.4,
			"colour": Color(0.9, 0.5, 0.2),
		},
	],

	GameState.Region.MIAMI: [
		{
			"id": "sol_coast_crew",
			"name": "Sol Coast Crew",
			"business_type": "nursery_empire",
			"shop_name": "Little Sunshine Childcare LLC",
			"leader": "Mama Sol",
			"barks": [
				"You don't BELONG on this beach, papi!",
				"Grotty Green? She works for US now!",
				"We got twelve locations and a LAWYER!",
				"Nap time is OVER for you, mijo!",
				"Our Yelp rating will DESTROY you!",
				"Every child is a future investor, papi!",
				"You think you tough? My abuela is tougher!",
				"I didn't cross an ocean to lose to YOU!",
				"Mami didn't raise no quitter and she won't raise YOU either!",
				"This playground is OURS, comprende?",
			],
			"lore": "A childcare empire that's a front for the biggest networking hustle in South Beach. Their 'parent-teacher conferences' are recruitment drives.",
			"base_hostility": 55,
			"difficulty": 2.0,
			"colour": Color(0.95, 0.65, 0.3),
		},
		{
			"id": "ocean_drive_collective",
			"name": "Ocean Drive Collective",
			"business_type": "import_export",
			"shop_name": "Tropical Goods & More",
			"leader": "Captain Breeze",
			"barks": [
				"This is international waters, my friend!",
				"My shipping containers, my rules!",
				"Grotty Green's sessions are OUR franchise!",
				"You want import? We got EXPORT for you!",
				"The docks don't forget!",
				"Back home I was a GENERAL! Well... a corporal. But STILL!",
				"My mother sent me here to SUCCEED, not to deal with YOU!",
				"I have connections in FOURTEEN countries!",
				"You think this is hard? Try running a nursery AND a shipping empire!",
				"I didn't learn English for THIS conversation!",
			],
			"lore": "Import-export merchants whose containers are full of motivational posters and knock-off supplements.",
			"base_hostility": 50,
			"difficulty": 1.8,
			"colour": Color(0.4, 0.85, 0.75),
		},
	],

	GameState.Region.DUBAI: [
		{
			"id": "influencer_elite",
			"name": "The Content Cartel",
			"business_type": "influencer_agency",
			"shop_name": "Ascend Digital Media",
			"leader": "Chad Sterling",
			"barks": [
				"Wait till my father hears about this!",
				"Do you even KNOW who my father is?!",
				"My followers are VERIFIED, mate!",
				"I've got a brand deal you can't REFUSE!",
				"Grotty Green's engagement rate is OURS!",
				"Do you even HAVE a media kit?",
				"My morning routine gets more views than your LIFE!",
				"I'll cancel you before breakfast!",
				"I went to a VERY good school, I'll have you know!",
				"Daddy's lawyers will be in touch!",
				"I didn't fly business class for this!",
				"You're literally disrupting my content schedule!",
				"I know people at VICE, mate. VICE!",
				"My gap year was more productive than your entire CAREER!",
			],
			"lore": "British expat influencers running 'digital academies' from a rented Marina apartment. The final boss of hustle culture.",
			"base_hostility": 65,
			"difficulty": 3.0,
			"colour": Color(0.9, 0.45, 0.85),
		},
		{
			"id": "golden_falcons",
			"name": "The Golden Falcons",
			"business_type": "oil_and_luxury",
			"shop_name": "Al-Falcon Holdings & Leisure",
			"leader": "Sheikh Zayed Jr. (self-appointed)",
			"barks": [
				"Daddy is gonna sheikh you DOWN, habibi!",
				"You see that golden Rolls Royce? I have SEVEN!",
				"My falcon is worth more than your entire BLOODLINE!",
				"I will buy your house and turn it into a GARAGE!",
				"Oil money never runs dry, habibi!",
				"You want to fight? I will hire someone to fight FOR me!",
				"My gold-plated phone is ringing — it's your LANDLORD!",
				"In my country, men like you park the CARS!",
				"Grotty Green does private sessions for our FAMILY only!",
				"I sneeze and the stock market MOVES, habibi!",
				"Do you know how many barrels a DAY? DO YOU?!",
				"My air conditioning costs more than your SALARY!",
				"I will buy this ENTIRE street and rename it after my CAT!",
				"Habibi, my watch costs more than your FUTURE!",
				"The desert swallows men like you. And so does my LEGAL TEAM!",
				"One call and your visa is CANCELLED, my friend!",
			],
			"lore": "Oil-wealth heirs who measure everything in barrels per day. Their golden Rolls Royce fleet blocks traffic on the Marina daily. The mirror image of everything the player aspires to — except they were born into it.",
			"base_hostility": 70,
			"difficulty": 3.5,
			"colour": Color(0.95, 0.85, 0.35),
		},
	],
}


# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------

# faction_id -> current hostility (0-100, triggers encounters at thresholds)
var hostility: Dictionary = {}

# faction_id -> territory_control (0-100, how much of the region they own)
var territory_control: Dictionary = {}

# faction_id -> defeated (boss beaten)
var defeated_factions: Array[String] = []


func _ready() -> void:
	_init_faction_state()


func _init_faction_state() -> void:
	for region_key in FACTIONS:
		var factions: Array = FACTIONS[region_key]
		for f in factions:
			var fid: String = f["id"]
			hostility[fid] = f["base_hostility"]
			territory_control[fid] = 50


func get_factions_for_region(region: GameState.Region) -> Array:
	return FACTIONS.get(region, [])


func get_faction(faction_id: String) -> Dictionary:
	for region_key in FACTIONS:
		for f in FACTIONS[region_key]:
			if f["id"] == faction_id:
				return f
	return {}


func add_hostility(faction_id: String, amount: int) -> void:
	if not hostility.has(faction_id):
		return
	hostility[faction_id] = clampi(hostility[faction_id] + amount, 0, 100)
	faction_hostility_changed.emit(faction_id, hostility[faction_id])

	if hostility[faction_id] >= 80:
		_trigger_ambush(faction_id)


func get_random_bark(faction_id: String) -> String:
	var f := get_faction(faction_id)
	if f.is_empty():
		return ""
	var barks: Array = f.get("barks", [])
	if barks.is_empty():
		return ""
	return barks[randi() % barks.size()]


func get_encounter_difficulty(faction_id: String) -> float:
	var f := get_faction(faction_id)
	var base: float = f.get("difficulty", 1.0)
	var aggro: int = hostility.get(faction_id, 0)
	return base * (1.0 + aggro * 0.005)


func reduce_territory(faction_id: String, amount: int) -> void:
	if not territory_control.has(faction_id):
		return
	territory_control[faction_id] = clampi(territory_control[faction_id] - amount, 0, 100)
	if territory_control[faction_id] <= 0:
		territory_contested.emit("", faction_id)


func defeat_faction(faction_id: String) -> void:
	if faction_id not in defeated_factions:
		defeated_factions.append(faction_id)
		territory_control[faction_id] = 0
		hostility[faction_id] = 0


func _trigger_ambush(faction_id: String) -> void:
	faction_encounter.emit(faction_id, "", "ambush")
