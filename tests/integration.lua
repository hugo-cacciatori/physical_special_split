package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")
local Sdk = require("tests.modkit.sdk")
local GameVersion = require("src.core.GameVersion")
local Runtime = require("src.mods.Runtime")
local Logger = require("src.core.Logger")
if Logger.warn then Logger.warn = function() end end

local total = 0
local function check(value, message)
  total = total + 1
  assert(value, message)
end

local PROFILES = {
  { version = "firered", gen = 3 },
  { version = "leafgreen", gen = 3 },
  { version = "ruby", gen = 3 },
  { version = "sapphire", gen = 3 },
  { version = "emerald", gen = 3 },
  { version = "red", gen = 1 },
  { version = "blue", gen = 1 },
  { version = "yellow", gen = 1 },
  { version = "gold", gen = 2 },
  { version = "silver", gen = 2 },
  { version = "crystal", gen = 2 },
}

for _, p in ipairs(PROFILES) do
  GameVersion.set(p.version)
  Runtime.reset()

  local opts = {
    version = p.version,
    generation = p.gen,
    data = (p.gen == 3 and Sdk.gen3Data()) or {},
  }

  local run = Sdk.loadMod(MOD_PATH, opts)
  check(#run.errors == 0, p.version .. ": load error: " .. table.concat(run.errors, "\n"))
  check(run.mod and run.mod.state == "loaded", p.version .. ": mod loaded")

  if p.gen == 3 then
    local Moves = require("src.core.game3.battle.moves")
    local Damage = require("src.core.game3.battle.damage")
    local Types = require("src.core.game3.battle.types")

    -- Seed sample move rows for integration test
    local testRows = {
      [7] = { power = 75, type = 10, accuracy = 100, pp = 15 }, -- FIRE_PUNCH (Fire)
      [127] = { power = 80, type = 11, accuracy = 100, pp = 15 }, -- WATERFALL (Water)
      [348] = { power = 70, type = 12, accuracy = 100, pp = 15 }, -- LEAF_BLADE (Grass)
      [247] = { power = 80, type = 7, accuracy = 100, pp = 15 }, -- SHADOW_BALL (Ghost)
      [188] = { power = 90, type = 3, accuracy = 100, pp = 10 }, -- SLUDGE_BOMB (Poison)
      [63] = { power = 150, type = 0, accuracy = 90, pp = 5 }, -- HYPER_BEAM (Normal)
      [14] = { power = 0, type = 0, accuracy = 0, pp = 30 }, -- SWORDS_DANCE (Status)
      [89] = { power = 100, type = 4, accuracy = 100, pp = 10 }, -- EARTHQUAKE (Ground)
      [57] = { power = 95, type = 11, accuracy = 100, pp = 15 }, -- SURF (Water)
    }
    Moves._rom = testRows
    Moves._romLoaded = true
    Moves.setLinkRows(testRows)
    local byNum = {
      [7] = "FIRE_PUNCH", [127] = "WATERFALL", [348] = "LEAF_BLADE",
      [247] = "SHADOW_BALL", [188] = "SLUDGE_BOMB", [63] = "HYPER_BEAM",
      [14] = "SWORDS_DANCE", [89] = "EARTHQUAKE", [57] = "SURF",
    }
    for k, v in pairs(byNum) do Moves.BY_NUM[k] = v end
    Moves._numByName = {}
    for k, v in pairs(byNum) do Moves._numByName[v] = k end

    -- 1) Verify move metadata categories
    local fp = Moves.get("FIRE_PUNCH")
    check(fp.category == "physical", p.version .. ": FIRE_PUNCH is physical")

    local wf = Moves.get("WATERFALL")
    check(wf.category == "physical", p.version .. ": WATERFALL is physical")

    local lb = Moves.get("LEAF_BLADE")
    check(lb.category == "physical", p.version .. ": LEAF_BLADE is physical")

    local sb = Moves.get("SHADOW_BALL")
    check(sb.category == "special", p.version .. ": SHADOW_BALL is special")

    local slb = Moves.get("SLUDGE_BOMB")
    check(slb.category == "special", p.version .. ": SLUDGE_BOMB is special")

    local hb = Moves.get("HYPER_BEAM")
    check(hb.category == "special", p.version .. ": HYPER_BEAM is special")

    local sd = Moves.get("SWORDS_DANCE")
    check(sd.category == "status", p.version .. ": SWORDS_DANCE is status")

    local eq = Moves.get("EARTHQUAKE")
    check(eq.category == "physical", p.version .. ": EARTHQUAKE is physical")

    local surf = Moves.get("SURF")
    check(surf.category == "special", p.version .. ": SURF is special")

    -- 2) Verify Damage.base stat dependency
    local monBase = { level = 50, maxHp = 100, hp = 100, attack = 100, defense = 100, spAtk = 100, spDef = 100 }
    local monHighAtk = { level = 50, maxHp = 100, hp = 100, attack = 200, defense = 100, spAtk = 100, spDef = 100 }
    local monHighSpAtk = { level = 50, maxHp = 100, hp = 100, attack = 100, defense = 100, spAtk = 200, spDef = 100 }
    local defender = { level = 50, maxHp = 100, hp = 100, attack = 100, defense = 100, spAtk = 100, spDef = 100 }

    -- Fire Punch (Physical, Fire type)
    -- High Attack must increase damage; High SpAtk must NOT increase damage!
    local dmgFpBase = Damage.base(monBase, defender, fp, { noRandom = true })
    local dmgFpHighAtk = Damage.base(monHighAtk, defender, fp, { noRandom = true })
    local dmgFpHighSpAtk = Damage.base(monHighSpAtk, defender, fp, { noRandom = true })
    check(dmgFpHighAtk > dmgFpBase, p.version .. ": Fire Punch scales with Attack")
    check(dmgFpHighSpAtk == dmgFpBase, p.version .. ": Fire Punch does NOT scale with Special Attack")

    -- Shadow Ball (Special, Ghost type)
    -- High SpAtk must increase damage; High Attack must NOT increase damage!
    local dmgSbBase = Damage.base(monBase, defender, sb, { noRandom = true })
    local dmgSbHighAtk = Damage.base(monHighAtk, defender, sb, { noRandom = true })
    local dmgSbHighSpAtk = Damage.base(monHighSpAtk, defender, sb, { noRandom = true })
    check(dmgSbHighSpAtk > dmgSbBase, p.version .. ": Shadow Ball scales with Special Attack")
    check(dmgSbHighAtk == dmgSbBase, p.version .. ": Shadow Ball does NOT scale with Attack")

    -- 3) Verify screens: Reflect halves Physical moves; Light Screen halves Special moves
    local dmgFpReflect = Damage.base(monBase, defender, fp, { noRandom = true, reflect = true })
    check(dmgFpReflect < dmgFpBase, p.version .. ": Fire Punch reduced by Reflect")

    local dmgSbLightScreen = Damage.base(monBase, defender, sb, { noRandom = true, lightScreen = true })
    check(dmgSbLightScreen < dmgSbBase, p.version .. ": Shadow Ball reduced by Light Screen")

    -- 4) Verify battle.damage hook passes info.physical
    local ctxFp = { user = monBase, target = defender, move = fp, opts = { noRandom = true } }
    local dmgHookFp, infoHookFp = run.loader.hooks:call("battle.damage", function(c)
      local d, i = Damage.calc(c.user, c.target, c.move, c.opts)
      return d, i
    end, ctxFp)
    check(infoHookFp.physical == true, p.version .. ": battle.damage info.physical is true for Fire Punch")

    local ctxSb = { user = monBase, target = defender, move = sb, opts = { noRandom = true } }
    local dmgHookSb, infoHookSb = run.loader.hooks:call("battle.damage", function(c)
      local d, i = Damage.calc(c.user, c.target, c.move, c.opts)
      return d, i
    end, ctxSb)
    check(infoHookSb.physical == false, p.version .. ": battle.damage info.physical is false for Shadow Ball")

    -- 5) Rollback restores vanilla type-based behavior
    local restore = run.loader.exports.physical_special_split and run.loader.exports.physical_special_split.restore
    run.loader:_rollback("physical_special_split")
    if restore then restore() end

    local dmgFpVanillaBase = Damage.base(monBase, defender, fp, { noRandom = true })
    local dmgFpVanillaSpAtk = Damage.base(monHighSpAtk, defender, fp, { noRandom = true })
    check(dmgFpVanillaSpAtk > dmgFpVanillaBase, p.version .. ": Vanilla Fire Punch scales with Special Attack after rollback")
  end

  run.release()
  Runtime.reset()
end

print(string.format("Integration suite passed: %d assertions across %d profiles", total, #PROFILES))
