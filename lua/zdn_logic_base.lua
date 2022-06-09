require("zdn_util")
require("zdn_lib_moving")

function GetLogicState()
    local role = nx_value("role")
    if not nx_is_valid(role) then
        return 1
    end
    local visual = nx_value("game_visual")
    if not nx_is_valid(visual) then
        return 1
    end
    return visual:QueryRoleLogicState(role)
end

function GetRoleState()
    local role = nx_value("role")
    if not nx_is_valid(role) then
        return 0
    end
    if not nx_find_custom(role, "state") then
        return 0
    end
    return role.state
end

function GetChildForm(formPath)
    local gui = nx_value("gui")
    local childlist = gui.Desktop:GetChildControlList()
    for i = 1, table.maxn(childlist) do
        local control = childlist[i]
        if nx_is_valid(control) and nx_script_name(control) == formPath then
            return control
        end
    end
end

function GetPlayer()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    return client:GetPlayer()
end

function GetCurrentHour()
    local timeStamp = GetCurrentTimestamp()
    return timeStamp % 86400 / 3600 + 7
end

function GetCurrentHourHuman()
    local timeStamp = GetCurrentTimestamp()
    local hour = nx_int(nx_int(timeStamp % 86400 / 3600) + 7)
    local minute = nx_int(((timeStamp % 86400) % 3600) / 60)
    local hourStr = nx_string(hour)
    local minuteStr = nx_string(minute)
    if hour < nx_int(10) then
        hourStr = "0" .. hourStr
    end
    if minute < nx_int(10) then
        minuteStr = "0" .. minuteStr
    end
    return hourStr .. ":" .. minuteStr
end

function GetNextDayStartTimestamp()
    local timeStamp = GetCurrentTimestamp()
    return timeStamp - (timeStamp % 86400) + (7 * 3600) + 86400
end

function GetCurrentDayStartTimestamp()
    local timeStamp = GetCurrentTimestamp()
    return timeStamp - (timeStamp % 86400) + (7 * 3600)
end

function GetCurrentTimestamp()
    local msgDelay = nx_value("MessageDelay")
    if not (nx_is_valid(msgDelay)) then
        return 0
    end
    return msgDelay:GetServerSecond()
end

function GetNearestObj(...)
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return nil
    end
    local target = 0
    local shortestDistance = 200
    local objList = scene:GetSceneObjList()
    local argCnt = #arg
    for _, obj in pairs(objList) do
        if nx_is_valid(obj) then
            local validTarget = true
            if argCnt > 1 then
                for i = 2, argCnt do
                    if not nx_execute(nx_string(arg[1]), nx_string(arg[i]), obj) then
                        validTarget = false
                        i = cnt
                    end
                end
            end
            if validTarget then
                local d = GetDistanceToObj(obj)
                if d < shortestDistance then
                    shortestDistance = d
                    target = obj
                end
            end
        end
    end
    return target
end

function SelectTarget(obj)
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    local t = client:GetSceneObj(nx_string(player:QueryProp("LastObject")))
    if nx_id_equal(t, obj) then
        return
    end
    nx_execute("custom_sender", "custom_select", obj.Ident)
end

function TalkToNpc(npc, index)
    local form = nx_value("form_stage_main\\form_talk_movie")
    if not nx_is_valid(form) or not form.Visible then
        return
    end
    local ctl = form.mltbox_menu
    local funcid = ctl:GetItemKeyByIndex(index)
    nx_execute("form_stage_main\\form_talk_movie", "menu_select", funcid)
end
