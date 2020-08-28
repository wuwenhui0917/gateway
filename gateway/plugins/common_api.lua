local ipairs = ipairs
local type = type
local tostring = tostring
local table_insert = table.insert
local json = require("gateway.utils.json")
local gateway_db = require("gateway.store.gateway_db")
local utils = require("gateway.utils.utils")
local stringy = require("gateway.utils.stringy")
local aes = require("resty.aes")
local dao = require("gateway.store.dao")
local redisdao = require("gateway.store.redis_dao")
local stream_sock = ngx.socket.tcp
local log = ngx.log
local ERR = ngx.ERR
local WARN = ngx.WARN
local DEBUG = ngx.DEBUG
local sub = string.sub
local re_find = ngx.re.find
local new_timer = ngx.timer.at
local shared = ngx.shared
local debug_mode = ngx.config.debug
local concat = table.concat
local tonumber = tonumber
local tostring = tostring
local ipairs = ipairs
local ceil = math.ceil
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
local pcall = pcall
local ok, upstream = pcall(require, "ngx.upstream")
if not ok then
    error("ngx_upstream_lua module required")
end

local set_peer_down = upstream.set_peer_down
local get_primary_peers = upstream.get_primary_peers
local get_backup_peers = upstream.get_backup_peers
local get_upstreams = upstream.get_upstreams

local upstream_checker_statuses = {}

-- local function gen_peers_status_info(peers, bits, idx)
--     local npeers = #peers
--     for i = 1, npeers do
--         local peer = peers[i]
--         bits[idx] = "        "
--         bits[idx + 1] = peer.name
--         if peer.down then
--             bits[idx + 2] = " DOWN\n"
--         else
--             bits[idx + 2] = " up\n"
--         end
--         idx = idx + 3
--     end
--     return idx
-- end

-- build common apis
return function(plugin)
    local API = {}

    -- get config in gateway's node now
    API["/" .. plugin .. "/config"] = {
        GET = function(store)
            return function(req, res, next)
                local enable = gateway_db.get(plugin .. ".enable") or false
                local meta = gateway_db.get_json(plugin .. ".meta") or {}

                local selectors = {}
                if meta and meta.selectors and type(meta.selectors)=="table" then
                    for i, sid in ipairs(meta.selectors) do
                        local selector = {}
                        local cache_selectors = gateway_db.get_json(plugin .. ".selectors") or {}
                        for j, selector_detail in pairs(cache_selectors) do
                            if j == sid then
                                selector = selector_detail
                                if selector_detail.rules and type(selector_detail.rules) == "table" then
                                    local rule_ids = selector_detail.rules
                                    local cache_rules = gateway_db.get_json(plugin .. ".selector." .. sid .. ".rules") or {}
                                    local rules = {}
                                    for m, rule_id in ipairs(rule_ids) do
                                        for n, rule in ipairs(cache_rules) do
                                            if rule_id == rule.id then
                                                table_insert(rules, rule)
                                            end
                                        end
                                    end
                                    selector.rules = rules
                                else
                                    selector.rules = {}
                                end
                            end
                        end
                        table_insert(selectors, selector)
                    end
                end

                return res:json({
                    success = true,
                    msg = "succeed to get configuration in this node",
                    data = {
                        enable = enable,
                        selectors = selectors
                    }
                })
            end
        end
    }

    API["/" .. plugin .. "/reload"] = {
        GET = function(store)
            return function(req, res, next)
                local gateway = context.gateway
                local config = gateway.data.config
                local store = gateway.data.store
                local result = false
                local objplugin  = json.decode(plugin);

                if  config.store == "mysql" then
                    result = dao.load_data_by_mysql(store, plugin)
                -- elseif config.store == "redis" 
                --     result = redisdao.load_data_by_redis(store, plugin)
                end
                if  config.store == "redis" then
                    store:init()
                    result = redisdao.load_data_by_redis(store, plugin)
                
                end

                
                return res:json({
                    success = result,
                    msg = "succeed to get configuration in this node",
                    plugin=plugin
                    
                })
            end
        end
    }

    -- API["/" .. plugin .. "/reload"] = {
    --     GET = function(store)
    --         return function(req, res, next)
    --             local gateway = context.gateway
    --             local config = gateway.data.config
    --             local store = gateway.data.store
    --             local available_plugins = config.plugins
    --             local result 
    --             if  config.store == "mysql" then
    --                 result = dao.load_data_by_mysql(store, v)
    --             elseif config.store == "redis" 
    --                 result = redisdao.load_data_by_redis(store, plugin)
    --             end

    --             return res:json({
    --                 success = result,
    --                 msg = "succeed to get configuration in this node",
    --                 data = {
    --                     enable = enable,
    --                     selectors = selectors
    --                 }
    --             })
    --         end
    --     end
    -- }
    API["/upstream"] = {
        GET = function(store)
            return function(req, res, next)
                local result = false
                local nodes={}
               
                local us=false
                local us, err = get_upstreams()
                ngx.log(ngx.INFO, "shibai " )
              
                if not us then
                    result = false

                else 
                    local n = #us
                    for i = 1, n do
                        
                        local u = us[i]
                        local upsream={}
                        local peers, err = get_primary_peers(u)
                        if not peers then
                            result = false
                            break
                        end
                       
                        local bakpeers, err = get_backup_peers(u)
                        if not bakpeers then
                            result = false
                            break
                        end
                        upsream.name=u
                        upsream.primarynodes=peers
                        upsream.backuppeers=bakpeers
                        nodes[u]=upsream


                    end

                end
                
                
                return res:json({
                    success = result,
                    data = nodes
                    
                })
            end
        end
    }


    







    return API
end
