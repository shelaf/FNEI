local CraftingBuildingsSett = {
  classname = "FNCraftingBuildingsSett",
}

local cat_text = "cat"
local buildings = "buildings"
local categoties = "categoties"

function CraftingBuildingsSett.get_val(setting)
  local global_set = Settings.get_global_sett()

  if not global_set[setting.name] then global_set[setting.name] = {} end
  global_set = global_set[setting.name]

  if not global_set[categoties] then
    local craft_tb = get_crafting_categories_list()

    global_set[categoties] = {}
    for cat, items in pairs(craft_tb) do
      global_set[categoties][cat] = setting.def_val
    end
  end

  if not global_set[buildings] then 
    local craft_tb = get_crafting_categories_list()

    global_set[buildings] = {}
    for cat, items in pairs(craft_tb) do
      for _, item in pairs(items) do
        if item.type == "building" then
          global_set[buildings][item.val.name] = setting.def_val
        else
          global_set[buildings][item.val] = setting.def_val
        end
      end
    end
  end

  return global_set
end

function CraftingBuildingsSett.set_val(setting, val)
  local gl_sett = CraftingBuildingsSett.get_val(setting)

  if gl_sett[val.type] and gl_sett[val.type][val.name] ~= nil then
    if val.val == 2 then
      gl_sett[val.type][val.name] = true
    elseif val.val == 4 then
      gl_sett[val.type][val.name] = false
    end
  end
end

function CraftingBuildingsSett.add_label_func(parent, sett) end

function CraftingBuildingsSett.split_cat(category)
  local ret_str = string.format("%.12s", category)
  if string.len(category) > 12 then
    return ret_str .. "…"
  end
  return ret_str
end

function CraftingBuildingsSett.add_content_func(parent, sett)
  local settings = CraftingBuildingsSett.get_val(sett)
  local craft_tb = get_crafting_categories_list()
  local gui_template = {}

  for cat, items in pairs(craft_tb) do
    local flow_childer = {}

    table.insert(flow_childer, { type = "sprite-button", name = sett.name .. "_" .. cat_text .. "_" .. cat .. "_but", 
                                 style = CraftingBuildingsSett.get_category_style(settings, cat),
                                 tooltip = {"", cat, "\n", {"fnei.left-eneble-click"}, "\n", {"fnei.right-disable-click"}},
                                 caption = CraftingBuildingsSett.split_cat(cat) })

    for _, item in pairs(items) do
      if item.type == "building" then
        table.insert(flow_childer, { type = "choose-elem-button", name = sett.name .. "_" .. cat .. "_" .. item.val.name, 
                                     elem_type = "item", elem_value = item.val.name, locked = true,
                                     style = CraftingBuildingsSett.get_building_style(settings, cat, item.val.name),
                                     tooltip = {"", Gui.get_local_name(item.val), "\n", {"fnei.left-eneble-click"}, "\n", {"fnei.right-disable-click"}},
        })
      elseif item.type == "player" then
        table.insert(flow_childer, { type = "sprite-button", name = sett.name .. "_" .. cat .. "_" .. item.val,  
                                     style = CraftingBuildingsSett.get_building_style(settings, cat, item.val),
                                     tooltip = {"", {"fnei.handcraft"}, "\n", {"fnei.left-eneble-click"}, "\n", {"fnei.right-disable-click"}},
                                     sprite = "fnei_hand_icon",
        })
      end
    end

    table.insert(gui_template, { type = "flow", name = sett.name .. "-flow-" .. cat, direction = "horizontal", children = flow_childer })
  end

  gui_template = {
    { type = "table", name = sett.name .."-table", style = "fnei_settings_content-table", column_count = 1, children = {
      { type = "label", name = "header-label-2", style = "fnei_settings_craft-category-label", caption = {"fnei.craftin-cat-msg"} },
      { type = "scroll-pane", name = sett.name .. "-scroll-pane", style = "fnei_settings_craft-cat-scroll", children = {
        { type = "table", name = sett.name .. "-flow-table", style = "fnei_settings_content-table", column_count = 1, children = gui_template }
      }}
    }}
  }

  Gui.add_gui_template(parent, gui_template)
end

function CraftingBuildingsSett.parse_name(name)
  local ret_tb = {}

  for k in string.gmatch(name, "[^_]+") do
    table.insert(ret_tb, k)
  end

  return ret_tb
end

function CraftingBuildingsSett.change_category_style(sett_name, elem_name)
  local settings = Settings.get_val(sett_name)
  local parent = Gui.get_gui(Gui.get_pos(), sett_name .. "-flow-table")
  local parse_str

  for _,flow_gui in pairs(parent.children) do
    for _,gui_elem in pairs(flow_gui.children) do
      parse_str = CraftingBuildingsSett.parse_name(gui_elem.name)
      if parse_str[4] == cat_text and parse_str[5] == elem_name then
        gui_elem.style = CraftingBuildingsSett.get_category_style(settings, elem_name)
      elseif parse_str[4] == elem_name then
        gui_elem.style = CraftingBuildingsSett.get_building_style(settings, elem_name, parse_str[5])
      end
    end
  end
end

function CraftingBuildingsSett.change_building_style(sett_name, elem_name)
  local settings = Settings.get_val(sett_name)
  local parent = Gui.get_gui(Gui.get_pos(), sett_name .. "-flow-table")
  local parse_str

  for _,flow_gui in pairs(parent.children) do
    for _,gui_elem in pairs(flow_gui.children) do
      parse_str = CraftingBuildingsSett.parse_name(gui_elem.name)
      if parse_str[4] ~= cat_text and parse_str[5] == elem_name then
        gui_elem.style = CraftingBuildingsSett.get_building_style(settings, parse_str[4], elem_name)
      end
    end
  end
end

function CraftingBuildingsSett.event(event, sett_name)
  local gui_elem = CraftingBuildingsSett.parse_name(event.element.name or "")
  
  if gui_elem[4] == cat_text then
    Settings.set_val(sett_name, {type = categoties, name = gui_elem[5], val = event.button })
    CraftingBuildingsSett.change_category_style(sett_name, gui_elem[5])
  else
    Settings.set_val(sett_name, {type = buildings, name = gui_elem[5], val = event.button })
    CraftingBuildingsSett.change_building_style(sett_name, gui_elem[5])
  end
end

function CraftingBuildingsSett.event_init(sett)
  local event = sett.event or CraftingBuildingsSett.event
  Events.add_custom_event(Controller.get_cont("settings").get_name(), "sprite-button", sett.name, event)
  Events.add_custom_event(Controller.get_cont("settings").get_name(), "choose-elem-button", sett.name, event)
  Events.add_custom_event(Controller.get_cont("settings").get_name(), "label", sett.name, event)
end

function CraftingBuildingsSett.get_building_style(settings, cat_name, item_name)
  if not settings[buildings][item_name] then
    return "fnei_settings_disabled-building"
  elseif settings[categoties][cat_name] then
    return "fnei_settings_enabled-building"
  else
    return "fnei_settings_hidden-building"
  end
end

function CraftingBuildingsSett.get_category_style(settings, cat_name)
  if settings[categoties][cat_name] then
    return "fnei_settings_enable-category"
  else
    return "fnei_settings_disable-category"
  end
end

return CraftingBuildingsSett