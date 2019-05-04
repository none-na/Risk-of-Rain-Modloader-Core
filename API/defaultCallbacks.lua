local iwrap = GMInstance.iwrap
local function siwrap(id)
    -- same as iwrap but for instances in their destroy event
    VerifiedInstances[id] = 2
    return iwrap(id)
end

-- Items
AddCallback("onItemRoll", {types = {RoRItem.poolFromID, RoRItem.fromObjID}, returnType = "Item", returnFunc = RoRItem.toID}) -- Pool, item
AddCallback("onItemDropped") -- Drop type
AddCallback("onItemInit", {types = {iwrap}}) -- Item ID
AddCallback("onItemPickup", {types = {iwrap, iwrap}}) -- Item ID, Player ID
AddCallback("onUseItemUse", {types = {iwrap, RoRItem.fromObjID}}) -- Player ID, Item
AddCallback("postUseItemUse", {types = {iwrap, RoRItem.fromObjID}}) -- Player ID, Item

--  Actor
AddCallback("onNPCDeath", {types = {siwrap}}) -- id,
AddCallback("onNPCDeathProc", {types = {siwrap, iwrap}}) -- id, player
AddCallback("onActorInit", {types = {iwrap}}) -- id

--  Player
AddCallback("onPlayerInit", {types = {iwrap}}) -- id
AddCallback("onPlayerStep", {types = {iwrap}}) -- id
AddCallback("onPlayerDrawBelow", {types = {iwrap}}) -- id
AddCallback("onPlayerDraw", {types = {iwrap}}) -- id
AddCallback("onPlayerDrawAbove", {types = {iwrap}}) -- id
AddCallback("onPlayerLevelUp", {types = {iwrap}}) -- id
AddCallback("onPlayerDeath", {types = {iwrap}}) -- id
AddCallback("onPlayerHUDDraw", {types = {iwrap}}) -- id, x, y

-- Damagers
AddCallback("onFire", {types = {iwrap}}) -- Bullet ID
AddCallback("onHit", {types = {iwrap, iwrap}}) -- Bullet ID, Hit ID, x, y
AddCallback("preHit", {types = {iwrap, iwrap}}) -- Bullet ID, Hit ID
AddCallback("postHit", {types = {iwrap, iwrap}}) -- Bullet ID
AddCallback("onImpact", {types = {iwrap}}) -- Bullet ID

--  Map objects
AddCallback("onMapObjectActivate", {types = {iwrap, iwrap}}) -- id, activator

--  Game
AddCallback("onStageEntry")
AddCallback("onMinuteChange")
AddCallback("onGameStart")
AddCallback("onGameEnd")

--  Global
AddCallback("onStep")
AddCallback("preStep")
AddCallback("postStep")
AddCallback("onDraw")
AddCallback("onHUDDraw")
AddCallback("preHUDDraw")
AddCallback("onLoad", {noGML = true})
AddCallback("postLoad", {noGML = true})
