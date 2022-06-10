require("zdn_lib\\util_functions")
require("zdn_util")
local Running = false
local TodoList = {
    {"Kim Lăng 1", "zdn_logic_noi6_kl1"},
    {"Kim Lăng 2", "zdn_logic_noi6_kl2"},
    {"Tô Châu", "zdn_logic_noi6_tc"},
    {"Lạc Dương", "zdn_logic_noi6_ld"}
}

function IsRunning()
    return Running
end

function CanRun()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
        if nx_execute(logic, "CanRun") then
            return true
        end
    end
    return false
end

function Start()
    if Running then
        return
    end
    Running = true
    startNoi6()
end

function Stop()
    Running = false
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-stop", nx_current())
        nx_execute(logic, "Stop")
    end
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function checkNextTask()
    Console("Check next quest")
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
        if nx_execute(logic, "IsRunning") then
            nx_execute(logic, "Stop")
        end
    end

    for i = 1, cnt do
        local logic = TodoList[i][2]
        if nx_execute(logic, "CanRun") then
            Console("Next quest: " .. TodoList[i][1])
            nx_execute(logic, "Start")
            return
        end
    end
    Console("All quest is done.")
    Stop()
end

function startNoi6()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
        nx_execute("zdn_logic_common_listener", "Subscribe", logic, "on-task-stop", nx_current(), "onTaskStop")
    end
    checkNextTask()
end

function onTaskStop(logic)
    Console(logic .. " stopped")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    checkNextTask()
end
