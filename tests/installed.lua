package.path = "./?.lua;./?/init.lua;" .. package.path
love = {
  data = {
    compress = function(_, _, bytes, level) return deflate(bytes, level) end,
    decompress = function(_, _, bytes) return inflate(bytes) end,
  },
  graphics = {
    newQuad = function() return {} end,
    newImage = function() return { getDimensions = function() return 256, 256 end } end,
  },
}
local GameVersion = require("src.core.GameVersion")
GameVersion.set(TEST_VERSION)
assert(require("src.core.Version").engine == INSTALLED_ENGINE, "staged engine is not the installed one")

local fs, overlay = {}, {}
function fs.read(p) return overlay[p] or fs_read(p) end
function fs.getInfo(p) return overlay[p] and { type = "file" } or fs_info(p) end
function fs.getDirectoryItems(p) return fs_list(p) end
function fs.load(p)
  local bytes = fs.read(p)
  return bytes and loadstring(bytes, "@" .. p)
end
function fs.write(p, bytes) overlay[p] = bytes return true end
function fs.createDirectory() return true end
fs.root = "."

local generation = GameVersion.generation()
local Loader = require("src.mods.Loader")
local game = { data = {} }

if generation == 3 then
  local Dataset = require("src.core.game3.dataset")
  Dataset.cacheRootOverride = CACHE_ROOT
  assert(Dataset.hydrate(game), "installed dataset did not hydrate")
else
  local dir = TEST_VERSION .. "/data/generated/"
  for _, name in ipairs({ "constants", "moves", "items", "pokemon", "type_chart" }) do
    local chunk = fs.load(dir .. name .. ".lua")
    if chunk then game.data[name] = chunk() end
  end
end

local loader = Loader.new({ fs = fs, generation = generation })
loader:load(game.data)
assert(#loader.errors == 0, table.concat(loader.errors, "\n"))
local mod = loader.mods.physical_special_split
assert(mod and mod.state == "loaded", "installed mod did not load for " .. TEST_VERSION)

if generation == 3 then
  local Moves = require("src.core.game3.battle.moves")
  local Damage = require("src.core.game3.battle.damage")

  local fp = Moves.get("FIRE_PUNCH")
  assert(fp.category == "physical", "FIRE_PUNCH not physical")

  local wf = Moves.get("WATERFALL")
  assert(wf.category == "physical", "WATERFALL not physical")

  local sb = Moves.get("SHADOW_BALL")
  assert(sb.category == "special", "SHADOW_BALL not special")

  local slb = Moves.get("SLUDGE_BOMB")
  assert(slb.category == "special", "SLUDGE_BOMB not special")

  local hb = Moves.get("HYPER_BEAM")
  assert(hb.category == "special", "HYPER_BEAM not special")

  local sd = Moves.get("SWORDS_DANCE")
  assert(sd.category == "status", "SWORDS_DANCE not status")

  local eq = Moves.get("EARTHQUAKE")
  assert(eq.category == "physical", "EARTHQUAKE not physical")

  local surf = Moves.get("SURF")
  assert(surf.category == "special", "SURF not special")

  -- Damage scaling tests
  local monBase = { level = 50, maxHp = 100, hp = 100, attack = 100, defense = 100, spAtk = 100, spDef = 100 }
  local monHighAtk = { level = 50, maxHp = 100, hp = 100, attack = 200, defense = 100, spAtk = 100, spDef = 100 }
  local monHighSpAtk = { level = 50, maxHp = 100, hp = 100, attack = 100, defense = 100, spAtk = 200, spDef = 100 }
  local defender = { level = 50, maxHp = 100, hp = 100, attack = 100, defense = 100, spAtk = 100, spDef = 100 }

  local dmgFpBase = Damage.base(monBase, defender, fp, { noRandom = true })
  local dmgFpHighAtk = Damage.base(monHighAtk, defender, fp, { noRandom = true })
  local dmgFpHighSpAtk = Damage.base(monHighSpAtk, defender, fp, { noRandom = true })
  assert(dmgFpHighAtk > dmgFpBase, "Fire Punch does not scale with Attack")
  assert(dmgFpHighSpAtk == dmgFpBase, "Fire Punch scales with Special Attack")

  local dmgSbBase = Damage.base(monBase, defender, sb, { noRandom = true })
  local dmgSbHighAtk = Damage.base(monHighAtk, defender, sb, { noRandom = true })
  local dmgSbHighSpAtk = Damage.base(monHighSpAtk, defender, sb, { noRandom = true })
  assert(dmgSbHighSpAtk > dmgSbBase, "Shadow Ball does not scale with Special Attack")
  assert(dmgSbHighAtk == dmgSbBase, "Shadow Ball scales with Attack")

  local ctxFp = { user = monBase, target = defender, move = fp, opts = { noRandom = true } }
  local _, infoFp = loader.hooks:call("battle.damage", function(c)
    local d, i = Damage.calc(c.user, c.target, c.move, c.opts)
    return d, i
  end, ctxFp)
  assert(infoFp.physical == true, "battle.damage info.physical not true for Fire Punch")

  local ctxSb = { user = monBase, target = defender, move = sb, opts = { noRandom = true } }
  local _, infoSb = loader.hooks:call("battle.damage", function(c)
    local d, i = Damage.calc(c.user, c.target, c.move, c.opts)
    return d, i
  end, ctxSb)
  assert(infoSb.physical == false, "battle.damage info.physical not false for Shadow Ball")

  -- Rollback
  local restore = loader.exports.physical_special_split and loader.exports.physical_special_split.restore
  loader:_rollback("physical_special_split")
  if restore then restore() end

  local dmgFpVanillaBase = Damage.base(monBase, defender, fp, { noRandom = true })
  local dmgFpVanillaSpAtk = Damage.base(monHighSpAtk, defender, fp, { noRandom = true })
  assert(dmgFpVanillaSpAtk > dmgFpVanillaBase, "Rollback did not restore vanilla Special Fire Punch")

  print("PASS installed " .. TEST_VERSION .. ": Physical/Special split and rollback")
  return
end

if generation == 1 then
  local Damage1 = require("src.battle.Damage")
  local moveFp = { id = "FIRE_PUNCH", type = "FIRE", power = 75 }
  local moveSb = { id = "SHADOW_BALL", type = "GHOST", power = 80 }

  local ctxFp = { move = moveFp, opts = {} }
  local _, infoFp = loader.hooks:call("battle.damage", function(c)
    return 50, { physical = (c.move.category == "physical") }
  end, ctxFp)
  assert(infoFp.physical == true, "Gen 1 Fire Punch not physical")

  local ctxSb = { move = moveSb, opts = {} }
  local _, infoSb = loader.hooks:call("battle.damage", function(c)
    return 50, { physical = (c.move.category == "physical") }
  end, ctxSb)
  assert(infoSb.physical == false, "Gen 1 Shadow Ball not special")

  local restore = loader.exports.physical_special_split and loader.exports.physical_special_split.restore
  loader:_rollback("physical_special_split")
  if restore then restore() end

  print("PASS installed " .. TEST_VERSION .. ": Gen 1 Physical/Special split hook")
  return
end

if generation == 2 then
  local Damage2 = require("src.battle.gen2.Damage")
  local moveFp = { id = "FIRE_PUNCH", type = "FIRE", power = 75 }
  local moveSb = { id = "SHADOW_BALL", type = "GHOST", power = 80 }

  local ctxFp = { move = moveFp, opts = { moveType = "FIRE", power = 75 } }
  local _, infoFp = loader.hooks:call("battle.damage", function(c)
    return 50, { physical = (c.move.category == "physical") }
  end, ctxFp)
  assert(infoFp.physical == true, "Gen 2 Fire Punch not physical")

  local ctxSb = { move = moveSb, opts = { moveType = "GHOST", power = 80 } }
  local _, infoSb = loader.hooks:call("battle.damage", function(c)
    return 50, { physical = (c.move.category == "physical") }
  end, ctxSb)
  assert(infoSb.physical == false, "Gen 2 Shadow Ball not special")

  local restore = loader.exports.physical_special_split and loader.exports.physical_special_split.restore
  loader:_rollback("physical_special_split")
  if restore then restore() end

  print("PASS installed " .. TEST_VERSION .. ": Gen 2 Physical/Special split hook")
  return
end
