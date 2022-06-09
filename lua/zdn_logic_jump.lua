require("zdn_util")
require("zdn_lib_moving")
--private
local function distance3d(bx, by, bz, dx, dy, dz)
    return math.sqrt((dx - bx) * (dx - bx) + (dy - by) * (dy - by) + (dz - bz) * (dz - bz))
end

local function setAngle(x, y, z)
    local role = nx_value("role")
    local scene_obj = nx_value("scene_obj")
    if not nx_is_valid(role) or not nx_is_valid(scene_obj) then
        return
    end
    scene_obj:SceneObjAdjustAngle(role, x, z)
end

local function isFlying(...)
    local target_role = nx_value("role")
    local link_role = target_role:GetLinkObject("actor_role")
    if nx_is_valid(link_role) then
        target_role = link_role
    end
    local action_list = target_role:GetActionBlendList()
    for i, action in pairs(action_list) do
        if string.find(action, "jump") ~= nil then
            return true
        end
    end
    return false
end

local function collide(...)
    local game_visual = nx_value("game_visual")
    local role = nx_value("role")
    if not nx_is_valid(game_visual) or not nx_is_valid(role) then
        return
    end
    game_visual:SetRoleMoveDistance(role, 1)
    game_visual:SetRoleMaxMoveDistance(role, 1)
    game_visual:SwitchPlayerState(role, 1, 103)
    role.state = "zdn_jump"
end

local function setCollide(x, y, z)
    local game_visual = nx_value("game_visual")
    local role = nx_value("role")
    if not nx_is_valid(game_visual) or not nx_is_valid(role) then
        return
    end
    game_visual:SetRoleMoveDestX(role, x)
    game_visual:SetRoleMoveDestY(role, y)
    game_visual:SetRoleMoveDestZ(role, z)
end

local function flyToPos(cur_x, cur_y, cur_z, x, y, z)
    local role = nx_value("role")
    local scene_obj = nx_value("scene_obj")
    if not nx_is_valid(scene_obj) or not nx_is_valid(role) then
        return
    end
    local dis = distance3d(role.PositionX, role.PositionY, role.PositionZ, cur_x, cur_y, cur_z)
    if not (cur_x == 0 and cur_y == 0 and cur_z == 0) and dis > 6 then
        return
    end

    nx_execute("zdn_logic_skill", "switchFly")
    nx_pause(0.2)
    y = y + 0.1
    setAngle(x, y, z)
    local temp_angle = role.AngleY
    nx_call("player_state\\state_input", "emit_player_input", role, 21, 36, x, y, z, 0, 3)
    role.state = "zdn_jump"
    nx_pause(2.8)
    role.move_dest_orient = temp_angle
    setCollide(x, y, z)
    collide()
    local out_time = TimerInit()
    while TimerDiff(out_time) < 3 do
        nx_pause(0.1)
        if not isFlying() then
            return
        end
    end
end

local function getVisualObj(obj)
    if not nx_is_valid(obj) then
        return
    end
    return nx_value("game_visual"):GetSceneObj(obj.Ident)
end

function FlyToObj(obj)
    local pX, pY, pZ = GetPlayerPosition()
    local vObj = getVisualObj(obj)
    if not nx_is_valid(vObj) then
        return
    end
    local posX = vObj.PositionX
    local posY = vObj.PositionY
    local posZ = vObj.PositionZ
    flyToPos(pX, pY, pZ, posX, posY, posZ)
end

function FlyToPos(posX, posY, posZ)
    local pX, pY, pZ = GetPlayerPosition()
    flyToPos(pX, pY, pZ, posX, posY, posZ)
end

-- die instantly
-- function JumpInstantly(x1, y1, z1)
--     local stepPause = 2
--     local stepDistance = 80
--     local x = nx_float(x1)
--     local y = nx_float(y1)
--     local z = nx_float(z1)
--     local game_visual = nx_value("game_visual")
--     if not nx_is_valid(game_visual) then
--         return false
--     end
--     local role = nx_value("role")
--     if not nx_is_valid(role) then
--         return false
--     end
--     local scene_obj = nx_value("scene_obj")
--     if not nx_is_valid(scene_obj) then
--         return false
--     end
--     scene_obj:SceneObjAdjustAngle(role, x, z)
--     role.move_dest_orient = role.AngleY
--     role.server_pos_can_accept = true
--     role:SetPosition(role.PositionX, y, role.PositionZ)
--     game_visual:SetRoleMoveDestX(role, x)
--     game_visual:SetRoleMoveDestY(role, y)
--     game_visual:SetRoleMoveDestZ(role, z)
--     game_visual:SetRoleMoveDistance(role, stepDistance)
--     game_visual:SetRoleMaxMoveDistance(role, stepDistance)
--     game_visual:SwitchPlayerState(role, 1, 103)
--     nx_pause(stepPause)
-- end
