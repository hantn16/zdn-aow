function xiaQi(form)
  local ini = nx_execute("util_functions", "get_ini", "share\\Life\\WeiqiGame.ini")
  if not nx_is_valid(ini) then return end
  local grid = form.imagegrid_weiqi
  local sec_index = ini:FindSectionIndex(nx_string(form.Diff))
  local playerPos = ini:ReadString(nx_number(sec_index), "playerPos", "1")
  playerPos = util_split_string(nx_string(playerPos), ",")
  for i,pos in pairs(playerPos) do
    local index = util_split_string(pos,"|")[1]
    nx_pause(3)
    nx_execute("form_stage_main\\form_small_game\\form_game_weiqi", "on_imagegrid_weiqi_select_changed",grid, nx_number(index))  
  end
end
function on_btn_start_click(btn)
  local form = btn.ParentForm
  if not nx_is_valid(form) then
    return
  end
  btn.Visible = false
  local weiqigame = nx_value("WeiqiGame")
  if nx_is_valid(weiqigame) then
    weiqigame:StartGame()
  end
  --
  nx_pause(1)
  xiaQi(form)
  --
end