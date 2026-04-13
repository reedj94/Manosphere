extends Node

## Point-of-Interest registry. Defines every interactable building type
## and its per-region variant (name, look, colour, size, gameplay hook).
## The world scripts read this to spawn actual geometry + interaction zones.

signal poi_entered(poi_id: String, poi_type: String)
signal poi_exited(poi_id: String)
signal poi_interaction(poi_id: String, action: String)

enum POIType {
	SAFEHOUSE,
	SHOP,
	BOOKIES,
	NIGHTCLUB,
	PARK,
	VAPE_SHOP,
	BARBERS,
	RECRUITMENT_SHOP,
	FACTION_HQ,
}

# Interaction types available at each POI class
const POI_ACTIONS: Dictionary = {
	POIType.SAFEHOUSE: ["save", "stash", "upgrade", "sleep", "plan_heist"],
	POIType.SHOP: ["buy", "sell", "recruit", "talk"],
	POIType.BOOKIES: ["bet_horses", "bet_sumo", "bet_custom", "loan_shark"],
	POIType.NIGHTCLUB: ["quest_board", "dance", "recruit", "vip_area", "side_quest"],
	POIType.PARK: ["rest", "encounter", "train", "deal", "ambient_quest"],
	POIType.VAPE_SHOP: ["confront", "buy_vapes", "eavesdrop", "faction_dialogue"],
	POIType.BARBERS: ["confront", "get_trim", "eavesdrop", "faction_dialogue"],
	POIType.RECRUITMENT_SHOP: ["recruit", "buy", "talk", "sell"],
	POIType.FACTION_HQ: ["boss_fight", "negotiate", "spy", "faction_dialogue"],
}


# ---------------------------------------------------------------------------
# Per-region POI specs
# ---------------------------------------------------------------------------
# Each entry: { id, type, display_name, description, position, size, colour,
#               faction_id (optional), interactable, open_hours }
# Positions are relative to the region origin; world scripts offset as needed.
# ---------------------------------------------------------------------------

const CONSETT_POIS: Array = [
	# --- Player spaces ---
	{
		"id": "consett_mancave",
		"type": POIType.SAFEHOUSE,
		"display_name": "The Man Cave",
		"description": "A damp garage behind the chippy. Motivational posters peel off breeze-block walls. Home sweet home.",
		"position": Vector3(0.0, 0.0, -6.0),
		"size": Vector3(8.0, 6.0, 10.0),
		"colour": Color(0.35, 0.28, 0.22),
		"open_hours": [0, 24],
	},

	# --- Shops (recruitment) ---
	{
		"id": "consett_newsagent",
		"type": POIType.RECRUITMENT_SHOP,
		"display_name": "Davo's News & Bits",
		"description": "Newspapers nobody reads and energy drinks everybody does. Davo knows everyone.",
		"position": Vector3(14.0, 0.0, 10.0),
		"size": Vector3(7.0, 8.0, 9.0),
		"colour": Color(0.52, 0.48, 0.42),
		"open_hours": [6, 22],
	},
	{
		"id": "consett_chippy",
		"type": POIType.RECRUITMENT_SHOP,
		"display_name": "Battered Dreams Fish Bar",
		"description": "Chips, gravy, and gossip. The owner has opinions about EVERYTHING.",
		"position": Vector3(-14.0, 0.0, 10.0),
		"size": Vector3(8.0, 7.0, 10.0),
		"colour": Color(0.58, 0.52, 0.38),
		"open_hours": [11, 23],
	},
	{
		"id": "consett_charity_shop",
		"type": POIType.SHOP,
		"display_name": "Second Chances",
		"description": "Cheap suits for job interviews that'll never happen. Occasionally stocks rare hustle manuals.",
		"position": Vector3(24.0, 0.0, -4.0),
		"size": Vector3(7.0, 7.0, 8.0),
		"colour": Color(0.45, 0.5, 0.48),
		"open_hours": [9, 17],
	},

	# --- Bookies ---
	{
		"id": "consett_bookies",
		"type": POIType.BOOKIES,
		"display_name": "Guaranteed Returns Bookmakers",
		"description": "The carpet is sticky. The screens show horse racing and something called 'Extreme Sumo Showdown'. The regulars haven't left since 2019.",
		"position": Vector3(-24.0, 0.0, -4.0),
		"size": Vector3(9.0, 7.0, 10.0),
		"colour": Color(0.3, 0.45, 0.3),
		"open_hours": [8, 23],
	},

	# --- Nightclub ---
	{
		"id": "consett_nightclub",
		"type": POIType.NIGHTCLUB,
		"display_name": "Vibes (one letter broken: 'V_bes')",
		"description": "Sticky floors, UV lights, and a DJ who only plays 2008 bangers. Main quests start here after 10pm.",
		"position": Vector3(0.0, 0.0, 26.0),
		"size": Vector3(14.0, 9.0, 12.0),
		"colour": Color(0.15, 0.12, 0.2),
		"open_hours": [21, 4],
	},

	# --- Park ---
	{
		"id": "consett_park",
		"type": POIType.PARK,
		"display_name": "Memorial Gardens (Neglected)",
		"description": "A rusted climbing frame, two broken benches, and a burnt-out bin. Pigeons own this place. Occasional shady deals at dusk.",
		"position": Vector3(-30.0, 0.0, 20.0),
		"size": Vector3(18.0, 2.0, 16.0),
		"colour": Color(0.28, 0.35, 0.22),
		"open_hours": [0, 24],
	},

	# --- Faction: Vape Shop ---
	{
		"id": "consett_vape_shop",
		"type": POIType.VAPE_SHOP,
		"display_name": "Cloud 9½ Vapes",
		"description": "The window is pure fog. Inside: a thousand flavours and two blokes who REALLY want to talk about Grotty Green.",
		"position": Vector3(30.0, 0.0, 10.0),
		"size": Vector3(6.0, 8.0, 8.0),
		"colour": Color(0.6, 0.85, 0.55),
		"faction_id": "bazaar_brothers_consett",
		"open_hours": [9, 21],
	},

	# --- Faction: Barbers ---
	{
		"id": "consett_barbers",
		"type": POIType.BARBERS,
		"display_name": "Turdish Delights Barbers",
		"description": "More networking than trimming. Every chair is a throne. The waiting room doubles as a war council.",
		"position": Vector3(-30.0, 0.0, -10.0),
		"size": Vector3(7.0, 7.0, 9.0),
		"colour": Color(0.55, 0.75, 0.9),
		"faction_id": "trim_kings_consett",
		"open_hours": [8, 20],
	},
]


const LONDON_POIS: Array = [
	{
		"id": "london_mancave",
		"type": POIType.SAFEHOUSE,
		"display_name": "The Pad",
		"description": "A grotty flatshare in Zone 4. The 'office' is a fold-out desk. Smells of protein shakes and ambition.",
		"position": Vector3(0.0, 0.0, -6.0),
		"size": Vector3(10.0, 12.0, 10.0),
		"colour": Color(0.4, 0.35, 0.32),
		"open_hours": [0, 24],
	},
	{
		"id": "london_bookies",
		"type": POIType.BOOKIES,
		"display_name": "Sure Thing Racing & Sumo Lounge",
		"description": "Screens on every wall. The sumo channel has a cult following. Someone is always shouting at a horse.",
		"position": Vector3(-20.0, 0.0, 8.0),
		"size": Vector3(10.0, 9.0, 12.0),
		"colour": Color(0.25, 0.4, 0.25),
		"open_hours": [7, 24],
	},
	{
		"id": "london_nightclub",
		"type": POIType.NIGHTCLUB,
		"display_name": "APEX",
		"description": "Bottle service and bad decisions. The VIP list is a quest in itself.",
		"position": Vector3(0.0, 0.0, 30.0),
		"size": Vector3(16.0, 14.0, 14.0),
		"colour": Color(0.1, 0.08, 0.18),
		"open_hours": [22, 5],
	},
	{
		"id": "london_park",
		"type": POIType.PARK,
		"display_name": "Victoria Crescent Gardens",
		"description": "Slightly less neglected. Joggers, dog walkers, and one bloke doing burpees at 5am.",
		"position": Vector3(-28.0, 0.0, 22.0),
		"size": Vector3(20.0, 2.0, 18.0),
		"colour": Color(0.3, 0.42, 0.25),
		"open_hours": [0, 24],
	},
	{
		"id": "london_sterling_sons",
		"type": POIType.FACTION_HQ,
		"display_name": "Sterling & Sons Property Group",
		"description": "Glass-fronted office with photos of houses they definitely don't own. The brochures have clip-art mansions and spelling errors.",
		"position": Vector3(26.0, 0.0, 10.0),
		"size": Vector3(10.0, 14.0, 10.0),
		"colour": Color(0.85, 0.75, 0.3),
		"faction_id": "the_firm_london",
		"open_hours": [9, 18],
	},
	{
		"id": "london_cluckin",
		"type": POIType.FACTION_HQ,
		"display_name": "Cluckin' Investments Ltd",
		"description": "A chicken shop with a business plan. The menu board has a mission statement. The wings come with unsolicited career advice.",
		"position": Vector3(-26.0, 0.0, -8.0),
		"size": Vector3(9.0, 9.0, 10.0),
		"colour": Color(0.9, 0.5, 0.2),
		"faction_id": "yard_mandem_london",
		"open_hours": [11, 3],
	},
]


const MIAMI_POIS: Array = [
	{
		"id": "miami_mancave",
		"type": POIType.SAFEHOUSE,
		"display_name": "The Beach Shack",
		"description": "An Airbnb with a sea view and a mould problem. The 'content studio' is a ring light on the balcony.",
		"position": Vector3(0.0, 0.0, -6.0),
		"size": Vector3(12.0, 8.0, 10.0),
		"colour": Color(0.85, 0.78, 0.65),
		"open_hours": [0, 24],
	},
	{
		"id": "miami_bookies",
		"type": POIType.BOOKIES,
		"display_name": "Flamingo Bets",
		"description": "Neon pink interior. The sumo channel is HUGE here. Horse racing projected poolside.",
		"position": Vector3(-18.0, 0.0, 12.0),
		"size": Vector3(11.0, 8.0, 13.0),
		"colour": Color(0.9, 0.4, 0.55),
		"open_hours": [0, 24],
	},
	{
		"id": "miami_nightclub",
		"type": POIType.NIGHTCLUB,
		"display_name": "DRIP",
		"description": "Open-air mega-club. The bouncer is a quest giver. The dance floor is a battlefield.",
		"position": Vector3(0.0, 0.0, 32.0),
		"size": Vector3(20.0, 10.0, 16.0),
		"colour": Color(0.08, 0.05, 0.15),
		"open_hours": [23, 6],
	},
	{
		"id": "miami_park",
		"type": POIType.PARK,
		"display_name": "Sunset Boardwalk",
		"description": "Palm trees, outdoor gyms, and influencers filming content every 3 metres.",
		"position": Vector3(-30.0, 0.0, 24.0),
		"size": Vector3(24.0, 2.0, 20.0),
		"colour": Color(0.35, 0.55, 0.3),
		"open_hours": [0, 24],
	},
	{
		"id": "miami_nursery",
		"type": POIType.FACTION_HQ,
		"display_name": "Little Sunshine Childcare LLC",
		"description": "Twelve locations. A lawyer on retainer. The 'parent-teacher conferences' are recruitment drives.",
		"position": Vector3(28.0, 0.0, 8.0),
		"size": Vector3(12.0, 8.0, 12.0),
		"colour": Color(0.95, 0.65, 0.3),
		"faction_id": "sol_coast_crew",
		"open_hours": [7, 18],
	},
	{
		"id": "miami_import_export",
		"type": POIType.FACTION_HQ,
		"display_name": "Tropical Goods & More",
		"description": "Shipping containers full of motivational posters and knock-off supplements.",
		"position": Vector3(-28.0, 0.0, -6.0),
		"size": Vector3(10.0, 10.0, 14.0),
		"colour": Color(0.4, 0.85, 0.75),
		"faction_id": "ocean_drive_collective",
		"open_hours": [6, 22],
	},
]


const DUBAI_POIS: Array = [
	{
		"id": "dubai_mancave",
		"type": POIType.SAFEHOUSE,
		"display_name": "The Marina Suite",
		"description": "A rented penthouse. The fridge has nothing but pre-workout and champagne. The view IS the flex.",
		"position": Vector3(0.0, 0.0, -6.0),
		"size": Vector3(14.0, 18.0, 12.0),
		"colour": Color(0.9, 0.88, 0.82),
		"open_hours": [0, 24],
	},
	{
		"id": "dubai_bookies",
		"type": POIType.BOOKIES,
		"display_name": "The Gold Lounge — Racing & Sumo",
		"description": "Gold leaf on every surface. Minimum bet: insane. The sumo matches are sponsored by energy drinks.",
		"position": Vector3(-16.0, 0.0, 14.0),
		"size": Vector3(12.0, 12.0, 14.0),
		"colour": Color(0.85, 0.75, 0.25),
		"open_hours": [0, 24],
	},
	{
		"id": "dubai_nightclub",
		"type": POIType.NIGHTCLUB,
		"display_name": "ZENITH",
		"description": "Rooftop mega-venue. The final quest hub. Entry requires a media kit.",
		"position": Vector3(0.0, 0.0, 34.0),
		"size": Vector3(22.0, 20.0, 18.0),
		"colour": Color(0.05, 0.03, 0.12),
		"open_hours": [22, 6],
	},
	{
		"id": "dubai_park",
		"type": POIType.PARK,
		"display_name": "Oasis Promenade",
		"description": "Immaculate artificial gardens. Every bench has a QR code for a networking app.",
		"position": Vector3(-32.0, 0.0, 26.0),
		"size": Vector3(26.0, 2.0, 22.0),
		"colour": Color(0.4, 0.6, 0.35),
		"open_hours": [0, 24],
	},
	{
		"id": "dubai_ascend",
		"type": POIType.FACTION_HQ,
		"display_name": "Ascend Digital Media",
		"description": "British expat influencers running 'digital academies' from a rented Marina office. The final boss of hustle culture.",
		"position": Vector3(30.0, 0.0, 8.0),
		"size": Vector3(14.0, 22.0, 12.0),
		"colour": Color(0.9, 0.45, 0.85),
		"faction_id": "influencer_elite",
		"open_hours": [10, 22],
	},
	{
		"id": "dubai_al_falcon",
		"type": POIType.FACTION_HQ,
		"display_name": "Al-Falcon Holdings & Leisure",
		"description": "A marble lobby with a golden falcon statue. Seven Rolls Royces parked outside, all gold. The receptionist asks for your net worth before your name.",
		"position": Vector3(-30.0, 0.0, -8.0),
		"size": Vector3(14.0, 20.0, 16.0),
		"colour": Color(0.95, 0.85, 0.35),
		"faction_id": "golden_falcons",
		"open_hours": [10, 22],
	},
]


# Quick lookup: region -> POI array
const REGION_POIS: Dictionary = {
	GameState.Region.CONSETT: "consett",
	GameState.Region.LONDON: "london",
	GameState.Region.MIAMI: "miami",
	GameState.Region.DUBAI: "dubai",
}


func get_pois_for_region(region: GameState.Region) -> Array:
	match region:
		GameState.Region.CONSETT: return CONSETT_POIS
		GameState.Region.LONDON: return LONDON_POIS
		GameState.Region.MIAMI: return MIAMI_POIS
		GameState.Region.DUBAI: return DUBAI_POIS
	return []


func get_poi(poi_id: String) -> Dictionary:
	for region_key in [GameState.Region.CONSETT, GameState.Region.LONDON, GameState.Region.MIAMI, GameState.Region.DUBAI]:
		for poi in get_pois_for_region(region_key):
			if poi["id"] == poi_id:
				return poi
	return {}


func get_actions(poi_type: int) -> Array:
	return POI_ACTIONS.get(poi_type, [])


func is_open(poi: Dictionary, hour: int) -> bool:
	var open: int = poi.get("open_hours", [0, 24])[0]
	var close: int = poi.get("open_hours", [0, 24])[1]
	if open < close:
		return hour >= open and hour < close
	else:
		return hour >= open or hour < close


func get_faction_pois(faction_id: String) -> Array:
	var result: Array = []
	for region_key in [GameState.Region.CONSETT, GameState.Region.LONDON, GameState.Region.MIAMI, GameState.Region.DUBAI]:
		for poi in get_pois_for_region(region_key):
			if poi.get("faction_id", "") == faction_id:
				result.append(poi)
	return result
