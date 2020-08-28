-- redis store: will store plgin info into redis.
-- author:wuwh(wuwh6@asiainfo.com)
local ipairs = ipairs
local table_insert = table.insert
local table_concat = table.concat
local type = type
local xpcall = xpcall
local json = require("gateway.utils.json")
local gateway_db = require("gateway.store.gateway_db")


local _M = {
    desc = "store access & local cache manage"
}

-- 获取插件的配置选择信息
function _M.get_selector(plugin, store, selector_id)
    if not selector_id or selector_id == "" or type(selector_id) ~= "string" then
        return nil
    end
    local selectid = "selector_"..selector_id;

    local selector,error = store:getHashInfo(plugin,selectid);
    


    if not err and selector  then
        -- ngx.log(ngx.INFO, "selectid="..selectid..selector)
        return selector
    end

    return nil
end

--获取选择器下的规则配置
function _M.get_rules_of_selector(plugin, store, rule_ids)

    ngx.log(ngx.INFO, "selectid=")

    if not rule_ids or type(rule_ids) ~= "table" or #rule_ids == 0 then
        return {}
    end

    local to_concat = {}
    for _, r in ipairs(rule_ids) do
        table_insert(to_concat, "rule_" .. r )
    end
    local to_get_rules_ids = table_concat(to_concat, " ")
    if not to_get_rules_ids or to_get_rules_ids == "" then
        return {}
    end
    local rules,err = store:getMHashInfo(plugin,to_get_rules_ids);
    
    if err then
        ngx.log(ngx.ERR, "error to get rules of selector")
        return {}
    end
    if rules and type(rules) == "table" and #rules > 0 then
        local format_rules = {}

        -- reorder the rules as the order stored in selector
        for _, rule_id in ipairs(rule_ids) do
            for _, r in ipairs(rules) do
                local tmp = json.decode(r)
                if tmp and tmp.id == rule_id then
                    table_insert(format_rules, tmp)
                end
            end
        end
        return format_rules
    else
        return {}
    end
end

-- function _M.delete_rules_of_selector(plugin, store, rule_ids)
--     if not rule_ids or rule_ids == "" or type(rule_ids) ~= "table" then
--         return true
--     end

--     local to_concat = {}
--     for _, r in ipairs(rule_ids) do
--         table_insert(to_concat, "'" .. r .. "'")
--     end
--     local to_delete_rules_ids = table_concat(to_concat, ",")
--     if not to_delete_rules_ids or to_delete_rules_ids == "" then
--         return true
--     end

--     local delete_result = store:delete({
--         sql = "delete from " .. plugin .. " where `key` in (" .. to_delete_rules_ids .. ") and `type`=?",
--         params = { "rule" }
--     })
--     if delete_result then
--         return true
--     else
--         ngx.log(ngx.INFO, "delete rules of selector err, ", rule_ids)
--         return false
--     end
-- end

-- function _M.delete_selector(plugin, store, selector_id)
--     if not selector_id or selector_id == "" or type(selector_id) ~= "string" then
--         return true
--     end

--     local delete_result = store:delete({
--         sql = "delete from " .. plugin .. " where `key` = ? and `type` = ?",
--         params = { selector_id, "selector" }
--     })
--     if delete_result then
--         return true
--     else
--         ngx.log(ngx.INFO, "delete selector err, ", selector_id)
--         return false
--     end
-- end

-- 获取配置信息从redis中
function _M.get_meta(plugin, store)

    local meta,err = store:getHashInfo(plugin,"meta");
    
    -- local meta, err = store:query({
    --     sql = "select * from " .. plugin .. " where `type` = ? limit 1",
    --     params = {"meta"}
    -- })

    if not err and meta and type(meta) == "table" and #meta > 0 then
        return meta[1]
    else
        ngx.log(ngx.INFO, "[FATAL ERROR]meta not found while it must exist.")
        return nil
    end
end

-- function _M.update_meta(plugin, store, meta)
--     if not meta or type(meta) ~= "table" then
--         return false
--     end

--     local meta_json_str = json.encode(meta)
--     if not meta_json_str then
--         ngx.log(ngx.INFO, "encode error: meta to save is not json format.")
--         return false
--     end

--     local result = store:update({
--         sql = "update " .. plugin .. " set `value` = ? where `type` = ?",
--         params = {meta_json_str, "meta"}
--     })

--     return result
-- end

-- function _M.update_selector(plugin, store, selector)
--     if not selector or type(selector) ~= "table" then
--         return false
--     end

--     local selector_json_str = json.encode(selector)
--     if not selector_json_str then
--         ngx.log(ngx.INFO, "encode error: selector to save is not json format.")
--         return false
--     end

--     local result = store:update({
--         sql = "update " .. plugin .. " set `value` = ? where `key`=? and `type` = ?",
--         params = {selector_json_str, selector.id, "selector"}
--     })

--     return result
-- end


-- 从redis获取配置并更新本地共享内存配置
function _M.update_local_meta(plugin, store)
    -- local meta, err = store:query({
    --     sql = "select * from " .. plugin .. " where `type` = ? limit 1",
    --     params = {"meta"}
    -- })
    local meta,error = store:getHashInfo(plugin,"meta");

    if err then
        ngx.log(ngx.INFO, "error to find meta from storage when updating local meta, err:", err)
        return false
    end

    if meta and type(meta) == "table" and #meta > 0 then
        local success, err, forcible = gateway_db.set(plugin .. ".meta", meta[1].value or '{}')
        if err or not success then
            ngx.log(ngx.INFO, "update local plugin's meta error, err:", err)
            return false
        end
    else
        ngx.log(ngx.INFO, "can not find meta from storage when updating local meta")
    end

    return true
end
-- 更新选择器配置：从redis配置中更新
function _M.update_local_selectors(plugin, store)
    
    local selectors,error = store:getHashByKeyTag(plugin,"selector_");

    if err then
        ngx.log(ngx.INFO, "error to find selectors from storage when updating local selectors, err:", err)
        return false
    end

    local to_update_selectors = {}
    if selectors and type(selectors) == "table" then
        for _, s in ipairs(selectors) do
            to_update_selectors[s.id] = json.decode(s.value or "{}")
        end

        local success, err, forcible = gateway_db.set_json(plugin .. ".selectors", to_update_selectors)
        if err or not success then
            ngx.log(ngx.INFO, "update local plugin's selectors error, err:", err)
            return false
        end
    else
        ngx.log(ngx.INFO, "the size of selectors from storage is 0 when updating local selectors")
        local success, err, forcible = gateway_db.set_json(plugin .. ".selectors", {})
        if err or not success then
            ngx.log(ngx.INFO, "update local plugin's selectors error, err:", err)
            return false
        end
    end

    return true
end
--更新选择器下的规则
function _M.update_local_selector_rules(plugin, store, selector_id)
    if not selector_id then
        ngx.log(ngx.INFO, "error to find selector from storage when updating local selector rules, selector_id is nil")
        return false
    end

    local selector = _M.get_selector(plugin, store, selector_id)
    if not selector then
        ngx.log(ngx.INFO, "error to find selector from storage when updating local selector rules, selector_id:", selector_id)
        return false
    end

    selector = json.decode(selector)
    local rules_ids = selector.rules or {}
    ngx.log(ngx.INFO, "rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr:", rules_ids)


    local rules = _M.get_rules_of_selector(plugin, store, rules_ids)
    ngx.log(ngx.INFO, "rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr:get_rules_of_selector", rules)


    local success, err, forcible = gateway_db.set_json(plugin .. ".selector." .. selector_id .. ".rules", rules)
    if err or not success then
        ngx.log(ngx.INFO, "update local rules of selector error, err:", err)
        return false
    end

    return true
end

function _M.create_selector(plugin, store, selector)
    return store:insert({
        sql = "insert into " .. plugin .. "(`key`, `value`, `type`, `op_time`) values(?,?,?,?)",
        params = { selector.id, json.encode(selector), "selector", selector.time }
    })
end
 --add by wuwenhui 创建信息
-- function _M.create_pluginData(plugin, store, data,types,chanid,id)
--     ngx.log(ngx.INFO,"data>>>>>>>>>>>>>>>>>>>>>>"..json.encode(data) .. chanid)
--     return store:insert({
--         --sql = "insert into " .. plugin .. "(`key`, `value`, `type`, `op_time`) values(?,?,?,?)",
--         sql = "insert into " .. plugin .. "(`key`, `value`, `type`, `chanid`) values(?,?,?,?)",
--         params = { id, json.encode(data),types, chanid}
--     })
-- end



-- function _M.update_rule(plugin, store, rule)
--     return store:update({
--         sql = "update " .. plugin .. " set `value`=?,`op_time`=? where `key`=? and `type`=?",
--         params = { json.encode(rule), rule.time, rule.id, "rule" }
--     })
-- end

-- function _M.create_rule(plugin, store, rule)
--     return store:insert({
--         sql = "insert into " .. plugin .. "(`key`, `value`, `op_time`, `type`) values(?,?,?,?)",
--         params = { rule.id, json.encode(rule), rule.time, "rule" }
--     })
-- end

function _M.get_enable(plugin, store)
    return store:query({
        sql = "select `value` from meta where `key`=?",
        params = { plugin .. ".enable" }
    })
end

function _M.update_enable(plugin, store, enable)
    return store:update({
        sql = "replace into meta SET `key`=?, `value`=?",
        params = { plugin .. ".enable", enable }
    })
end


-- ########################### local cache init start #############################
function _M.init_rules_of_selector(plugin, store, selector_id)
    if not selector_id then
        ngx.log(ngx.INFO, "error: selector_id is nil")
        return false
    end

    local selector = _M.get_selector(plugin, store, selector_id)
    if not selector  then
        ngx.log(ngx.INFO, "error to find selector from storage when initializing plugin[" .. plugin .. "] local selector rules, selector_id:", selector_id)
        return false
    end

    -- selector = json.decode(selector)
    local rules_ids = selector.rules or {}
    ngx.log(ngx.INFO, plugin .. ".selector." .. selector_id .. ".rulesids&&&&&&&&&&&&&&&&&&&&&&&&&&&7",json.decode(rules_ids))

    local rules = _M.get_rules_of_selector(plugin, store, rules_ids)
    ngx.log(ngx.INFO, plugin .. ".selector." .. selector_id .. ".rules"..json.encode(rules))


    local success, err, forcible = gateway_db.set_json(plugin .. ".selector." .. selector_id .. ".rules", rules)
    if err or not success then
        ngx.log(ngx.INFO, "init plugin[" .. plugin .. "] local rules of selector error, err:", err)
        return false
    end

    return true
end

function _M.init_enable_of_plugin(plugin, store)
    -- 查找enable
    local enables, err = store:query(plugin)
    -- ngx.log(ngx.INFO, '......'..plugin.."enbale")
    if err then
        ngx.log(ngx.INFO, "Load `enable` of plugin[" .. plugin .. "], error: ", err)
        return false
    end

    if enables then
        gateway_db.set(plugin .. ".enable", true)
    else
        gateway_db.set(plugin .. ".enable", false)   
    end    

    -- if enables and type(enables) == "table" and #enables > 0 then
    --     gateway_db.set(plugin .. ".enable", enables[1].value == "1")
    -- else
    --     gateway_db.set(plugin .. ".enable", false)
    -- end

    return true
end

function _M.init_meta_of_plugin(plugin, store)
    -- local meta, err = store:query({
    --     sql = "select * from " .. plugin .. " where `type` = ? limit 1",
    --     params = {"meta"}
    -- })

    -- local enables, err = store:query({
    --     key = plugin 
    -- })

    ngx.log(ngx.ERR, "find meta: type is "..type(plugin) )
    local meta, err = store:getHashInfo(plugin,"meta")
   
    if err then
        ngx.log(ngx.INFO, "error to find meta from storage when initializing plugin[" .. plugin .. "] local meta, err:", err)
        return false
    end


    if meta  then
        local success, err, forcible = gateway_db.set_json(plugin .. ".meta", meta or {})
        if err or not success then
            ngx.log(ngx.INFO, "init local plugin[" .. plugin .. "] meta error, err:", err)
            return false
        end
    else
        ngx.log(ngx.INFO, "can not find meta from storage when initializing plugin[" .. plugin .. "] local meta")
    end

    return true
end

function _M.init_selectors_of_plugin(plugin, store)
    --获取选择器
    local selectors, err = store:getHashByKeyTag(plugin,"selector");

    if err then
        ngx.log(ngx.INFO, "error to find selectors from storage when initializing plugin[" .. plugin .. "], err:", err)
        return false
    end
    local to_update_selectors = {}
    if selectors and type(selectors) == "table" then
        for _, s in ipairs(selectors) do
            -- local s = json.decode(s1);
            -- local id = s.id
            -- ngx.log(ngx.INFO, "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"..s )
            -- local s_id = s.id
            to_update_selectors[s.id] = s;
            -- init this selector's rules local cache
            local init_rules_of_it = _M.init_rules_of_selector(plugin, store, s.id)
            if not init_rules_of_it then
                return false
            end
        end

        local success, err, forcible = gateway_db.set_json(plugin .. ".selectors", to_update_selectors)
        if err or not success then
            ngx.log(ngx.INFO, "init local plugin[" .. plugin .. "] selectors error, err:", err)
            return false
        end
    else
        ngx.log(ngx.INFO, "the size of selectors from storage is 0 when initializing plugin[" .. plugin .. "] local selectors")
        local success, err, forcible = gateway_db.set_json(plugin .. ".selectors", {})
        if err or not success then
            ngx.log(ngx.INFO, "init local plugin[" .. plugin .. "] selectors error, err:", err)
            return false
        end
    end

    return true
end
-- ########################### local cache init end #############################


-- 获取redis网关配置的信息
function _M.compose_plugin_data(store, plugin)
    local data = {}
    local ok, e
    ok = xpcall(function()
       
        local meta, err = store:getHashInfo(plugin,"meta");

        if err then
            ngx.log(ngx.INFO, "error to find meta from storage when fetching data of plugin[" .. plugin .. "], err:", err)
            return false
        end

        if meta and type(meta) == "table" and #meta > 0 then
            data[plugin .. ".meta"] = json.decode(meta[1]) or {}
        else
            ngx.log(ngx.INFO, "can not find meta from storage when fetching data of plugin[" .. plugin .. "]")
            return false
        end
        local selectors, err = store:getHashByKeyTag(plugin,"selector");

        if err then
            ngx.log(ngx.INFO, "error to find selectors from storage when fetching data of plugin[" .. plugin .. "], err:", err)
            return false
        end

        local to_update_selectors = {}
        if selectors and type(selectors) == "table" then
            for _, s in ipairs(selectors) do
                to_update_selectors[s.id] = json.decode(s or "{}")

                -- init this selector's rules local cache
                local selector_id = s.id
                if not selector_id then
                    ngx.log(ngx.INFO, "error: selector_id is nil")
                    return false
                end

                local selector = _M.get_selector(plugin, store, selector_id)
                if not selector  then
                    ngx.log(ngx.INFO, "error to find selector from storage when fetch plugin[" .. plugin .. "] selector rules, selector_id:", selector_id)
                    return false
                end

                selector = json.decode(selector)
                local rules_ids = selector.rules or {}
                local rules = _M.get_rules_of_selector(plugin, store, rules_ids)
                data[plugin .. ".selector." .. selector_id .. ".rules"] = rules
            end

            data[plugin .. ".selectors"]= to_update_selectors
        else
            ngx.log(ngx.INFO, "the size of selectors from storage is 0 when fetching data of plugin[" .. plugin .. "] selectors")
            data[plugin .. ".selectors"] = {}
        end

        return true, data
    end, function()
        e = debug.traceback()
    end)

    if not ok or e then
        ngx.log(ngx.INFO, "[fetch plugin's data error], plugin:", plugin, " error:", e)
        return false
    end

    return true, data
end

-- ########################### init cache when starting gateway #############################
function _M.load_data_by_redis(store, plugin)
    local ok, e
    ok = xpcall(function()
        local v = plugin
        if not v or v == "" then
            ngx.log(ngx.INFO, "params error, the `plugin` is nil")
            return false
        end

        if v == "stat" then
            return
        elseif v == "kvstore" then
            local init_enable = _M.init_enable_of_plugin(v, store)
            if not init_enable then
                ngx.log(ngx.INFO, "load data of plugin[" .. v .. "] error, init_enable:", init_enable)
                return false
            else
                ngx.log(ngx.INFO, "load data of plugin[" .. v .. "] success")
            end
        else -- ignore `stat` and `kvstore`
            local init_enable = _M.init_enable_of_plugin(v, store)
            local init_meta = _M.init_meta_of_plugin(v, store)
            local init_selectors_and_rules = _M.init_selectors_of_plugin(v, store)
            if not init_enable or not init_meta or not init_selectors_and_rules then
                ngx.log(ngx.INFO, "load data of plugin[" .. v .. "] error, init_enable:", init_enable, " init_meta:", init_meta, " init_selectors_and_rules:", init_selectors_and_rules)
                return false
            else
                ngx.log(ngx.INFO, "load data of plugin[" .. v .. "] success")
            end
        end
    end, function()
        e = debug.traceback()
    end)

    if not ok or e then
        ngx.log(ngx.INFO, "[load plugin's data error], plugin:", plugin, " error:", e)
        return true
    end

    return true
end

return _M
