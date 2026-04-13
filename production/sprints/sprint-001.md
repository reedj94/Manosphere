# Sprint 1 — Consett Walkable World

**Duration:** 2026-04-13 → 2026-04-20
**Goal:** Player can walk around Consett, enter POIs, trigger faction dialogues, and bet at the bookies.

## Stories

| ID | Story | Points | Status | Notes |
|----|-------|--------|--------|-------|
| S-001 | POI buildings spawn with signs, interaction zones, and open/closed logic | 3 | DONE | consett_blockout.gd rewritten |
| S-002 | Faction system with per-region antagonists and barks | 3 | DONE | faction_manager.gd + poi_registry.gd |
| S-003 | Faction dialogue trees (Bazaar Brothers + Trim Kings) | 5 | DONE | JSON dialogues created |
| S-004 | Bookies minigame — horse racing + sumo betting | 5 | TODO | |
| S-005 | POI interaction (E key) opens context-appropriate UI | 3 | TODO | |
| S-006 | Man Cave save/sleep functionality | 2 | TODO | |
| S-007 | Day/night cycle visual change | 2 | TODO | |

## Acceptance Criteria
- [ ] Game launches, main menu → Consett works
- [ ] All POI buildings visible with 3D labels
- [ ] Walking near faction POIs shows bark text
- [ ] E key triggers interaction at open POIs
- [ ] Bookies minigame is playable

## Blockers
- None currently
