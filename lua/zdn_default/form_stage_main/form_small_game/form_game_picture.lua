function on_btn_start_click(btn)
  local form = btn.ParentForm
  if not nx_is_valid(form) then
    return
  end
  local PictureGame = nx_value("PictureGame")
  if not nx_is_valid(PictureGame) then
    return
  end
  PictureGame:StartGame()
  form.start = true
  btn.Visible = false
  local timer = nx_value(GAME_TIMER)
  timer:Register(200, -1, "form_stage_main\\form_small_game\\form_game_picture", "on_update_time", form, -1, -1)
  --
  nx_pause(1)
  sapXep(form)
  --
end


function readPictureList(form)
  local list = {}
  local row_num = form.grid_row_num
  local col_num = form.grid_clomn_num
  local index = 0
  for i=1,col_num do
    for j=1,row_num do
      index = index + 1
      table.insert(list, getImageValue(form,index-1))
    end
  end
  return list
end

function getImageValue(form, index )
  local grid = form.imagegrid_pic
  local photo = grid:GetItemImage(index)
  local temp = util_split_string(nx_string(photo), "/")
  if #temp == 0 then return 0 end
  local photo_name = temp[#temp]
  temp = util_split_string(photo_name, ".")
  photo_name = temp[1]
  temp = util_split_string(photo_name,"_")
  local value = nx_number(temp[#temp])
  local aTable = {
    ["Photo"] = nx_string(photo),
    ["Value"] = value
  }
  return aTable
end


function sapXep(form)
  local picture_list = readPictureList(form)
  local PictureGame = nx_value("PictureGame")
  local grid = form.imagegrid_pic
  for i=1,#picture_list do
    for j = #picture_list, i,-1 do
      if picture_list[j].Value < picture_list[i].Value then
        PictureGame:ChangePic(j-1,i-1)
        grid:DelItem(j-1)
        grid:DelItem(i-1)
        grid:AddItem(j-1, picture_list[i].Photo, "", 1, -1)
        grid:AddItem(i-1, picture_list[j].Photo, "", 1, -1)
        
        local temp = picture_list[j]
        picture_list[j] = picture_list[i]
        picture_list[i] = temp
        nx_pause(0.1)
      end
    end
  end
end