local modn = minetest.get_current_modname()
local prepare_for_winter = minetest.registered_nodes["nc_nature:dirt_with_leaf_litter"]
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
        amount = 2,
        time = 1,
        minacc = {x = -0.1, y = -0.5, z = -0.1},
        maxacc = {x = 0.1, y = -0.5, z = 0.1},
        minexptime = 4,
        maxexptime = 6,
        minsize = 1.2,
        maxsize = 2.2,

        collisiondetection = true,
        collision_removal = true,
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
    walkable = true,
    floodable = true,
	paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.488, 0.5},
		}
	},
    groups = {green = 2, flammable = 2, falling_repose = 2, falling = 1, duff = 1, duff_leaflitter = 1, loose = 1},
    on_ignite = "nc_fire:ash_lump",
    on_punch = function(pos,node)
    end
})
end
nodecore.register_limited_abm(
    {
        label = "Fallen leaf litter logic",
        nodenames = {"group:duff_leaflitter"},
        interval = 90, -- 60 or 126
        chance = 10,
        catch_up = true,
        action = function(pos,node)
            local nodename = node.name
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local chance = math.random(1000)
            local new_param2 = math.random(0,3)
            if(chance > 70)then
                local function leaflitter_decay()
                    local digit = string.find(nodename,"%d") -- find the number in the nodename
                    local lv = digit and tonumber(string.sub(nodename,digit))
                    if(lv < 3)then
                        minetest.set_node(pos,{name = modn..":leaflitter"..lv+1, param2 = new_param2}) -- place next decay stage if not at max decay
                    elseif(lv == 3 and minetest.get_item_group(minetest.get_node(pos_under).name,"soil") > 0)then
                        local half_chance = math.random(2) == 2
                        if(half_chance)then
                            local node = prepare_for_winter and "nc_nature:dirt_with_leaf_litter" or "nc_tree:peat"
                            minetest.set_node(pos_under,{name = node}) -- else let decay stage become incorporated into underlying soil as peat
                        end
                            minetest.remove_node(pos)
                    end
                end
                leaflitter_decay()
            elseif(chance > 876 and nodename ~= modn..":leaflitter3")then
                local function leaflitter_relocate()
                    local p1 = {x = pos.x + 1, y = pos.y, z = pos.z + 1} -- corner1
                    local p2 = {x = pos.x - 1, y = pos.y, z = pos.z - 1} -- corner2
                    local near_air_nodes = minetest.find_nodes_in_area(p1, p2, "air") -- search for air nearby in a 3x3x1 area

                    if(#near_air_nodes > 0)then
                        local chosen_air = near_air_nodes[math.random(#near_air_nodes)] -- randomly choose a node from the options
                        local near_air_below = {x = chosen_air.x, y = chosen_air.y - 1, z = chosen_air.z}

                        suitable_node_below = minetest.get_node(near_air_below).name ~= "air" and
                        minetest.get_item_group(minetest.get_node(near_air_below).name, "duff_leaflitter") == 0 -- node must not have air or another leaflitter node underneath it

                        if(chosen_air and suitable_node_below)then -- perform placement and removal for relocation
                            minetest.set_node(chosen_air, {name = nodename, param2 = new_param2}) -- replace node
                            minetest.remove_node(pos)
                        end
                    end
                end
                leaflitter_relocate()
            end
            
        end
    })