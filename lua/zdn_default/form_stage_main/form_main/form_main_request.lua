--
function get_request_prop(index, para)
  if index == 0 then
    return table.maxn(REQUEST_ARRAY)
  elseif (1 <= para) and (para <=4)  then
    return REQUEST_ARRAY[index][para]
  end
end

function remove_request(index)
  local button = get_request_button(index)
  local form_main = nx_value(GAME_GUI_MAIN)
  if not nx_is_valid(form_main) or not nx_is_valid(button) then
    return
  end
  form_main:Remove(button.label)
  form_main:Remove(button)
  local gui = nx_value("gui")
  gui:Delete(button.label)
  gui:Delete(button)
  table.remove(REQUEST_ARRAY, index)
  show_request()
end
--