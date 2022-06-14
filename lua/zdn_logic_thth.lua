require("util_functions")
require("util_gui")
require("form_stage_main\\form_main\\form_main_shortcut_extraskill")
require("zdn_util")
require("zdn_lib_moving")
require("zdn_lib_jump")
local THICH_QUAN_FORM_PATH = "form_stage_main\\form_tiguan\\form_tiguan_one"
require(THICH_QUAN_FORM_PATH)

local Running = false
local BossData = {}
local ThichQuanData = {}
local ErrorBoss = {}
local Map = {}
local ThichQuanConfig = {}

local CurrentLevel = 1
local LEVEL_MAX_TURN = {
    [1] = 7,
    [2] = 6,
    [3] = 4,
    [4] = 4
}
local LastBossId = ""
local NeedResetTurnFlg = false

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    Running = true
    NeedResetTurnFlg = false
    nx_execute("zdn_logic_skill", "LeaveTeam")
    nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
    nx_execute("zdn_logic_skill", "PauseAttack")
    nx_execute("Listener", "addListen", nx_current(), "dttiaozhanjiemian_3", "onOutOfTime", -1)
    loadConfig()
    loadThichQuanData()
    while Running do
        loopThth()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    StopFindPath()
    nx_execute("Listener", "removeListen", nx_current(), "dttiaozhanjiemian_3", "onOutOfTime")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopThth()
    if isLoading() then
        return
    end

    if nx_execute("zdn_logic_skill", "IsPlayerDead") then
        endGame()
        return
    end

    checkLagSkill()

    if isInBossScene() then
        doScene()
    else
        enterScene()
    end
end

function doComplete()
    if TimerDiff(AttackTimer) < 2 then
        return
    end
    -- TODO get prize box
    if true then
        leaveBossScene()
        LoadingTimer = TimerInit() + 20
        return
    end
end

function doScene()
    if nx_execute("zdn_logic_vat_pham", "IsDroppickShowed") then
        nx_execute("zdn_logic_vat_pham", "PickAllDropItem")
        return
    end
    if isComplete() then
        doComplete()
    else
        if not isInBossScene() then
            return
        end
        if CanJump then
            jumpToBoss()
        else
            findAndKillBoss()
        end
        AttackTimer = TimerInit()
    end
end

function findAndKillBoss()
    CurBossId = getBossInfo()
    if CurBossId == nil or CurBossId == "0" then
        return
    end

    local obj = getObjByConfig(CurBossId)
    if nx_is_valid(obj) then
        if TimerDiff(CantBeAttackTimer) < 10 then
            prepareKillBoss(obj)
        elseif not isCantBeAttack(obj) then
            doKillBoss(obj)
        end
    else
        GoToNpc(GetCurMap(), CurBossId)
    end
end

function doKillBoss(boss)
    if GetDistanceToObj(boss) > 2.8 then
        nx_execute("zdn_logic_skill", "PauseAttack")
        GoToObj(boss)
    else
        attack(boss)
    end
end

function isCantBeAttack(obj)
    local cantAttack = obj:QueryProp("CantBeAttack")
    if nx_number(cantAttack) == 1 then
        CantBeAttackTimer = TimerInit()
        return true
    end
    return false
end

function prepareKillBoss(obj)
    if not isCantBeAttack(obj) and GetDistanceToObj(obj) < 3 then
        CantBeAttackTimer = 0
        return
    end

    local index = isErrorBoss(CurBossId)
    if index > 0 then
        nx_execute("zdn_logic_skill", "PauseAttack")
        local x = ErrorBoss[index].fPos.X
        local y = ErrorBoss[index].fPos.Y
        local z = ErrorBoss[index].fPos.Z
        if GetDistance(x, y, z) > 1 then
            GoToPosition(x, y, z)
            return
        end
    end
    nx_execute("zdn_logic_skill", "StartParry")
end

function isNeedParry(obj)
    return isHaveStrongBuff(obj) or isStrongAttack(obj)
end

function isHaveStrongBuff(obj)
    local name = obj:QueryProp("ConfigID")
    if ThichQuanConfig.AutoDefData[name] == nil or ThichQuanConfig.AutoDefData[name].buff == nil then
        return false
    end
    local list = ThichQuanConfig.AutoDefData[name].buff
    for i = 1, #list do
        return nx_execute("zdn_logic_skill", "ObjHaveBuff", obj, list[i])
    end
    return false
end

function isStrongAttack(obj)
    local name = obj:QueryProp("ConfigID")
    if ThichQuanConfig.AutoDefData[name] == nil or ThichQuanConfig.AutoDefData[name].skill == nil then
        return false
    end
    local list = ThichQuanConfig.AutoDefData[name].skill
    local cur_skill_id = obj:QueryProp("CurSkillID")
    for i = 1, #list do
        if cur_skill_id == list[i] then
            return true
        end
    end
    return false
end

function attack(obj)
    if isNeedParry(obj) then
        nx_execute("zdn_logic_skill", "StartParry")
        return
    end

    nx_execute("zdn_logic_base", "SelectTarget", obj)
    if nx_execute("zdn_logic_skill", "IsRunning") then
        nx_execute("zdn_logic_skill", "ContinueAttack")
    else
        nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
    end
end

function getObjByConfig(config)
    local game_client = nx_value("game_client")
    local game_scene = game_client:GetScene()
    if not nx_is_valid(game_scene) then
        return nil
    end
    local objList = game_scene:GetSceneObjList()
    for i, obj in pairs(objList) do
        if nx_string(obj:QueryProp("ConfigID")) == nx_string(config) then
            return obj
        end
    end
    return nil
end

function enterScene()
    if isReadyToEnterScene() then
        nx_execute("zdn_logic_skill", "StopNgoiThien")
        nx_pause(0.3)
        openThichQuan()
    else
        nx_execute("zdn_logic_skill", "NgoiThien")
    end
end

function openThichQuan()
    CanJump = true
    local form = nx_value(THICH_QUAN_FORM_PATH)
    if not nx_is_valid(form) or not form.Visible or form.lbl_score.Text == nx_widestr("") then
        util_auto_show_hide_form(THICH_QUAN_FORM_PATH)
        LoadingTimer = TimerInit()
        return 0
    end
    if NeedResetTurnFlg then
        NeedResetTurnFlg = false
        resetTurn()
        return 5
    end

    if openThichQuanByLevel(1) then
        return 1
    elseif openThichQuanByLevel(2) then
        return 2
    elseif openThichQuanByLevel(3) then
        return 3
    elseif openThichQuanByLevel(4) then
        return 4
    else
        resetTurn()
        return 5
    end
end

function resetTurn()
    if TimerDiff(ResetTurnTimer) < 10 then
        return
    end
    ResetTurnTimer = TimerInit()
    if kieuDungVoUsable() then
        nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 17)
        nx_pause(0.5)
    else
        local form = nx_value(THICH_QUAN_FORM_PATH)
        if not nx_is_valid(form) then
            return
        end
        if form.btn_reset_start.Enabled == true then
            nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 16)
            nx_pause(0.5)
        else
            Stop()
        end
    end
end

function onOutOfTime()
    if Running then
        NeedResetTurnFlg = true
    end
end

function kieuDungVoUsable()
    local form = nx_value(THICH_QUAN_FORM_PATH)
    if nx_is_valid(form) and form.btn_double_model.Enabled == true then
        return true
    end
    return false
end

function openThichQuanByLevel(level)
    local form = nx_value(THICH_QUAN_FORM_PATH)
    if not nx_is_valid(form) or not form.Visible then
        return false
    end
    selectLevel(level, form)
    nx_pause(1)
    if isLevelCompleted(level) then
        return false
    end
    nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 3, nx_number(level), 0)
    nx_pause(2)
    if not nx_is_valid(form) or not form.Visible then
        return false
    end

    if level >= 2 then
        specifyBoss(level, form)
    end

    nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 4, nx_number(level), 1)
    CurrentLevel = level
    return true
end

function specifyBoss(level, form)
    local nextGuanID, bossIndex = getNextGuan(level)
    local useFreePointFlg = 0
    if nextGuanID == 0 then
        return
    end
    local arrestIndex = getArrestBoss(nextGuanID, level)
    if arrestIndex == bossIndex then
        return
    end
    if level == 4 and form.free_appoint == 1 then
        useFreePointFlg = 1
    end
    if arrestIndex ~= 0 then
        nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 14, level, arrestIndex, useFreePointFlg)
    end
end

function getArrestBoss(guanID, level)
    local boss_id = ""
    for i = 1, 9 do
        local guan_id = nx_string(getArrestData(level, i, 1))
        if guan_id == nx_string(guanID) then
            boss_id = nx_string(getArrestData(level, i, 2))
            break
        end
    end
    if boss_id == "" then
        return 0
    end
    local boss_list = ThichQuanData[guanID].bossList
    if boss_list == nil then
        return 0
    end
    for i, boss in pairs(boss_list) do
        if nx_string(boss) == boss_id then
            return i
        end
    end
    return 0
end

function getArrestData(array_level, child_index, data_index)
    return nx_execute(THICH_QUAN_FORM_PATH, "get_arrest_data", array_level, child_index, data_index)
end

function getNextGuan(level)
    for i = 1, 9 do
        local array_name = "guan" .. nx_string(level) .. "sub" .. nx_string(i)
        local record_complete = nx_number(getThichQuanRecord(array_name, "value7"))
        if record_complete == 1 then
            local record_guan_id = nx_number(getThichQuanRecord(array_name, "value1"))
            local record_boss_index = nx_number(getThichQuanRecord(array_name, "value2"))
            return record_guan_id, record_boss_index
        end
    end
    return 0, 0
end

function isLevelCompleted(level)
    local cnt = 0
    for i = 1, LEVEL_MAX_TURN[level] do
        local array_name = "guan" .. nx_string(level) .. "sub" .. nx_string(i)
        local c = nx_number(getThichQuanRecord(array_name, "value7"))
        if c == -1 then
            return false
        end
        if c == 2 then
            cnt = cnt + 1
        end
    end
    if cnt >= LEVEL_MAX_TURN[level] then
        return true
    end
    return false
end

function getThichQuanRecord(array_name, child_name)
    local common_array = nx_value("common_array")
    if not nx_is_valid(common_array) then
        return -1
    end
    array_name = nx_string(array_name)
    child_name = nx_string(child_name)
    local is_exist = common_array:FindArray(array_name)
    if is_exist then
        local value = common_array:FindChild(array_name, child_name)
        if value ~= nil then
            return value
        end
    end
    return -1
end

function selectLevel(level, form)
    if not nx_is_valid(form) then
        return 0
    end
    form.cur_tiguan_level = level
    nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", CLIENT_MSG_DS_LEVEL_INFO, nx_number(level))
    refresh_attack_boss_times()
    refresh_arrest_info()
    refresh_challenge_info()
    refresh_arrest_desc(form)
end

function isReadyToEnterScene()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local hpRatio = nx_number(player:QueryProp("HPRatio"))
    local mpRatio = nx_number(player:QueryProp("MPRatio"))
    if
        ((hpRatio >= 74 and nx_execute("zdn_logic_skill", "HaveBuff", "buf_baosd_01")) or hpRatio >= 95) and
            mpRatio >= 95
     then
        return true
    end
    return false
end

function endGame()
    local timer = TimerInit()
    while TimerDiff(timer) < 120 and Running do
        nx_pause(1)
        if nx_execute("zdn_logic_skill", "IsPlayerDead") then
            nx_execute("custom_sender", "custom_relive", 2, 0)
        else
            leaveBossScene()
        end
        if not isInBossScene() then
            local form = nx_value("form_zdn_thth")
            if nx_is_valid(form) then
                form.btn_submit.Text = nx_widestr("Dead")
            end
            Stop()
        end
    end
    StartClickTimer = 0
end

function leaveBossScene()
    nx_execute("zdn_logic_skill", "PauseAttack")
    if isComplete() then
        nx_execute("custom_sender", "custom_tiguan_request_leave")
        return
    end
    requestLeaveViaNpc()
end

function requestLeaveViaNpc()
    local npc = findSceneNpc()
    if npc ~= nil then
        if GetDistanceToObj(npc) > 4 then
            GoToObj(npc)
        else
            nx_execute("custom_sender", "custom_select", npc.Ident)
            nx_pause(0.2)
            nx_execute("zdn_logic_base", "TalkToNpc", npc, 0)
        end
    else
        local guanId = getCurGuanId()
        if guanId == 0 then
            return
        end
        local x = ThichQuanData[guanID].TransOutX
        local y = ThichQuanData[guanID].TransOutY
        local z = ThichQuanData[guanID].TransOutZ
        GoToPosition()
    end
end

function getCurGuanId()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return 0
    end
    return nx_number(player:QueryProp("CurGuanID"))
end

function findSceneNpc()
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return nil
    end
    local objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if nx_number(obj:QueryProp("NpcType")) == 51 then
            return obj
        end
    end
    return nil
end

function isComplete()
    local form = nx_value("form_stage_main\\form_tiguan\\form_tiguan_detail")
    if not nx_is_valid(form) then
        return false
    end
    return form.Visible
end

function isLoading()
    local form = nx_value("form_stage_main\\form_main\\form_main_curseloading")
    if nx_is_valid(form) and form.Visible then
        LoadingTimer = TimerInit()
    end
    form = nx_value("form_common\\form_loading")
    if nx_is_valid(form) and form.Visible then
        LoadingTimer = TimerInit() + 3
    end
    return TimerDiff(LoadingTimer) < 1
end

function updateMap()
    Map = {
        ["ID"] = GetCurMap(),
        ["deltaTime"] = nx_execute("zdn_logic_base", "GetCurrentTimestamp") - os.time()
    }
end

function loadConfig()
end

function loadThichQuanData()
    updateMap()
    -- loadExSkillData()
    BossData = {}
    ThichQuanData = {}
    ErrorBoss = {}

    loadBossData()
    loadNpcPosData()
    loadJumpData()
    loadAutoDefData()
end

function loadBossData()
    local file = nx_resource_path() .. "zdn\\data\\thichquan\\boss.ini"
    local errNum = nx_number(IniRead(file, "error_boss", "total", "0"))
    for i = 1, errNum do
        local data = nx_string(IniRead(file, "error_boss", nx_string(i), "0"))
        local dataTable = util_split_string(data, ";")
        if #dataTable >= 4 then
            local cPos = util_split_string(dataTable[3], ",")
            local fPos = util_split_string(dataTable[4], ",")
            local child = {
                ["bossID"] = dataTable[1],
                ["Distance"] = nx_number(dataTable[2]),
                ["cPos"] = {
                    ["X"] = nx_number(cPos[1]),
                    ["Y"] = nx_number(cPos[2]),
                    ["Z"] = nx_number(cPos[3])
                },
                ["fPos"] = {
                    ["X"] = nx_number(fPos[1]),
                    ["Y"] = nx_number(fPos[2]),
                    ["Z"] = nx_number(fPos[3])
                }
            }
            table.insert(ErrorBoss, child)
        end
    end
    local setNum = nx_number(IniRead(file, "boss_list", "total", "0"))
    for i = 1, setNum do
        BossData[i] = nx_string(IniRead(file, "boss_list", nx_string(i), "0"))
    end
end

function loadNpcPosData()
    local file = nx_resource_path() .. "share\\War\\tiguan.ini"
    for i = 1, 32 do
        local data = {}
        local level = nx_number(IniRead(file, nx_string(i), "Level", "0"))
        local bossList = IniRead(file, nx_string(i), "BossList", "0")
        local x = nx_number(IniRead(file, nx_string(i), "TransOutX", "0"))
        local y = nx_number(IniRead(file, nx_string(i), "TransOutY", "0"))
        local z = nx_number(IniRead(file, nx_string(i), "TransOutZ", "0"))
        bossList = util_split_string(nx_string(bossList), ";")
        data = {
            ["Level"] = level,
            ["bossList"] = bossList,
            ["TransOutX"] = x,
            ["TransOutY"] = y,
            ["TransOutZ"] = z
        }
        table.insert(ThichQuanData, data)
    end
end

function loadJumpData()
    local jumpIni = nx_create("IniDocument")
    jumpIni.FileName = nx_resource_path() .. "zdn\\data\\thichquan\\jump.ini"
    if not jumpIni:LoadFromFile() then
        nx_destroy(jumpIni)
        Stop()
    end
    local jumpList = jumpIni:GetSectionList()
    local x, y, z = 0, 0, 0
    local pos_text = ""
    local pos_list = {}
    local data = {}
    ThichQuanConfig.JumpData = {}
    for i = 1, #jumpList do
        local point_list = jumpIni:GetItemList(jumpList[i])
        local last_x, last_y, last_z = 0, 0, 0
        ThichQuanConfig.JumpData[jumpList[i]] = {}
        for j = 1, #point_list do
            pos_text = nx_string(jumpIni:ReadString(jumpList[i], point_list[j], "0"))
            pos_list = util_split_string(pos_text, ",")
            if #pos_list ~= 3 then
                break
            end
            data = {}
            data.cur_x = last_x
            data.cur_y = last_y
            data.cur_z = last_z
            x, y, z = nx_number(pos_list[1]), nx_number(pos_list[2]), nx_number(pos_list[3])
            data.dest_x = x
            data.dest_y = y
            data.dest_z = z
            ThichQuanConfig.JumpData[jumpList[i]][j] = data
            last_x, last_y, last_z = x, y, z
        end
    end
    nx_destroy(jumpIni)
end

function loadAutoDefData()
    local autoDefIni = nx_create("IniDocument")
    autoDefIni.FileName = nx_resource_path() .. "zdn\\data\\thichquan\\boss_strong_skill.ini"
    if not autoDefIni:LoadFromFile() then
        nx_destroy(autoDefIni)
        Stop()
    end
    local deffList = autoDefIni:GetSectionList()
    ThichQuanConfig.AutoDefData = {}
    for i = 1, #deffList do
        ThichQuanConfig.AutoDefData[deffList[i]] = {}
        local buff = nx_string(autoDefIni:ReadString(deffList[i], "buff", "0"))
        if buff ~= "0" then
            ThichQuanConfig.AutoDefData[deffList[i]].buff = util_split_string(buff, ",")
        end
        local skill = nx_string(autoDefIni:ReadString(deffList[i], "skill", "0"))
        if skill ~= "0" then
            ThichQuanConfig.AutoDefData[deffList[i]].skill = util_split_string(skill, ",")
        end
    end
    nx_destroy(autoDefIni)
end

-- function loadExSkillData()
--     ExSkill = {}
--     for i = 1, 9 do
--         local skillId = "jn_drtg_00" .. nx_string(i)
--         local staticIni = nx_execute("util_functions", "get_ini", "share\\Skill\\skill_new.ini")
--         if not nx_is_valid(staticIni) then
--             return
--         end
--         local sectionIndexNumber = staticIni:FindSectionIndex(skillId)
--         if sectionIndexNumber < 0 then
--             return
--         end
--         local staticData = staticIni:ReadString(sectionIndexNumber, "StaticData", "0")

--         ExSkill[i] = {
--             ["SkillID"] = "jn_drtg_00" .. nx_string(i),
--             ["CoolType"] = nx_execute("zdn_logic_skill", "GetSkillCoolDownType", staticData)
--         }
--     end
-- end

function isInBossScene()
    local form = nx_value("form_stage_main\\form_main\\form_main_shortcut_extraskill")
    if nx_is_valid(form) and form.Visible == true then
        return true
    end
    if getBossInfo() ~= nil then
        return true
    end
    return false
end

function checkLagSkill()
    if TimerDiff(timerCheckLag) < 3 then
        return
    end
    timerCheckLag = TimerInit()
    local tempMapID = GetCurMap()
    if tempMapID == "0" then
        return false
    end
    local curTime = nx_execute("zdn_logic_base", "GetCurrentTimestamp")
    if curTime == 0 then
        return
    end
    local tempMapDeltaTime = curTime - os.time()
    local delta = (tempMapDeltaTime - Map.deltaTime)
    if delta > -20 then
        updateMap()
        return false
    end
    waitLagTime(math.abs(delta))
    updateMap()
end

function waitLagTime(delta)
    local timer = TimerInit()
    while Running and TimerDiff(timer) < delta do
        nx_pause(1)
        leaveBossScene()
    end
end

function getBossInfo()
    local tiguan_finish_cdts = nx_value("tiguan_finish_cdts")

    if not nx_is_valid(tiguan_finish_cdts) or not nx_find_custom(tiguan_finish_cdts, "cg_id") then
        return nil
    end
    local cdt_tab = tiguan_finish_cdts:GetChildList()
    local index = 1
    if #cdt_tab > 0 then
        index = cdt_tab[1].cdt_id
        LastBossId = BossData[index]
    end
    return LastBossId
end

function jumpToBoss()
    CanJump = false
    boss_id = getBossInfo()
    if boss_id == nil or boss_id == "0" then
        return
    end
    local x, y, z = GetNpcPostion(GetCurMap(), boss_id)
    local jump_data = ThichQuanConfig.JumpData[boss_id]
    if jump_data == nil then
        return
    end
    local last_x, last_y, last_z = 0, 0, 0
    for i = 1, #jump_data do
        local pos = jump_data[i]
        flyToPos(pos.cur_x, pos.cur_y, pos.cur_z, pos.dest_x, pos.dest_y, pos.dest_z)
        last_x, last_y, last_z = pos.dest_x, pos.dest_y, pos.dest_z
    end
    local index = isErrorBoss(boss_id)
    if index > 0 then
        x = ErrorBoss[index].fPos.X
        y = ErrorBoss[index].fPos.Y
        z = ErrorBoss[index].fPos.Z
    end
    flyToPos(last_x, last_y, last_z, x, y, z)
end

function isErrorBoss(cfg)
    for i, boss in pairs(ErrorBoss) do
        if cfg == boss.bossID then
            return i
        end
    end
    return 0
end

function flyToPos(cur_x, cur_y, cur_z, x, y, z)
    if not Running then
        return
    end
    local role = nx_value("role")
    local scene_obj = nx_value("scene_obj")
    if not nx_is_valid(scene_obj) or not nx_is_valid(role) then
        return
    end
    local dis = distance3d(role.PositionX, role.PositionY, role.PositionZ, cur_x, cur_y, cur_z)
    if not (cur_x == 0 and cur_y == 0 and cur_z == 0) and dis > 6 then
        return
    end

    SwitchPlayerStateToFly()
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
    while TimerDiff(out_time) < 3 and Running do
        nx_pause(0.1)
        if not isFlying() then
            break
        end
    end
    StartClickTimer = 0
end

function collide(...)
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

function setCollide(x, y, z)
    local game_visual = nx_value("game_visual")
    local role = nx_value("role")
    if not nx_is_valid(game_visual) or not nx_is_valid(role) then
        return
    end
    game_visual:SetRoleMoveDestX(role, x)
    game_visual:SetRoleMoveDestY(role, y)
    game_visual:SetRoleMoveDestZ(role, z)
end

function setAngle(x, y, z)
    local role = nx_value("role")
    local scene_obj = nx_value("scene_obj")
    if not nx_is_valid(role) or not nx_is_valid(scene_obj) then
        return
    end
    scene_obj:SceneObjAdjustAngle(role, x, z)
end

function distance3d(bx, by, bz, dx, dy, dz)
    return math.sqrt((dx - bx) * (dx - bx) + (dy - by) * (dy - by) + (dz - bz) * (dz - bz))
end

function isFlying(...)
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
