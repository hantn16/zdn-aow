require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_define\\task_define")
local Running = false
local TodoList = {}

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    if loadConfig() then
        Running = true
        startTaskManager()
    else
        Stop()
    end
end

function Stop()
    Running = false
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-stop", nx_current())
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-interrupt", nx_current())
        nx_execute(logic, "Stop")
    end
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

--private
function loadConfig()
    TodoList = {}
    local taskStr = IniReadUserConfig("TroLy", "Task", "")
    if taskStr ~= "" then
        local taskList = util_split_string(nx_string(taskStr), ";")
        for _, task in pairs(taskList) do
            local prop = util_split_string(task, ",")
            addToTodoList(nx_number(prop[2]), nx_string(prop[1]) == "1" and true or false)
        end
    end
    if #TodoList > 0 then
        return true
    end
    return false
end

function addToTodoList(i, checked)
    if checked then
        table.insert(TodoList, i)
    end
end

function startTaskManager()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        nx_execute("zdn_logic_common_listener", "Subscribe", logic, "on-task-stop", nx_current(), "onTaskStop")
        nx_execute(
            "zdn_logic_common_listener",
            "Subscribe",
            logic,
            "on-task-interrupt",
            nx_current(),
            "onTaskInterrupt"
        )
    end
    checkNextTask()
end

function onTaskStop(logic)
    Console(logic .. " stopped")
    checkNextTask()
end

function checkNextTask()
    Console("Check next task")
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        if nx_execute(logic, "IsRunning") then
            nx_execute(logic, "Stop")
        end
    end

    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        if nx_execute(logic, "CanRun") then
            Console("Next task: " .. TASK_LIST[TodoList[i]][1])
            nx_execute(logic, "Start")
            return
        end
    end
    Console("All task is done.")
    Stop()
end

function onTaskInterrupt(source)
    if not Running then
        return
    end
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        if source == logic then
            return
        end
        if nx_execute(logic, "CanRun") then
            Console("Task interrupted")
            nx_execute(logic, "Stop")
            return
        end
    end
end
