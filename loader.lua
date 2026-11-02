-- PrimoDax Hub | Loader
-- Created By: BoboyTagaAquarius

local GAMES = {
    [100283815455755] = "https://raw.githubusercontent.com/Ryu533748/Primodax/main/script.lua",
    [118805555015549] = "https://raw.githubusercontent.com/Ryu533748/Primodax/main/LootToForge/script.lua",
    [104037817505797] = "https://raw.githubusercontent.com/Ryu533748/Primodax/main/FatForLoot/script.lua",
}

local url = GAMES[game.PlaceId]

if not url then
    warn("[PrimoDax Hub] Game not supported. PlaceId: " .. tostring(game.PlaceId))
    return
end

local ok, err = pcall(function()
    loadstring(game:HttpGet(url, true))()
end)

if not ok then
    warn("[PrimoDax Hub] Failed to load: " .. tostring(err))
end
