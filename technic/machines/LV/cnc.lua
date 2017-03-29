-- Technic CNC v1.0 by kpoppel
-- Based on the NonCubic Blocks MOD v1.4 by yves_de_beck

-- Idea:
--   Somehow have a tabbed/paged panel if the number of shapes should expand
--   beyond what is available in the panel today.
--   I could imagine some form of API allowing modders to come with their own node
--   box definitions and easily stuff it in the this machine for production.

local S = technic.getter


minetest.register_craft({
	output = 'technic:cnc',
	recipe = {
		{ 'default:glass', 'technic:diamond_drill_head', 'default:glass' },
		{ 'technic:control_logic_unit', 'technic:machine_casing', 'technic:motor' },
		{ 'technic:carbon_steel_ingot', 'technic:lv_cable', 'technic:carbon_steel_ingot' },
	},
})


local shape = {}
local onesize_products = {
	slope = 2,
	slope_edge = 1,
	slope_inner_edge = 1,
	pyramid = 2,
	spike = 1,
	cylinder = 2,
	oblate_spheroid = 1,
	sphere = 1,
	stick = 8,
	slope_upsdown = 2,
	slope_edge_upsdown = 1,
	slope_inner_edge_upsdown = 1,
	cylinder_horizontal = 2,
	slope_lying = 2,
	onecurvededge = 1,
	twocurvededge = 1,
}
local twosize_products = {
	element_straight = 4,
	element_end = 2,
	element_cross = 1,
	element_t = 1,
	element_edge = 2,
}

local cnc_formspec =
"invsize[9,11;]"..
		"label[1,0;"..S("Choose Milling Program:").."]"..
		"image_button[1,0.5;1,1;technic_cnc_slope.png;slope; ]"..
		"image_button[2,0.5;1,1;technic_cnc_slope_edge.png;slope_edge; ]"..
		"image_button[3,0.5;1,1;technic_cnc_slope_inner_edge.png;slope_inner_edge; ]"..
		"image_button[4,0.5;1,1;technic_cnc_pyramid.png;pyramid; ]"..
		"image_button[5,0.5;1,1;technic_cnc_spike.png;spike; ]"..
		"image_button[6,0.5;1,1;technic_cnc_cylinder.png;cylinder; ]"..
		"image_button[7,0.5;1,1;technic_cnc_oblate_spheroid.png;oblate_spheroid; ]"..
		"image_button[8,0.5;1,1;technic_cnc_stick.png;stick; ]"..

		"image_button[1,1.5;1,1;technic_cnc_slope_upsdwn.png;slope_upsdown; ]"..
		"image_button[2,1.5;1,1;technic_cnc_slope_edge_upsdwn.png;slope_edge_upsdown; ]"..
		"image_button[3,1.5;1,1;technic_cnc_slope_inner_edge_upsdwn.png;slope_inner_edge_upsdown; ]"..
		"image_button[4,1.5;1,1;technic_cnc_cylinder_horizontal.png;cylinder_horizontal; ]"..
		"image_button[5,1.5;1,1;technic_cnc_sphere.png;sphere; ]"..

		"image_button[1,2.5;1,1;technic_cnc_slope_lying.png;slope_lying; ]"..
		"image_button[2,2.5;1,1;technic_cnc_onecurvededge.png;onecurvededge; ]"..
		"image_button[3,2.5;1,1;technic_cnc_twocurvededge.png;twocurvededge; ]"..

		"label[1,3.5;"..S("Slim Elements half / normal height:").."]"..

		"image_button[1,4;1,0.5;technic_cnc_full.png;full; ]"..
		"image_button[1,4.5;1,0.5;technic_cnc_half.png;half; ]"..
		"image_button[2,4;1,1;technic_cnc_element_straight.png;element_straight; ]"..
		"image_button[3,4;1,1;technic_cnc_element_end.png;element_end; ]"..
		"image_button[4,4;1,1;technic_cnc_element_cross.png;element_cross; ]"..
		"image_button[5,4;1,1;technic_cnc_element_t.png;element_t; ]"..
		"image_button[6,4;1,1;technic_cnc_element_edge.png;element_edge; ]"..

		"label[0, 5.5;"..S("In:").."]"..
		"list[current_name;src;0.5,5.5;1,1;]"..
		"label[4, 5.5;"..S("Out:").."]"..
		"list[current_name;dst;5,5.5;4,1;]"..

		"list[current_player;main;0,7;8,4;]"..
		"listring[current_name;dst]"..
		"listring[current_player;main]"..
		"listring[current_name;src]"..
		"listring[current_player;main]"

local size = 1;

-- The form handler is declared here because we need it in both the inactive and active modes
-- in order to be able to change programs wile it is running.
local function form_handler(pos, formname, fields, sender)
	-- REGISTER MILLING PROGRAMS AND OUTPUTS:
	------------------------------------------
	-- Program for half/full size
	if fields["full"] then
		size = 1
		return
	end

	if fields["half"] then
		size = 2
		return
	end

	-- Resolve the node name and the number of items to make
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local inputstack = inv:get_stack("src", 1)
	local inputname = inputstack:get_name()
	local multiplier = 0
	for k, _ in pairs(fields) do
		-- Set a multipier for the half/full size capable blocks
		if twosize_products[k] ~= nil then
			multiplier = size * twosize_products[k]
		else
			multiplier = onesize_products[k]
		end

		if onesize_products[k] ~= nil or twosize_products[k] ~= nil then
			meta:set_float("cnc_multiplier", multiplier)
			meta:set_string("cnc_user", sender:get_player_name())
		end

		if onesize_products[k] ~= nil or (twosize_products[k] ~= nil and size == 2) then
			meta:set_string("cnc_product", inputname.."_technic_cnc_"..k)
			--print(inputname.."_technic_cnc_"..k)
			break
		end

		if twosize_products[k] ~= nil and size == 1 then
			meta:set_string("cnc_product", inputname.."_technic_cnc_"..k.."_double")
			--print(inputname.."_technic_cnc_"..k.."_double")
			break
		end
	end
	return
end

-- Action code performing the transformation
local run = function(pos, node)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local eu_input = meta:get_int("LV_EU_input")
	local machine_name = S("%s CNC Machine"):format("LV")
	local machine_node = "technic:cnc"
	local demand = 450

	local result = meta:get_string("cnc_product")
	if inv:is_empty("src") or
			(not minetest.registered_nodes[result]) or
			(not inv:room_for_item("dst", result)) then
		technic.swap_node(pos, machine_node)
		meta:set_string("infotext", S("%s Idle"):format(machine_name))
		meta:set_string("cnc_product", "")
		meta:set_int("LV_EU_demand", 0)
		return
	end

	if eu_input < demand then
		technic.swap_node(pos, machine_node)
		meta:set_string("infotext", S("%s Unpowered"):format(machine_name))
	elseif eu_input >= demand then
		technic.swap_node(pos, machine_node.."_active")
		meta:set_string("infotext", S("%s Active"):format(machine_name))
		meta:set_int("src_time", meta:get_int("src_time") + 1)
		if meta:get_int("src_time") >= 3 then -- 3 ticks per output
			meta:set_int("src_time", 0)
			srcstack = inv:get_stack("src", 1)
			srcstack:take_item()
			inv:set_stack("src", 1, srcstack)
			inv:add_item("dst", result.." "..meta:get_int("cnc_multiplier"))
		end
	end
	meta:set_int("LV_EU_demand", demand)
end

-- The actual block inactive state
minetest.register_node("technic:cnc", {
	description = S("%s CNC Machine"):format("LV"),
	tiles = {
		"technic_cnc_top.png", "technic_cnc_bottom.png", "technic_cnc_side.png",
		"technic_cnc_side.png", "technic_cnc_side.png", "technic_cnc_front.png"
	},
	groups = { cracky = 2, technic_machine = 1, technic_lv = 1 },
	connect_sides = { "bottom", "back", "left", "right" },
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("%s CNC Machine"):format("LV"))
		meta:set_float("technic_power_machine", 1)
		meta:set_string("formspec", cnc_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
	end,
	can_dig = technic.machine_can_dig,
	allow_metadata_inventory_put = technic.machine_inventory_put,
	allow_metadata_inventory_take = technic.machine_inventory_take,
	allow_metadata_inventory_move = technic.machine_inventory_move,
	on_receive_fields = form_handler,
	technic_run = run,
})

-- Active state block
minetest.register_node("technic:cnc_active", {
	description = S("%s CNC Machine"):format("LV"),
	tiles = {
		"technic_cnc_top_active.png", "technic_cnc_bottom.png", "technic_cnc_side.png",
		"technic_cnc_side.png", "technic_cnc_side.png", "technic_cnc_front_active.png"
	},
	groups = { cracky = 2, technic_machine = 1, technic_lv = 1, not_in_creative_inventory = 1 },
	connect_sides = { "bottom", "back", "left", "right" },
	paramtype2 = "facedir",
	drop = "technic:cnc",
	legacy_facedir_simple = true,
	can_dig = technic.machine_can_dig,
	allow_metadata_inventory_put = technic.machine_inventory_put,
	allow_metadata_inventory_take = technic.machine_inventory_take,
	allow_metadata_inventory_move = technic.machine_inventory_move,
	on_receive_fields = form_handler,
	technic_run = run,
	technic_disabled_machine_name = "technic:cnc",
})

technic.register_machine("LV", "technic:cnc", technic.receiver)
technic.register_machine("LV", "technic:cnc_active", technic.receiver)

