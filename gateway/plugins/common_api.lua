local ipairs = ipairs
local type = type
local tostring = tostring
local table_insert = table.insert
local json = require("gateway.utils.json")
local gateway_db = require("gateway.store.gateway_db")
local utils = require("gateway.utils.utils")
local stringy = require("gateway.utils.stringy")
local aes = require("resty.aes")

-- build common apis
return function(plugin)
    local API = {}

   

    -- fetch config from store
    -- API["/" .. plugin .. "/fetch_config"] = {
    --     GET = function(store)
    --         return function(req, res, next)
    --             local success, data =  dao.compose_plugin_data(store, plugin)
    --             if success then
    --                 return res:json({
    --                     success = true,
    --                     msg = "succeed to fetch config from store",
    --                     data = data
    --                 })
    --             else
    --                 ngx.log(ngx.ERR, "error to fetch plugin[" .. plugin .. "] config from store")
    --                 return res:json({
    --                     success = false,
    --                     msg = "error to fetch config from store"
    --                 })
    --             end
    --         end
    --     end
    -- }

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

  

    

   


   




   

    return API
end
