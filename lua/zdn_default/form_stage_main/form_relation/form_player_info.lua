--
sns_info = {}
sns_info.name = ""
sns_info.scene = ""
sns_info.guild = ""
sns_info.school = ""
function reset_sns_info()
  sns_info.state = 0
  sns_info.name = ""
  sns_info.scene = ""
  sns_info.guild = ""
  sns_info.school = ""
end
function get_sns_info(prop)
  if prop == "State" then 
    return sns_info.state
  elseif prop == "Name" then
    return sns_info.name
  elseif prop == "Scene" then
    return sns_info.scene
  elseif prop == "Guild" then
    return sns_info.guild
  elseif prop == "School" then
    return sns_info.school
  else 
    return -1
  end     
end
function on_look_up_msg(player_name, player_title, player_level, player_photo, player_pk_step, player_scene, player_school, player_guild, player_guild_pos, player_sh, player_vip, player_teacher, player_partner, zone)
  sns_info.state = 1
  sns_info.name = player_name
  sns_info.scene = player_scene
  sns_info.guild = player_guild
  sns_info.school = player_school
--
  local game_client = nx_value("game_client")
  local player = game_client:GetPlayer()
  if not nx_is_valid(player) then
    return
  end
  local jh_scene = ""
  if player:FindProp("CurJHSceneConfigID") then
    jh_scene = player:QueryProp("CurJHSceneConfigID")
  end
  if nx_string(jh_scene) ~= nx_string("") then
    nx_execute("form_stage_main\\form_relation\\form_new_world_player_info", "on_look_up_jhpk_msg", player_name, player_level, player_photo, player_scene, player_school, player_guild, zone)
    return
  end
  local gui = nx_value("gui")
  if not nx_is_valid(gui) then
    return
  end
  local dialog = nx_execute("util_gui", "util_get_form", "form_stage_main\\form_relation\\form_player_info", true, false)
  if not nx_is_valid(dialog) then
    return
  end
  gui.Desktop:ToFront(dialog)
  dialog.PlayerName = player_name
  local _, relation = nx_execute("form_stage_main\\form_relation\\form_relation_renmai", "get_relation_type_by_name", player_name)
  dialog:Show()
  local player_relation = "ui_wu"
  if relation == RELATION_TYPE_SWORN then
    player_relation = "ui_menu_friend_item_sworn"
  elseif relation == RELATION_TYPE_FRIEND then
    player_relation = "ui_menu_friend_item_haoyou"
  elseif relation == RELATION_TYPE_BUDDY then
    player_relation = "ui_menu_friend_item_zhiyou"
  elseif relation == RELATION_TYPE_ENEMY then
    player_relation = "ui_menu_friend_item_chouren"
  elseif relation == RELATION_TYPE_BLOOD then
    player_relation = "ui_menu_friend_item_xuechou"
  elseif relation == RELATION_TYPE_ATTENTION then
    player_relation = "ui_menu_friend_item_guanzhu"
  end
  player_relation = util_text(player_relation)
  dialog.lbl_name.Text = nx_widestr(player_name)
  dialog.lbl_photo.BackImage = player_photo
  dialog.lbl_menpai.Text = nx_widestr(player_school)
  dialog.lbl_bangpai.Text = nx_widestr(player_guild)
  dialog.lbl_guanxi.Text = nx_widestr(player_relation)
  dialog.lbl_chengwei.Text = nx_widestr(player_title)
  dialog.lbl_zhuangtai.Text = nx_widestr(gui.TextManager:GetText(player_scene))
  dialog.lbl_11.Text = nx_widestr(player_guild_pos)
  dialog.lbl_shili.Text = nx_widestr(player_level)
  dialog.lbl_shane.Text = nx_widestr(player_pk_step)
  dialog.mltbox_1:Clear()
  dialog.mltbox_1:AddHtmlText(nx_widestr(player_sh), -1)
  if nx_int(player_vip) == nx_int(1) then
    dialog.lbl_viper.Text = nx_widestr(util_text("ui_yes"))
  else
    dialog.lbl_viper.Text = nx_widestr(util_text("ui_no"))
  end
  if nx_widestr(player_teacher) == nx_widestr("") or player_teacher == nil then
    dialog.lbl_teacher.Text = nx_widestr(util_text("ui_wu"))
  else
    dialog.lbl_teacher.Text = nx_widestr(player_teacher)
  end
  if nx_widestr("") == nx_widestr(player_partner) or nil == player_partner then
    dialog.lbl_marry.Text = nx_widestr(util_text("ui_wu"))
  else
    dialog.lbl_marry.Text = nx_widestr(player_partner)
  end
  split_sworn_info(dialog, sworn_info)
end