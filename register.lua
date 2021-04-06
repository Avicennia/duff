-- luacheck: globals duff minetest _ ItemStack nodecore

local modn = minetest.get_current_modname()
--  --  --  -- Leaf Litter  --  --  --  --

--  --  --  --  --  DUFF DEFINITION
for n = 1, 2 do
    local a = n == 1
duff.register_duff({
    source_node = "nc_tree:leaves",
    
    name = "leaf_litter_"..n,
    
    settle_def = {
        chance = 989,
        neighbors = {},
        catch_up = true,
        placenode = {name = modn..":leaflitter1"}
    },
    
    particle_def = {
        amount = 4,
        time = 1,
        minacc = {x = -0.1, y = -0.5, z = -0.1},
        maxacc = {x = 0.1, y = -0.5, z = 0.1},
        minexptime = 4,
        maxexptime = 6,
        minsize = a and 1.2 or 0.5,
        maxsize = a and 2 or 1,

        collisiondetection = true,
        --collision_removal = true,
        vertical = false,
        texture = "duff_leaf"..n..".png",
        animation = {
            type = "vertical_frames",
            aspect_w = 16,
            aspect_h = 16,
            length = 1},
        {
            type = "sheet_2d",
            frames_w = 1,
            frames_h = a and 9 or 18,
            frame_length = a and 1/9 or 1/18,
        },
        glow = 2,
    }
})
end
--  --  --  --  --  NODE REGISTRATIONS
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
})
end
--  --  --  --  --  LEAF LITTER GRINDING RECIPE
nodecore.register_craft({
    label = "grind leaf duff to peat",
    action = "pummel",
    indexkeys = {"group:duff"},
    toolgroups = {crumbly = 2},
    nodes = {
        {
            match = {groups = {duff = true}, count = 24},
            replace = "nc_tree:peat"
        }
    }
})


--  --  --  --  --  ABM AND PERSISTENT BEHAVIOUR
nodecore.register_limited_abm(
    {
        label = "Fallen leaf litter logic",
        nodenames = {"group:duff_leaflitter"},
        interval = 240,
        chance = 10,
        catch_up = true,
        action = function(pos,node)
            local nodename = node.name
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local chance = math.random(10)
            local new_param2 = math.random(0,3)
            
            if(chance > 7)then
                local function leaflitter_decay()
                    local digit = string.find(nodename,"%d") -- find the number in the nodename
                    local lv = digit and tonumber(string.sub(nodename,digit))

                    if(lv < 3)then
                       
                        minetest.set_node(pos,{name = modn..":leaflitter"..lv+1, param2 = new_param2}) -- place next decay stage if not at max decay
                    
                    elseif(lv == 3 and nodecore.node_group("soil",pos_under))then
                        
                        local half_chance = chance > 5
                        if(half_chance)then
                            local prepare_for_winter = minetest.registered_nodes["nc_nature:dirt_with_leaf_litter"] -- check if nc_nature's node is registered
                            local node_repl = prepare_for_winter and "nc_nature:dirt_with_leaf_litter" or "nc_tree:humus"
                            minetest.set_node(pos_under,{name = node_repl}) -- else let decay stage become incorporated into underlying soil as peat
                        end
                        minetest.remove_node(pos)
                    end
                end
                leaflitter_decay()
            elseif(chance > 5 and nodename ~= modn..":leaflitter3")then
                local function leaflitter_relocate()
                    local p1 = {x = pos.x + 1, y = pos.y, z = pos.z + 1} -- corner1
                    local p2 = {x = pos.x - 1, y = pos.y, z = pos.z - 1} -- corner2
                    local near_air_nodes = minetest.find_nodes_in_area(p1, p2, "air") -- search for air nearby in a 3x3x1 area

                    if(#near_air_nodes > 0)then
                        local chosen_air = near_air_nodes[math.random(#near_air_nodes)] -- randomly choose a node from the options
                        local near_air_below = {x = chosen_air.x, y = chosen_air.y - 1, z = chosen_air.z}

                        local suitable_node_below = minetest.get_node(near_air_below).name ~= "air" and
                        (not nodecore.node_group("duff",near_air_below)) -- node must not have air or another leaflitter node underneath it

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