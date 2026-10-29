-- Physical/Special Split Mod
-- Decouples damage calculations from elemental move types, applying the
-- official Generation 4+ per-move physical/special/status category split.
-- The logic lives in the bundled `move_categories` lib (lib/move_categories/); this file only wires it.
return function(mod)
  local use = assert(load(assert(mod:read("lib/init.lua"), "missing lib/init.lua"), "@lib/init.lua"))(mod)
  use("move_categories").install(mod)
end
