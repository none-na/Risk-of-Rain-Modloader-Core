local iwrap = GMInstance.iwrap
local function siwrap(id)
    -- same as iwrap but for instances in their destroy event
    VerifiedInstances[id] = 2
    return iwrap(id, true)
end

-- Items
AddCallback("onItemRoll", {
    types = {RoRItem.poolFromID, RoRItem.fromObjID},
    callTypes = {"ItemPool", "Item"},
    returnType = "Item", returnFunc = RoRItem.toID}) -- Pool, item
AddCallback("onItemDropped") -- Drop type
AddCallback("onItemInit", {
    types = {iwrap},
    callTypes = {"ItemInstance"}}) -- Item ID
AddCallback("onItemPickup",{
    types = {iwrap, iwrap},
    callTypes = {"ItemInstance", "PlayerInstance"}}) -- Item ID, Player ID
AddCallback("onUseItemUse", {
    types = {iwrap, RoRItem.fromObjID},
    callTypes = {"PlayerInstance", "Item"}}) -- Player ID, Item
AddCallback("postUseItemUse", {
    types = {iwrap, RoRItem.fromObjID},
    callTypes = {"PlayerInstance", "Item"}}) -- Player ID, Item

--  Actor
AddCallback("onNPCDeath", {
    types = {siwrap},
    callTypes = {"ActorInstance"}}) -- id,
AddCallback("onNPCDeathProc", {
    types = {siwrap, iwrap},
    callTypes = {"ActorInstance", "PlayerInstance"}}) -- id, player
AddCallback("onActorInit", {
    types = {iwrap},
    callTypes = {"ActorInstance"}}) -- id
AddCallback("onDamage", {
    types = {iwrap, tonumber, iwrap},
    callTypes = {"ActorInstance", "number", "Instance"},
    cancellable = true}) -- id

--  Player
AddCallback("onPlayerInit", {
    types = {iwrap},
    callTypes = {"PlayerInstance"}}) -- id
AddCallback("onPlayerStep", {
    types = {iwrap},
    callTypes = {"PlayerInstance"}}) -- id
AddCallback("onPlayerDrawBelow", {
    types = {iwrap},
    callTypes = {"PlayerInstance"}}) -- id
AddCallback("onPlayerDraw", {
    types = {iwrap},
    callTypes = {"PlayerInstance"}}) -- id
AddCallback("onPlayerDrawAbove", {
    types = {iwrap},
    callTypes = {"PlayerInstance"}}) -- id
AddCallback("onPlayerLevelUp", {
    types = {iwrap},
    callTypes = {"PlayerInstance"}}) -- id
AddCallback("onPlayerDeath", {
    types = {iwrap},
    callTypes = {"PlayerInstance"}}) -- id
AddCallback("onPlayerHUDDraw", {
    types = {iwrap},
    callTypes = {"PlayerInstance", "number", "number"}}) -- id, x, y

-- Damagers
AddCallback("onFire", {
    types = {iwrap},
    callTypes = {"DamagerInstance"}}) -- Bullet ID
AddCallback("onHit", {
    types = {iwrap, iwrap},
    callTypes = {"DamagerInstance", "ActorInstance", "number", "number"}}) -- Bullet ID, Hit ID, x, y
AddCallback("preHit", {
    types = {iwrap, iwrap},
    callTypes = {"DamagerInstance", "ActorInstance"}}) -- Bullet ID, Hit ID
AddCallback("postHit", {
    types = {iwrap, iwrap},
    callTypes = {"DamagerInstance"}}) -- Bullet ID
AddCallback("onImpact", {
    types = {iwrap},
    callTypes = {"DamagerInstance", "number", "number"}}) -- Bullet ID, x, y

--  Map objects
AddCallback("onMapObjectActivate", {
    types = {iwrap, iwrap},
    callTypes = {"Instance"}, {"PlayerInstance"}}) -- id, activator

--  Game
AddCallback("onStageEntry")
AddCallback("onSecond", {callTypes = {"number", "number"}}) -- Minute, second
AddCallback("onMinute", {callTypes = {"number", "number"}}) -- Minute, second
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
AddCallback("onCameraUpdate")

AddCallback("globalStep", {types = {GMRoom.fromID}})
AddCallback("globalPreStep", {types = {GMRoom.fromID}})
AddCallback("globalPostStep", {types = {GMRoom.fromID}})
AddCallback("globalRoomStart", {types = {GMRoom.fromID}})
AddCallback("globalRoomEnd", {types = {GMRoom.fromID}})
