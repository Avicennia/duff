-- LUALOCALS -- -- -- -- -- -- -- --
local minetest, nodecore
    = minetest, nodecore
-- LUALOCALS -- -- -- -- -- -- -- --
local modn = minetest.get_current_modname()
local function say(x) return minetest.chat_send_all(type(x) == "string" and x or minetest.serialize(x)) end

duff = {}
local duff = duff

duff.duffs = {}
duff.register_duff = function(def) -- Registers a new duff
    if(def and def.name)then
        duff.duffs[def.name] = def
    end
end

duff.node_duff_map = {} -- key-value storage for interacting ([nodename] = {duffname1, duffname2})
duff.collate_source_nodes = function() -- Searches all registered duffs to register particles for specific node sources
    for k,v in pairs(duff.duffs)do
        if(v.source_node and v.particle_def)then
            local nodename = v.source_node
            local nodegroups = minetest.registered_nodes[nodename].groups
            nodegroups["duffy"] = 1
            minetest.override_item(nodename, {groups = nodegroups}) -- add guarding
            if(duff.node_duff_map[v.source_node])then
                table.insert(duff.node_duff_map[v.source_node],v.name)
            else duff.node_duff_map[v.source_node] = {v.name}
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
    duff.wind = {x = math.random(100)/100, y = -math.random(40)/100 ,z = math.random(100)/100}
end
duff.blow_wind_vector = function(v) -- Makes wind blow in a desired vector direction
    local function is_num(n)
        return n and type(n) == "number" and n
    end

    if(is_num(v.x) and is_num(v.y) and is_num(v.z))then
    duff.wind = v
    end
end

nodecore.interval(60, function() duff.blow_wind_random()end)

--  --  --  --  --  PARTICLES

duff.shed_particle = function(pos, duff_def) -- Causes particles to fall as defined by duff definition
    if(pos and duff_def)then
        local bas = {x = 0, y = 0, z = 0}
        duff_def.minpos = {x = pos.x - 0.5, y = pos.y-0.4, z = pos.z - 0.5}
        duff_def.maxpos = {x = pos.x + 0.5, y = pos.y, z = pos.z + 0.5}
        duff_def.minvel = duff_def.minvel or bas
        duff_def.maxvel = duff_def.maxvel or duff.wind or {x = 0.5, y = -0.5, z = 0.2}
        minetest.add_particlespawner(duff_def)
    end
end



local modp = minetest.get_modpath(modn)
dofile(modp.."/register.lua")
duff.collate_source_nodes()




nodecore.register_limited_abm(
    {
        label = "Dirty Little Littering Node",
        nodenames = {"group:duffy"},
        neighbors = {"air"},
        interval = 3,
        chance = 8,
        catch_up = false,
        action = function(pos,node)
            local nodename = node.name
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
        interval = 4,--120
        chance = 10,--10
        catch_up = true,
        action = function(pos,node)
            local nodename = node.name
            local pos_under = {x = pos.x, y = pos.y - 1, z = pos.z}
            local max_depth = {x = pos.x, y = pos.y - 128, z = pos.z}
            local is_floor,where_floor = minetest.line_of_sight(pos_under, max_depth)
            local floor_has_duff = where_floor and minetest.get_item_group(minetest.get_node(where_floor).name, "duff") > 0
            where_floor.y = where_floor.y + 1
            where_floor = where_floor and minetest.get_node(where_floor).name == "air" and where_floor
            if((not is_floor) and where_floor and nodename and minetest.get_node(pos_under).name == "air" and (not floor_has_duff))then
                local node_duffs = duff.node_duff_map[nodename]
                if(node_duffs and #node_duffs > 0)then
                    for n = 1, #node_duffs do
                        local duff_def = duff.duffs[node_duffs[n]]
                        local def = duff_def.settle_def
                        local chance = math.random(1000)
                        if(chance > def.chance)then
                            minetest.set_node(where_floor,{name = def.placenode})
                        end
                    end
                end
            end
        end
    })
