function main_form_open(self)
    local gui = nx_value("gui")
    self.Left = (gui.Width - self.Width) / 2
    self.Top = (gui.Height - self.Height) / 2
    local gui = nx_value("gui")
    local text_del = gui.TextManager:GetText("ui_hp_del")
    local text = gui.TextManager:GetFormatText("ui_bag_delmsg", text_del)
    text = nx_widestr(text)
    self.info_label.Visible = false
    self.mltbox_info.Visible = true
    self.mltbox_info:Clear()
    self.mltbox_info:AddHtmlText(text, -1)
    self.del_edit.MaxLength = nx_ws_length(text_del)
    self.Default = self.ok_btn
    self.del_edit.Text = text_del
    return 1
end
