require("zdn_form_common")

local Logic = "zdn_logic_thu_nghiep"

function onFormOpen(form)
    if nx_execute(Logic, "IsRunning") then
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
        Form.btn_submit.Text = nx_widestr("Stop")
    else
        Form.btn_submit.Text = nx_widestr("Start")
    end
end

function onBtnSubmitClick()
	if not nx_execute(Logic, "IsRunning") then
		Form.btn_submit.Text = nx_widestr("Stop")
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
		nx_execute(Logic, "Start")
	else
		nx_execute(Logic, "Stop")
		Form.btn_submit.Text = nx_widestr("Start")
	end
end

function onTaskStop()
	Form.btn_submit.Text = nx_widestr("Start")
end

function onFormClose()
	nx_execute("zdn_logic_common_listener", "Unsubscribe", Logic, "on-task-stop", nx_current())
end