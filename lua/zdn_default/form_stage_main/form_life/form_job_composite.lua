local JOB_ID_TABLE = {}
local sortString = ""
local sortClass = ""
local life_btn_name_table = {
    sh_kg = {
        "@ui_btn_kg",
        "@ui_sh_jinggong"
    },
    sh_nf = {
        "@ui_btn_nf",
        "@ui_sh_jinggong"
    },
    sh_cf = {
        "@ui_btn_cf",
        "@ui_btn_cf_1"
    },
    sh_cs = {
        "@ui_btn_cs",
        "@ui_btn_cs_1"
    },
    sh_ds = {
        "@ui_btn_ds",
        "@ui_btn_ds_1"
    },
    sh_jq = {
        "@ui_btn_jq",
        "@ui_btn_jq_1"
    },
    sh_tj = {
        "@ui_btn_tj",
        "@ui_btn_tj_1"
    },
    sh_ys = {
        "@ui_btn_ys",
        "@ui_btn_ys_1"
    },
    sh_qs = {
        "@ui_LianXi",
        "@ui_sh_jinggong"
    },
    sh_ss = {
        "@ui_btn_ss",
        "@ui_sh_jinggong"
    },
    sh_hs = {
        "@ui_btn_hs",
        "@ui_sh_jinggong"
    }
}
function show_composite_info(form, formula_id)
    local ItemQuery = nx_value("ItemQuery")
    local gui = nx_value("gui")
    form.product_grid:Clear()
    form.material_grid:Clear()
    if not nx_is_valid(ItemQuery) or not nx_is_valid(gui) then
        return
    end
    if not nx_is_valid(form) then
        return
    end
    if formula_id == "" or formula_id == "nil" then
        return
    end
    form.CurFormulaID = nx_string(formula_id)
    local iniformula = nx_execute("util_functions", "get_ini", "share\\Item\\life_formula.ini")
    local sec_index = iniformula:FindSectionIndex(formula_id)
    if sec_index < 0 then
        return
    end
    if not nx_is_valid(iniformula) then
        return
    end
    local needene = iniformula:ReadString(sec_index, "ComposeUseStrenth", "")
    local needmoney = iniformula:ReadString(sec_index, "CompositeNeedMoney", "")
    local needitem = iniformula:ReadString(sec_index, "Material", "")
    local porduct_item = iniformula:ReadString(sec_index, "ComposeResult", "")
    local exp_package = iniformula:ReadInteger(sec_index, "ExpPackageID", 0)
    local needpoint = iniformula:ReadInteger(sec_index, "NeedPoint", 0)
    local Profession = iniformula:ReadString(sec_index, "Profession", "")
    local gamename = iniformula:ReadString(sec_index, "GameName", "")
    local npc_limit_table = iniformula:ReadString(sec_index, "TableNPCLimit", "")
    local temp_job_id, job_exp = get_exp_from_package(exp_package)
    local item_type = nx_number(ItemQuery:GetItemPropByConfigID(nx_string(porduct_item), "ItemType"))
    if item_type >= ITEMTYPE_EQUIP_MIN and item_type <= ITEMTYPE_EQUIP_MAX then
        photo = nx_execute("util_static_data", "item_query_ArtPack_by_id", nx_string(porduct_item), "Photo")
    else
        photo = ItemQuery:GetItemPropByConfigID(nx_string(porduct_item), nx_string("Photo"))
    end
    local name = gui.TextManager:GetFormatText(nx_string(porduct_item))
    local Text_tl = gui.TextManager:GetText("ui_sh_xhtl")
    local Text_sl = gui.TextManager:GetText("ui_sh_tssld")
    local Text_xd
    if Profession == "sh_ss" or Profession == "sh_hs" then
        Text_xd = gui.TextManager:GetText("ui_sh_qs_hdxd")
    else
        Text_xd = gui.TextManager:GetText("ui_sh_xhxd")
    end
    local Text_zsxy = gui.TextManager:GetText("ui_sh_zsxy")
    local tool_name = gui.TextManager:GetText(Profession)
    form.mltbox_dec:Clear()
    local dec_text = nx_widestr("")
    if nx_int(needpoint) ~= nx_int(0) then
        dec_text = dec_text .. nx_widestr(Text_xd) .. nx_widestr(-needpoint) .. nx_widestr("   ")
    end
    if needmoney ~= nil and needmoney ~= "" and nx_int(needmoney) > nx_int(0) then
        local Text_jq = gui.TextManager:GetText("ui_off_money_pay")
        local money_text = format_prize_money(nx_int64(needmoney))
        form.mltbox_dec:AddHtmlText(nx_widestr(Text_jq) .. nx_widestr(money_text), nx_int(-1))
    end
    if nx_string(needene) ~= nx_string("") then
        dec_text = dec_text .. nx_widestr(Text_tl) .. nx_widestr(needene)
    end
    form.mltbox_dec:AddHtmlText(nx_widestr(dec_text), nx_int(-1))
    if nx_int(needene) > nx_int(0) then
        form.lbl_ene_value.Text = nx_widestr(nx_string(needene))
        form.groupbox_ene.Visible = true
    else
        form.groupbox_ene.Visible = false
    end
    if nx_int(job_exp) > nx_int(0) then
        form.lbl_exp_value.Text = nx_widestr(nx_string(job_exp))
        form.groupbox_exp.Visible = true
    else
        form.groupbox_exp.Visible = false
    end
    form.product_grid:AddItem(0, photo, nx_widestr(name), 1, -1)
    form.product_grid:SetItemAddInfo(nx_int(0), nx_int(1), nx_widestr(porduct_item))
    if Profession == "sh_cs" or Profession == "sh_ds" or Profession == "sh_ys" then
        local pz_key, pz_value = get_ydc_pingzhi(Profession, ItemQuery, porduct_item)
        form.product_grid:SetItemAddInfo(nx_int(0), nx_int(4), nx_widestr(nx_string(pz_key)))
        form.product_grid:SetItemAddInfo(nx_int(0), nx_int(5), nx_widestr(nx_string(pz_value)))
    end
    local str_lst = util_split_string(needitem, ";")
    form.groupbox_3.Visible = true
    for i = 1, table.getn(str_lst) do
        local str_temp = util_split_string(str_lst[i], ",")
        local item = nx_string(str_temp[1])
        local num = nx_int(str_temp[2])
        local bExist = ItemQuery:FindItemByConfigID(nx_string(item))
        if bExist then
            local tempphoto = ItemQuery:GetItemPropByConfigID(nx_string(item), nx_string("Photo"))
            local itemname =
                nx_execute(
                "form_stage_main\\form_life\\form_job_gather",
                "takeoutmore_str",
                gui.TextManager:GetText(item)
            )
            itemname = gui.TextManager:GetText(item)
            local text = nx_widestr('<font color="#5f4325">') .. nx_widestr(itemname) .. nx_widestr("</font>")
            form.material_grid:AddItem(i - 1, tempphoto, text, 0, -1)
            local MaterialNum = Get_Material_Num(item, VIEWPORT_MATERIAL_TOOL) + Get_Material_Num(item, VIEWPORT_TOOL)
            if nx_int(MaterialNum) >= nx_int(num) then
                form.material_grid:ChangeItemImageToBW(i - 1, false)
                form.material_grid:SetItemAddInfo(
                    nx_int(i - 1),
                    nx_int(1),
                    nx_widestr('<font color="#00aa00">' .. nx_string(MaterialNum) .. "/" .. nx_string(num) .. "</font>")
                )
                form.material_grid:ShowItemAddInfo(nx_int(i - 1), nx_int(1), true)
            else
                form.material_grid:ChangeItemImageToBW(i - 1, true)
                form.material_grid:SetItemAddInfo(
                    nx_int(i - 1),
                    nx_int(1),
                    nx_widestr('<font color="#ff0000">' .. nx_string(MaterialNum) .. "/" .. nx_string(num) .. "</font>")
                )
                form.material_grid:ShowItemAddInfo(nx_int(i - 1), nx_int(1), true)
                form.groupbox_3.Visible = false
            end
            form.material_grid:SetItemAddInfo(nx_int(i - 1), nx_int(2), nx_widestr(item))
        end
    end
    local num = count_item(nx_string(formula_id))
    if nx_int(num) > nx_int(999) then
        num = nx_int(999)
    end
    form.ipt_1.MaxDigit = nx_int(num)
    if nx_number(num) >= 1 then
        form.ipt_1.Text = nx_widestr(1)
    else
        form.ipt_1.Text = nx_widestr(0)
    end
    form.btn_composite.Text = nx_widestr(life_btn_name_table[nx_string(Profession)][1])
    form.btn_composite_refine.Text = nx_widestr(life_btn_name_table[nx_string(Profession)][2])
    if not is_Learned_formula(formula_id) then
        form.product_grid:ChangeItemImageToBW(nx_int(0), true)
        form.groupbox_3.Visible = false
        form.btn_add_to_share.Visible = false
    elseif check_can_share(form) == false then
        form.btn_add_to_share.Visible = false
    else
        form.btn_add_to_share.Visible = true
    end
    if npc_limit_table ~= "" then
        form.btn_add_to_share.Visible = false
    end
    if Profession == "sh_qg" then
        form.groupbox_3.Visible = false
    end
    local GameModule = iniformula:ReadString(sec_index, nx_string("GameName"), "")
    local TableNPCLimit = iniformula:ReadString(sec_index, nx_string("TableNPCLimit"), "")
    if TableNPCLimit ~= "" then
        form.lbl_tabletips.Visible = true
    else
        form.lbl_tabletips.Visible = false
    end
    if GameModule == "BrokenDoorModule" and TableNPCLimit == "" then
        form.btn_composite.Visible = true
        form.btn_composite_refine.Visible = true
        form.ipt_1.Visible = true
        form.lbl_10.Visible = true
    else
        form.btn_composite.Visible = true
        form.btn_composite_refine.Visible = false
        if GameModule ~= "" then
            form.ipt_1.Visible = false
            form.lbl_10.Visible = false
        else
            form.ipt_1.Visible = true
            form.lbl_10.Visible = true
        end
    end
end
