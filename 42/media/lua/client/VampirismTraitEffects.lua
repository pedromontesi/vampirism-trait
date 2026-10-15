require "MF_ISMoodle"
local Registries = require("VampirismTrait_registries")

-- Vampirism: every 3 zombies killed grants a % of health.
-- The moodle (Moodle Framework) appears after the first kill; the chevrons show the progress.

-- ================= CONFIG =================
local KILLS_NEEDED = 3     -- zombies killed per cycle
local HEAL_PERCENT = 1.00  -- fraction healed when a cycle completes (1.00 = 100%)
-- ==========================================

local MOODLE = "Vampirism"   -- must match media/ui/Vampirism.png and the Moodles translation keys
MF.createMoodle(MOODLE)

local MD_KEY = "VampirismTrait"

local function getState(player)
    local md = player:getModData()
    md[MD_KEY] = md[MD_KEY] or { progress = 0 }
    return md[MD_KEY]
end

-- value 0.5 = hidden; above 0.6 the moodle is shown (see Moodle Framework thresholds)
local function syncMoodle(player, state)
    local moodle = MF.getMoodle(MOODLE, player:getPlayerNum())
    if not moodle then return end

    local value = 0.5
    if state.progress > 0 then
        value = 0.5 + 0.5 * state.progress / KILLS_NEEDED
    end
    if moodle:getValue() ~= value then
        moodle:setChevronCount(state.progress)
        moodle:setValue(value)
    end
end

local function healFraction(player, fraction)
    local bd = player:getBodyDamage()

    -- health bar
    bd:AddGeneralHealth(100 * fraction)

    -- problems: shrink the remaining time of fractures
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        local fracture = part:getFractureTime()
        if fracture > 0 then
            part:setFractureTime(fracture * (1 - fraction))
        end
    end
end

local function onPlayerUpdate(player)
    if not player or not player:isLocalPlayer() then return end
    if not player:hasTrait(Registries.traits.Vampirism) then return end

    local state = getState(player)
    local total = player:getZombieKills()

    -- first read (or the game counter was reset): just sync
    if state.last == nil or total < state.last then
        state.last = total
    else
        local delta = total - state.last
        if delta > 0 then
            state.last = total
            state.progress = state.progress + delta
            while state.progress >= KILLS_NEEDED do
                healFraction(player, HEAL_PERCENT)
                state.progress = state.progress - KILLS_NEEDED
            end
        end
    end

    syncMoodle(player, state)
end
Events.OnPlayerUpdate.Add(onPlayerUpdate)
