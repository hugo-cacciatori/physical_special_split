# Physical/Special Split Mod

A gameplay mod for Pokémon (Generation 1, 2, and 3) running on the Pokémon Love2D engine.

## Overview
In early Pokémon generations, move damage categories were strictly determined by the move's elemental type:
- Normal, Fighting, Flying, Poison, Ground, Rock, Bug, Ghost, and Steel moves always used Attack and Defense.
- Fire, Water, Grass, Electric, Psychic, Ice, Dragon, and Dark moves always used Special Attack and Special Defense.

This mod implements the modern Generation 4+ Physical/Special split across all generations:
- Each damaging move is classified as **Physical** or **Special** individually based on the move's contact and execution nature.
- High-attack Pokémon can effectively use elemental punches, Waterfall, Crunch, and Bite.
- Special attackers can effectively use Shadow Ball, Sludge Bomb, and Hyper Beam.
- Counter and Mirror Coat correctly react to Physical and Special damage respectively.
- Status moves remain Status category without direct damage calculation.

## Installation
1. Download `physical_special_split-0.1.0.zip` from the releases page.
2. Place or extract the mod into your `mods/` directory.
3. Start the game. The split is active immediately in all battles.

## Save Safety & Rollback
This mod operates entirely in memory during battle calculations. It does not alter your save files, Pokémon stats, or learned moves. Disabling the mod restores the original type-based damage calculations immediately.
