# Manosphere — Master Game Design Document

**Version:** 0.2.0
**Last Updated:** 2026-04-13
**Engine:** Godot 4.6.2 (Mono / C# support)
**Genre:** Satirical open-world RPG
**Target:** PC (Steam), potential console port

---

## 1. High Concept

A satirical open-world RPG where the player climbs the "manosphere" pyramid — from Wage Slave in a dying Northern town to self-proclaimed King of the Manosphere in Dubai — while the game systematically roasts every hustle-culture trope, crypto scam, and toxic masculinity cliché along the way.

The tone is GTA-meets-Brass-Eye: **everyone** gets roasted equally. The player's own journey is the biggest joke of all.

## 2. Core Loop

```
Earn Cash/Respect → Unlock Skills/Phrases → Access New Areas → Encounter Harder Factions → Climb Pyramid Tier → Repeat
```

### Secondary Loops
- **Trading:** Buy/sell fake crypto (CraptoFeed) — prices driven by MarketMood
- **Recruitment:** Talk NPCs into joining your "downline" at shops
- **Betting:** Horse racing + Extreme Sumo Showdown at bookies
- **Social Media:** Post on Scammagram for followers/clout
- **Quests:** Main + side quests primarily at nightclubs and faction encounters

## 3. Regions

| Region | Tier Unlock | Vibe | Faction 1 | Faction 2 |
|--------|-------------|------|-----------|-----------|
| **Consett** | Start | Bleak northern high street, harsh geometry, run-down | The Bazaar Brothers (vape shop) | The Trim Kings (barbers) |
| **London** | Sigma in Training (Tier 4) | Urban sprawl, property hustle, grime culture | The Firm (property spivs) | The Yard Mandem (chicken shop empire) |
| **Miami** | International Player (Tier 7) | Beach flex, neon, Latin heat | Sol Coast Crew (nursery empire) | Ocean Drive Collective (import-export) |
| **Dubai** | Crypto Lord (Tier 9) | Gold, glass, performative wealth | The Content Cartel (British expat influencers) | The Golden Falcons (oil wealth heirs) |

## 4. POI Types (per region)

| POI | Gameplay Purpose |
|-----|-----------------|
| Man Cave (Safehouse) | Save, stash, upgrade, sleep, plan |
| Shops | Recruit NPCs, buy/sell items |
| Bookies | Bet on minigames (horses, sumo) |
| Nightclub | Main/side quest hub, dance, VIP |
| Park | Rest, encounters, training, ambient quests |
| Faction Business 1 | Confront, eavesdrop, faction dialogue |
| Faction Business 2 | Confront, eavesdrop, faction dialogue |

## 5. Key Characters

- **The Player** — customisable, starts in Consett, climbs the pyramid
- **Grotty Green** — mysterious figure running "holy sessions" (spiritual massages for 1000 men at a time); every faction is connected to her revenue stream
- **The Real One** — love interest, provides grounding / awareness stat boosts
- **Faction Leaders** — Big Kaz, Uncle Fadez, Tommy Bricks, Big Dex, Mama Sol, Captain Breeze, Chad Sterling, Sheikh Zayed Jr.

## 6. Stats

| Stat | Purpose |
|------|---------|
| Cash | Primary currency |
| Respect | Drives pyramid advancement |
| Clout | Social media power, feeds Scammagram followers |
| Testosterone Level | Satire stat — affects NPC reactions |
| Hustle Knowledge | Unlocks dialogue options and business moves |
| Awareness | Hidden stat — how self-aware the player becomes |
| Karma | Positive = ethical, negative = exploitative — drives ending |

## 7. Visual Style

**Harsh low-poly brutalist geometry.** Flat muted colours, sharp rectangular buildings, no organic curves. PS1-era aesthetic crossed with brutalist architecture. Each region keeps the angular style but shifts palette:

- Consett: Slate grey, dusty brown, overcast
- London: Darker greys, brick red, yellow street light
- Miami: Washed-out pastels, neon pink accents, bright sky
- Dubai: Gold, white marble, blinding sun

## 8. Pyramid Tiers

1. Wage Slave (start)
2. Side Hustler
3. Grindset Apprentice
4. Sigma in Training → unlocks London
5. Content Creator
6. Hustle Merchant
7. International Player → unlocks Miami
8. Alpha Prospect
9. Crypto Lord → unlocks Dubai
10. King of Manosphere (endgame)

## 9. Open Questions / TODO

- [ ] Combat system design (verbal vs physical vs both?)
- [ ] Bookies minigame mechanics (horse racing, sumo)
- [ ] Scammagram UI/UX flow
- [ ] Multiplayer: shared journey vs parallel hustles detail
- [ ] Ending conditions and cutscenes
- [ ] Music / audio direction
