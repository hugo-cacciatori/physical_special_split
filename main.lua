-- Physical/Special Split Mod
-- Decouples damage calculations from elemental move types, applying the
-- official Generation 4+ per-move physical/special/status category split.

local OVERRIDES = {
  -- === SPECIAL moves of historically PHYSICAL types ===
  -- Normal
  RAZOR_WIND = "special",
  SONIC_BOOM = "special",
  SONICBOOM = "special",
  HYPER_BEAM = "special",
  TRI_ATTACK = "special",
  SNORE = "special",
  UPROAR = "special",
  SWIFT = "special",
  WEATHER_BALL = "special",
  HIDDEN_POWER = "special",

  -- Ghost
  NIGHT_SHADE = "special",
  SHADOW_BALL = "special",

  -- Poison
  ACID = "special",
  SLUDGE = "special",
  SMOG = "special",
  SLUDGE_BOMB = "special",

  -- Ground
  MUD_SLAP = "special",
  MUD_SHOT = "special",

  -- Rock
  ANCIENT_POWER = "special",
  ANCIENTPOWER = "special",

  -- Bug
  SILVER_WIND = "special",
  SIGNAL_BEAM = "special",

  -- Steel
  DOOM_DESIRE = "special",

  -- Flying
  GUST = "special",
  AIR_CUTTER = "special",
  AEROBLAST = "special",

  -- === PHYSICAL moves of historically SPECIAL types ===
  -- Fire
  FIRE_PUNCH = "physical",
  FLAME_WHEEL = "physical",
  SACRED_FIRE = "physical",
  BLAZE_KICK = "physical",

  -- Water
  WATERFALL = "physical",
  CLAMP = "physical",
  CRABHAMMER = "physical",
  DIVE = "physical",

  -- Grass
  VINE_WHIP = "physical",
  RAZOR_LEAF = "physical",
  LEAF_BLADE = "physical",
  BULLET_SEED = "physical",
  NEEDLE_ARM = "physical",

  -- Electric
  THUNDER_PUNCH = "physical",
  THUNDERPUNCH = "physical",
  SPARK = "physical",
  VOLT_TACKLE = "physical",

  -- Ice
  ICE_PUNCH = "physical",
  ICICLE_SPEAR = "physical",
  ICE_BALL = "physical",

  -- Dark
  BITE = "physical",
  THIEF = "physical",
  FEINT_ATTACK = "physical",
  FAINT_ATTACK = "physical",
  PURSUIT = "physical",
  CRUNCH = "physical",
  BEAT_UP = "physical",
  KNOCK_OFF = "physical",

  -- Dragon
  DRAGON_CLAW = "physical",
  OUTRAGE = "physical",
}

-- Numeric ID overrides for Gen 3 ROM moves
local NUMERIC_OVERRIDES = {
  -- Normal
  [13] = "special",  -- RAZOR_WIND
  [49] = "special",  -- SONICBOOM
  [63] = "special",  -- HYPER_BEAM
  [129] = "special", -- SWIFT
  [161] = "special", -- TRI_ATTACK
  [173] = "special", -- SNORE
  [237] = "special", -- HIDDEN_POWER
  [253] = "special", -- UPROAR
  [311] = "special", -- WEATHER_BALL
  -- Ghost
  [101] = "special", -- NIGHT_SHADE
  [247] = "special", -- SHADOW_BALL
  -- Poison
  [51] = "special",  -- ACID
  [123] = "special", -- SMOG
  [124] = "special", -- SLUDGE
  [188] = "special", -- SLUDGE_BOMB
  -- Ground
  [189] = "special", -- MUD_SLAP
  [341] = "special", -- MUD_SHOT
  -- Rock
  [246] = "special", -- ANCIENTPOWER
  -- Bug
  [318] = "special", -- SILVER_WIND
  [324] = "special", -- SIGNAL_BEAM
  -- Steel
  [353] = "special", -- DOOM_DESIRE
  -- Flying
  [16] = "special",  -- GUST
  [177] = "special", -- AEROBLAST
  [314] = "special", -- AIR_CUTTER

  -- Fire
  [7] = "physical",   -- FIRE_PUNCH
  [172] = "physical", -- FLAME_WHEEL
  [221] = "physical", -- SACRED_FIRE
  [299] = "physical", -- BLAZE_KICK
  -- Water
  [127] = "physical", -- WATERFALL
  [128] = "physical", -- CLAMP
  [152] = "physical", -- CRABHAMMER
  [291] = "physical", -- DIVE
  -- Grass
  [22] = "physical",  -- VINE_WHIP
  [75] = "physical",  -- RAZOR_LEAF
  [302] = "physical", -- NEEDLE_ARM
  [331] = "physical", -- BULLET_SEED
  [348] = "physical", -- LEAF_BLADE
  -- Electric
  [9] = "physical",   -- THUNDERPUNCH
  [209] = "physical", -- SPARK
  [344] = "physical", -- VOLT_TACKLE
  -- Ice
  [8] = "physical",   -- ICE_PUNCH
  [301] = "physical", -- ICE_BALL
  [333] = "physical", -- ICICLE_SPEAR
  -- Dark
  [44] = "physical",  -- BITE
  [168] = "physical", -- THIEF
  [185] = "physical", -- FEINT_ATTACK
  [228] = "physical", -- PURSUIT
  [242] = "physical", -- CRUNCH
  [251] = "physical", -- BEAT_UP
  [282] = "physical", -- KNOCK_OFF
  -- Dragon
  [200] = "physical", -- OUTRAGE
  [337] = "physical", -- DRAGON_CLAW
}

local NATIVE_PHYSICAL_TYPES = {
  [0] = true,  -- NORMAL
  [1] = true,  -- FIGHTING
  [2] = true,  -- FLYING
  [3] = true,  -- POISON
  [4] = true,  -- GROUND
  [5] = true,  -- ROCK
  [6] = true,  -- BUG
  [7] = true,  -- GHOST
  [8] = true,  -- STEEL
  NORMAL = true, FIGHTING = true, FLYING = true, POISON = true,
  GROUND = true, ROCK = true, BUG = true, GHOST = true, STEEL = true,
}

local function normalizeMoveKey(moveId)
  if type(moveId) == "table" then
    moveId = moveId.id or moveId.move or moveId.moveId or moveId.name or moveId.num or moveId[1]
  end
  if type(moveId) == "string" then
    return moveId:upper():gsub("%s+", "_"):gsub("%-", "_")
  end
  return moveId
end

local function getCategory(move, moveType, power)
  local moveKey = normalizeMoveKey(move)
  local num = tonumber(moveKey) or (type(move) == "table" and tonumber(move.numId or move.num))

  -- Power <= 0 moves are Status (unless fixed damage effects)
  if power ~= nil and tonumber(power) <= 0 then
    local eff = (type(move) == "table" and move.effect) or nil
    -- Fixed damage moves like Night Shade / SonicBoom / Dragon Rage have power 0 in ROM
    if moveKey == "NIGHT_SHADE" or num == 101 or moveKey == "SONICBOOM" or num == 49 then
      return "special"
    end
    if moveKey == "SEISMIC_TOSS" or num == 69 or moveKey == "SUPER_FANG" or num == 162 or moveKey == "COUNTER" or num == 68 then
      return "physical"
    end
    if eff == nil then
      return "status"
    end
  end

  if num and NUMERIC_OVERRIDES[num] then
    return NUMERIC_OVERRIDES[num]
  end

  if type(moveKey) == "string" and OVERRIDES[moveKey] then
    return OVERRIDES[moveKey]
  end

  -- Fallback to native type category
  if moveType ~= nil then
    local mtNum = tonumber(moveType)
    if mtNum ~= nil then
      return NATIVE_PHYSICAL_TYPES[mtNum] and "physical" or "special"
    end
    if type(moveType) == "string" then
      local s = moveType:upper():gsub("%s+", "_")
      return NATIVE_PHYSICAL_TYPES[s] and "physical" or "special"
    end
  end

  return "physical"
end

local activeMoveCategory = nil

return function(mod)
  if not (mod and mod.hooks and mod.hooks.wrap) then return end

  -- 1) Hook unified `battle.damage`
  mod.hooks:wrap("battle.damage", function(nextFn, ctx)
    local move = ctx and (ctx.move or ctx.moveId)
    local mType = ctx and ctx.opts and ctx.opts.moveType
    if not mType and type(ctx.move) == "table" then mType = ctx.move.type end
    local pwr = ctx and ctx.opts and ctx.opts.power
    if not pwr and type(ctx.move) == "table" then pwr = ctx.move.power end

    local cat = getCategory(move, mType, pwr)
    local prevCat = activeMoveCategory
    activeMoveCategory = cat

    local isPhys = (cat == "physical")
    if type(ctx.move) == "table" then
      ctx.move.category = cat
    end
    if ctx.opts and type(ctx.opts) == "table" then
      ctx.opts.category = cat
    end

    local dmg, info = nextFn(ctx)
    activeMoveCategory = prevCat

    if type(info) == "table" then
      info.physical = isPhys
      info.category = cat
    end

    return dmg, info
  end)

  -- 2) Wrap Types.isPhysical in Gen 3
  local okT, Types3 = pcall(require, "src.core.game3.battle.types")
  local origTypes3IsPhys = okT and Types3 and Types3.isPhysical
  if okT and Types3 and origTypes3IsPhys then
    Types3.isPhysical = function(typeId)
      if activeMoveCategory ~= nil then
        return activeMoveCategory == "physical"
      end
      return origTypes3IsPhys(typeId)
    end
  end

  -- 3) Wrap Moves.get in Gen 3
  local okM, Moves3 = pcall(require, "src.core.game3.battle.moves")
  local origMoves3Get = okM and Moves3 and Moves3.get
  if okM and Moves3 and origMoves3Get then
    Moves3.get = function(moveId)
      local m = origMoves3Get(moveId)
      if m then
        m.category = getCategory(m.id or m.numId or moveId, m.type, m.power)
      end
      return m
    end
  end

  -- 4) Wrap Damage.base in Gen 3
  local okD, Damage3 = pcall(require, "src.core.game3.battle.damage")
  local origDamage3Base = okD and Damage3 and Damage3.base
  if okD and Damage3 and origDamage3Base then
    Damage3.base = function(attacker, defender, move, opts)
      local moveKey = move and (move.id or move.numId)
      local mType = (opts and opts.moveType) or (move and move.type)
      local pwr = (opts and opts.power) or (move and move.power)
      local cat = getCategory(moveKey, mType, pwr)

      local prev = activeMoveCategory
      activeMoveCategory = cat
      local ok, res = pcall(origDamage3Base, attacker, defender, move, opts)
      activeMoveCategory = prev

      if not ok then error(res, 0) end
      return res
    end
  end

  -- 5) Wrap Damage.isPhysical in Gen 2
  local okG2, Damage2 = pcall(require, "src.battle.gen2.Damage")
  local origDamage2IsPhys = okG2 and Damage2 and Damage2.isPhysical
  if okG2 and Damage2 and origDamage2IsPhys then
    Damage2.isPhysical = function(moveType, types)
      if activeMoveCategory ~= nil then
        return activeMoveCategory == "physical"
      end
      return origDamage2IsPhys(moveType, types)
    end
  end

  -- Clean rollback export
  local function restore()
    if Types3 and origTypes3IsPhys then Types3.isPhysical = origTypes3IsPhys end
    if Moves3 and origMoves3Get then Moves3.get = origMoves3Get end
    if Damage3 and origDamage3Base then Damage3.base = origDamage3Base end
    if Damage2 and origDamage2IsPhys then Damage2.isPhysical = origDamage2IsPhys end
    activeMoveCategory = nil
  end

  mod.exports = mod.exports or {}
  mod.exports.restore = restore
end
