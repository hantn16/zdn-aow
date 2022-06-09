require("util_functions")

function util_text(id)
  if nx_string(id) == nx_string("desc_zdn_buff_no_delay") then
    return nx_widestr('<font color="#FFFF00">Dùng liên tục</font>')
  end
  local gui = nx_value("gui")
  if nx_is_valid(gui) then
    return gui.TextManager:GetText(id)
  end
end
