require("util_gui")
require("zdn_form_common")

local Logic = "zdn_logic_vat_pham"

function onFormOpen()
	if nx_execute(Logic, "IsRunning") then
		Form.btn_submit.Text = nx_widestr("Stop")
	else
		Form.btn_submit.Text = nx_widestr("Start")
	end
end

function onBtnSubmitClick()
	if not nx_execute(Logic, "IsRunning") then
		nx_execute(Logic, "Start")
		Form.btn_submit.Text = nx_widestr("Stop")
	else
		nx_execute(Logic, "Stop")
		Form.btn_submit.Text = nx_widestr("Start")
	end
end

function onBtnSettingClick()
	util_auto_show_hide_form("form_zdn_vat_pham_setting")
end
