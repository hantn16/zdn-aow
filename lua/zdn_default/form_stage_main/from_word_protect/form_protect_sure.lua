function on_main_form_open(self)
    local form = self.ParentForm
    form.lbl_notice.Visible = false
    form.groupbox_countdown.Visible = false
    local switch_manager = nx_value("SwitchManager")
    if nx_is_valid(switch_manager) then
        local is_open = switch_manager:CheckSwitchEnable(ST_FUNCTION_OPEN_WORD_PROTECT_TIME)
        if not is_open then
            form.btn_timeprotect.Visible = false
        end
    end
    if nx_is_valid(switch_manager) then
        local is_open = switch_manager:CheckSwitchEnable(ST_FUNCTION_EMAIL_VALIDATE)
        if not is_open then
            form.btn_find_bymail.Visible = false
        end
    end
    local gui = nx_value("gui")
    if nx_is_valid(gui) then
        gui.Focused = form.redit_1
    end
end
