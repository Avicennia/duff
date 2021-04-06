-- luacheck: globals duff minetest _ ItemStack nodecore

-- LUALOCALS -- -- -- -- -- -- -- --
local minetest, nodecore
    = minetest, nodecore
-- LUALOCALS -- -- -- -- -- -- -- --
local modn = minetest.get_current_modname()

duff = {}
local duff = duff

duff.duffs = {}
duff.register_duff = function(def) -- Registers a new duff
    if(def and def.name)then
        duff.duffs[def.name] = def
    end
end

duff.node_duff_map = {} -- key-value array storage for accessing all duffs that a node may have, [nodename] = {duffname1, duffname2}
duff.collate_source_nodes = function() -- Searches all registered duffs to register duffs to specific node sources
    for _,v in pairs(duff.duffs)do
        if(v.source_node and v.particle_def)then
            local nodename = v.source_node
            local nodegroups = minetest.registered_nodes[nodename].groups
            nodegroups["duffy"] = 1
            minetest.override_item(nodename, {groups = nodegroups}) -- get groups of node, give it the duffy group so that it will produce duff.
            if(duff.node_duff_map[v.source_node])then
                table.insert(duff.node_duff_map[v.source_node],v.name) -- if this node is already in the map then add to existing duff
            else duff.node_duff_map[v.source_node] = {v.name} -- otherwise make a new entry for this node, starting with this duff
            end
        end
    end
end

duff.get_node_duffs = function(name)
    return duff.node_duff_map[name]
end


--  --  --  --  --  WIND
duff.wind = {x = 0, y = 0, z = 0} -- Controls direction that generated particles move in
duff.blow_wind_random = function() -- Makes wind randomly change direction within some arbitrary params
    duff.wind = {x = math.random(10)/100, y = -math.random(40)/100 ,z = math.random(100)/100}
end
duff.blow_wind_vector = function(v) -- Makes wind blow in a desired vector direction
    local function is_num(n)
        return n and type(n) == "number" and n
    end

    if(is_num(v.x) and is_num(v.y) and is_num(v.z))then
    duff.wind = v
    end
end

nodecore.interval(60, function() duff.blow_wind_random()end) -- reroll wind direction every minute

--  --  --  --  --  PARTICLES

duff.shed_particle = function(pos, duff_particle_def) -- Causes particles to fall as defined by duff definition
    if(pos and duff_particle_def)then
        local particle_def = duff_particle_def
        local bas = {x = 0, y = 0, z = 0}
        
        particle_def.minpos = {x = pos.x - 0.5, y = pos.y-0.5, z = pos.z - 0.5}
        particle_def.maxpos = {x = pos.x + 0.5, y = pos.y-0.5, z = pos.z + 0.5}
        particle_def.minvel = particle_def.minvel or bas
        particle_def.maxvel = particle_def.maxvel or duff.wind or {x = 0.01, y = -0.5, z = 0.01}
        
        minetest.add_particlespawner(particle_def)
    end
end


-- Load in register
local modp = minetest.get_modpath(modn)
dofile(modp.."/register.lua")
duff.collate_source_nodes()



--  --  --  --  --  SHEDDING
nodecore.register_limited_abm(
    {
        label = "Node shedding duff",
        nodenames = {"group:duffy"},
        neighbors = {"air"},
        interval = 6,
        chance = 40,
        catch_up = false,
        action = function(pos)
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            
            if(minetest.get_node(pos_under).name == "air")then
                
                for _,v in pairs(duff.duffs)do
                    local pdef = v.particle_def
                    duff.shed_particle(pos, pdef)
                end
            end
        end
    }
)


--  --  --  --  --  SETTLING

nodecore.register_limited_abm(
    {
        label = "Duff Settle Global",
        nodenames = {"group:duffy"},
        neighbors = {"air"},
        interval = 120,
        chance = 10,
        catch_up = true,
        action = function(pos,node)
            local nodename = node.name
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local space_under_node = minetest.get_node(pos_under).name == "air"

            if(space_under_node)then
            
                local max_depth = {x = pos.x, y = pos.y - 128, z = pos.z}
                local is_floor,where_floor = minetest.line_of_sight(pos_under, max_depth)

                if(where_floor)then -- checking for suitable position underneath
                    local floor_node = minetest.get_node(where_floor).name
                    where_floor = minetest.registered_nodes[floor_node].drawtype == "normal" and where_floor -- make sure odd drawtypes are not selected for placement.
                end

            
                if((not is_floor) and where_floor and nodename and (not floor_has_duff))then
                    local node_duffs = duff.node_duff_map[nodename]

                    if(node_duffs and #node_duffs > 0)then

                        for n = 1, #node_duffs do

                            local duff_def = duff.duffs[node_duffs[n]]
                            local def = duff_def.settle_def
                            local chance = math.random(1000) -- to give later definitions some control of spawn chance within this single abm reg
                            local placenode = def.placenode

                            if(chance > def.chance and placenode and minetest.registered_nodes[placenode.name])then
                                where_floor.y = where_floor.y + 1
                                minetest.set_node(where_floor,placenode) -- place designated duff
                            end
                        end
                    end
                end
            end
        end -- end pyramids ftw, embrace the Gerold
    })