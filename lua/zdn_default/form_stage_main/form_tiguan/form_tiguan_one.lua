--
openTime = 0
function getOpenTime( ... )
  return openTime
end
--
function on_main_form_open(form)
  openTime = os.clock()
  set_rbtn_type(form)
  form.rbtn_level_1.bNotice = true
  form.lbl_flicker.Visible = false
  form.btn_start.Enabled = false
  form.btn_allkill.Enabled = false
  form.btn_rank_get.Enabled = false
  form.lbl_double_image.Visible = false
  local game_client = nx_value("game_client")
  local client_player = game_client:GetPlayer()
  if not nx_is_valid(client_player) then
    return 0
  end
  form.player_name = client_player:QueryProp("Name")
  form.guan_ui_ini = nx_execute("util_functions", "get_ini", CHANGGUAN_UI_INI)
  if not nx_is_valid(form.guan_ui_ini) then
    return 0
  end
  form.guan_achieve_ini = nx_execute("util_functions", "get_ini", CHANGGUAN_UI_ACHIEVE_INI)
  if not nx_is_valid(form.guan_achieve_ini) then
    return 0
  end
  form.guan_exchange_ini = nx_execute("util_functions", "get_ini", CHANGGUAN_UI_EXCHANGE_INI)
  if not nx_is_valid(form.guan_exchange_ini) then
    return 0
  end
  init_arrest_achieve_one(form)
  init_rank_info(form)
  nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", CLIENT_MSG_DS_FORM_INIT)
  nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", CLIENT_MSG_DS_RANK_INFO)
  local flick = get_flick_item_index()
  nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", CLIENT_MSG_DS_EXCHANGE_QUERY, flick)
  local gui = nx_value("gui")
  form.Left = (gui.Width - form.Width) / 2
  form.Top = (gui.Height - form.Height) / 2
  form.rbtn_1.Checked = true
  form.rbtn_achieve_1.Checked = true
  form.rbtn_level_1.Checked = true
  form.rbtn_skill_1.Checked = true
  refresh_time_info()
  refresh_attack_boss_times()
  refresh_challenge_info()
  refresh_exchange_tree(form)
  default_set(form)
end