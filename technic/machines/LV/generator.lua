-- The electric generator.
-- A simple device to get started on the electric machines.
-- Inefficient and expensive in fuel (200EU per tick)
-- Also only allows for LV machinery to run.

minetest.register_alias("generator", "technic:generator_lv")
minetest.register_alias("generator", "technic:generator_lv_active")

minetest.register_craft({
	output = 'technic:generator',
	recipe = {
		{'default:stone', 'default:stone',        'default:stone'},
		{'default:stone', '',                     'default:stone'},
		{'default:stone', 'default:copper_ingot', 'default:stone'},
	}
})
technic.register_generator({tier="LV",supply=200})