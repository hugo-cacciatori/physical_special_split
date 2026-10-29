# Changelog

All notable changes to the `physical_special_split` mod will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-10-29

- The logic now ships as a library bundled inside the mod; behaviour is unchanged.

## [0.1.0] - 2026-10-25

### Added
- Decoupled physical and special damage calculations from move elemental types across Generation 1, Generation 2, and Generation 3 games, implementing the official Generation 4+ standard move category split.
- Canonical category assignment for all damaging moves:
  - Physical moves of historically special types: Fire Punch, Flame Wheel, Sacred Fire, Blaze Kick, Waterfall, Dive, Clamp, Crabhammer, Leaf Blade, Vine Whip, Razor Leaf, Bullet Seed, Needle Arm, ThunderPunch, Spark, Volt Tackle, Ice Punch, Icicle Spear, Ice Ball, Bite, Crunch, Pursuit, Thief, Knock Off, Feint Attack, Beat Up, Dragon Claw, Outrage.
  - Special moves of historically physical types: Hyper Beam, Swift, Tri Attack, Snore, Uproar, Razor Wind, SonicBoom, Weather Ball, Hidden Power, Shadow Ball, Night Shade, Sludge Bomb, Sludge, Smog, Acid, Mud-Slap, Mud Shot, AncientPower, Silver Wind, Signal Beam, Doom Desire, Gust, Air Cutter, Aeroblast.
  - Status moves (`power == 0`): strictly preserved as `"status"` with zero direct damage.
- Stat & screen interaction fidelity:
  - Physical moves scale with Attack (and stages), are halved by Burn (unless Guts) and Reflect, and benefit from Choice Band and Huge/Pure Power.
  - Special moves scale with Special Attack (and stages), are halved by Light Screen, and benefit from Plus/Minus, Soul Dew, Deep Sea Tooth, and Light Ball.
- Counter and Mirror Coat integration:
  - Counter accurately reflects Physical moves regardless of elemental type (e.g. reacts to Fire Punch and Waterfall).
  - Mirror Coat accurately reflects Special moves regardless of elemental type (e.g. reacts to Shadow Ball and Sludge Bomb).
- Clean rollback: removing or disabling the mod immediately restores original type-based damage calculations without modifying player save files.
