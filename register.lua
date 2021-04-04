local modn = minetest.get_current_modname()

--  --  --  -- Leaf Litter  --  --  --  --
duff.register_duff({
    source_node = "nc_tree:leaves",
    name = "leaf_litter",
    settle_def = {
        chance = 989,
        neighbors = {},
        catch_up = false,
        placenode = modn..":leaflitter1"
    },
    particle_def = {
        amount = 4,
        time = 4,
        minacc = {x = 0, y = -0.4, z = 0},
        maxacc = {x = 0, y = -0.6, z = 0},
        minexptime = 3,
        maxexptime = 6,
        minsize = 1.2,
        maxsize = 2.2,

        collisiondetection = true,
        collision_removal = false,
        vertical = true,
        texture = "duff_spore2.png",
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 2},
        {
            type = "sheet_2d",
            frames_w = 1,
            frames_h = 9,
            frame_length = 2/9,
        },
        glow = 12
    }
})
for n = 1, 3 do
minetest.register_node(modn..":leaflitter"..n, {
    description = "leaflitter"..n..".png",
	tiles = {
		"leaflitter"..n..".png"
	},
	drawtype = "nodebox",
    walkable = false,
    floodable = true,
    buildable_to = true,
	paramtype = "light",
    sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.485, 0.5},
		}
	},
    groups = {green = 2, flammable = 2, falling_repose = 2, falling = 1, duff = 1, duff_leaflitter = 1, loose = 1},
    on_ignite = "nc_fire:ash_lump"
})
end
nodecore.register_limited_abm(
    {
        label = "Leaf Litter Logic",
        nodenames = {"group:duff_leaflitter"},
        interval = 60,
        chance = 10,
        catch_up = true,
        action = function(pos,node)
            local nodename = node.name
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local chance = math.random(1000)
            if(chance > 992)then --992
                local function leaflitter_decay()
                    local digit = string.find(nodename,"%d")
                    local lv = digit and tonumber(string.sub(nodename,digit))
                    if(lv < 3)then
                        minetest.set_node(pos,{name = modn..":leaflitter"..lv+1})
                    else
                        minetest.set_node(pos_under,{name = "nc_tree:peat"})
                        minetest.remove_node(pos)
                    end
                end
                leaflitter_decay()
            elseif(chance > 856)then -- 856
                local function leaflitter_relocate()
                    local p1 = {x = pos.x + 1, y = pos.y, z = pos.z + 1}
                    local p2 = {x = pos.x - 1, y = pos.y, z = pos.z - 1}
                    local near_air = minetest.find_nodes_in_area(p1, p2, "air")
                    near_air = near_air and #near_air > 0 and near_air[math.random(#near_air)]
                    near_air = near_air and minetest.get_node({x = near_air.x, y = near_air.y - 1, z = near_air.z}).name ~= "air" and near_air
                return near_air and minetest.set_node(near_air, {name = nodename}) and minetest.remove_node(pos)
                end
                leaflitter_relocate()
            end
            
        end
    })