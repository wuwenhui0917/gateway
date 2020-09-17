local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local pcall = pcall
local require = require
require("gateway.lib.globalpatches")()
local utils = require("gateway.utils.utils")
local config_loader = require("gateway.utils.config_loader")
local dao = require("gateway.store.dao")
local redisdao = require("gateway.store.redis_dao")
local hc = require "resty.upstream.healthcheck"

local HEADERS = {
    PROXY_LATENCY = "X-Orange-Proxy-Latency",
    UPSTREAM_LATENCY = "X-Orange-Upstream-Latency",
}

local loaded_plugins = {}

local function load_node_plugins(config, store)
    ngx.log(ngx.DEBUG, "Discovering used plugins")

    local sorted_plugins = {}
    local plugins = config.plugins

    for _, v in ipairs(plugins) do
        local loaded, plugin_handler = utils.load_module_if_exists("gateway.plugins." .. v .. ".handler")
        if not loaded then
            ngx.log(ngx.WARN, "The following plugin is not installed or has no handler: " .. v)
        else
            ngx.log(ngx.DEBUG, "Loading plugin: " .. v)
            table_insert(sorted_plugins, {
                name = v,
                handler = plugin_handler(store),
            })
        end
    end

    table_sort(sorted_plugins, function(a, b)
        local priority_a = a.handler.PRIORITY or 0
        local priority_b = b.handler.PRIORITY or 0
        return priority_a > priority_b
    end)

    return sorted_plugins
end

-- ms
local function now()
    return ngx.now() * 1000
end

-- ########################### Orange #############################
local Gateway = {}
Gateway.vERSION="v0.1"

-- 执行过程:
-- 加载配置
-- 实例化存储store
-- 加载插件
-- 插件排序
function Gateway.init(options)
    options = options or {}
    local store, config
    local status, err = pcall(function()
        local conf_file_path = options.config
        config = config_loader.load(conf_file_path)
        --如果存储是mysql时
        if config.store == "mysql" then
              store = require("gateway.store.mysql_store")(config.store_mysql)
              loaded_plugins = load_node_plugins(config, store)
        else 
            --如果存储时redis时
            if config.store == "redis" then
                store = require("gateway.store.redis_store")(config.store_redis)
                -- ngx.log(ngx.ERR, "redis............. error: " .. store)
                loaded_plugins = load_node_plugins(config, store)
            end
        end    
        
        ngx.update_time()
        config.gateway_start_at = ngx.now()
    end)

    if not status or err then
        ngx.log(ngx.ERR, "Startup error: " .. err)
        os.exit(1)
    end

    Gateway.data = {
        store = store,
        config = config
    }

    return config, store
end

function Gateway.init_worker()
    -- 仅在 init_worker 阶段调用，初始化随机因子，仅允许调用一次
    ngx.log(ngx.ERR, "Startup init_work: ")
    math.randomseed()
    -- 初始化定时器，清理计数器等
    if Gateway.data and Gateway.data.store and Gateway.data.config.store == "mysql" then
        local worker_id = ngx.worker.id()
        if worker_id == 0 then
            local ok, err = ngx.timer.at(0, function(premature, store, config)
                local available_plugins = config.plugins
                for _, v in ipairs(available_plugins) do
                    local load_success = dao.load_data_by_mysql(store, v)
                    if not load_success then
                        os.exit(1)
                    end
                end
            end, Gateway.data.store, Gateway.data.config)

            if not ok then
                ngx.log(ngx.ERR, "failed to create the timer: ", err)
                return os.exit(1)
            end
        end
    end
    if Gateway.data and Gateway.data.store   and Gateway.data.config.store=="redis" then
        local worker_id = ngx.worker.id()
        if worker_id == 0 then
            -- local redisstore=Gateway.data.store
            -- redisstore:init();


            local ok, err = ngx.timer.at(1, function(premature, store, config)
                store:init();
                local available_plugins = config.plugins
                for _, v in ipairs(available_plugins) do
                    local load_success = redisdao.load_data_by_redis(store, v)
                    if not load_success then
                        ngx.log(ngx.ERR, "load data from redis error: system will be exit: ", err)
                        os.exit(1)
                    end
                end
            end, Gateway.data.store, Gateway.data.config)
            if not ok then
                ngx.log(ngx.ERR, "failed to create the timer: ", err)
                return os.exit(1)
            end
        end    


    end   

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:init_worker()
    end
    -- 添加探测脚本
    

end


function Gateway.redirect()
    ngx.ctx.GATEWAY_REDIRECT_START = now()

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:redirect()
    end

    local now_time = now()
    ngx.ctx.GATEWAY_REDIRECT_TIME = now_time - ngx.ctx.GATEWAY_REDIRECT_START
    ngx.ctx.GATEWAY_REDIRECT_ENDED_AT = now_time
end

function Gateway.rewrite()
    ngx.ctx.GATEWAY_REWRITE_START = now()

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:rewrite()
    end

    local now_time = now()
    ngx.ctx.GATEWAY_REWRITE_TIME = now_time - ngx.ctx.GATEWAY_REWRITE_START
    ngx.ctx.GATEWAY_REWRITE_ENDED_AT = now_time
end



function Gateway.access()
    ngx.ctx.GATEWAY_ACCESS_START = now()

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:access()
    end

    local now_time = now()
    ngx.ctx.GATEWAY_ACCESS_TIME = now_time - ngx.ctx.GATEWAY_ACCESS_START
    ngx.ctx.GATEWAY_ACCESS_ENDED_AT = now_time
    ngx.ctx.GATEWAY_PROXY_LATENCY = now_time - ngx.req.start_time() * 1000
    ngx.ctx.ACCESSED = true
end


function Gateway.header_filter()

    if ngx.ctx.ACCESSED then
        local now_time = now()
        ngx.ctx.GATEWAY_WAITING_TIME = now_time - ngx.ctx.GATEWAY_ACCESS_ENDED_AT -- time spent waiting for a response from upstream
        ngx.ctx.GATEWAY_HEADER_FILTER_STARTED_AT = now_time
    end

    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:header_filter()
    end

    if ngx.ctx.ACCESSED then
        ngx.header[HEADERS.UPSTREAM_LATENCY] = ngx.ctx.GATEWAY_WAITING_TIME
        ngx.header[HEADERS.PROXY_LATENCY] = ngx.ctx.GATEWAY_PROXY_LATENCY
    end
end

function Gateway.body_filter()
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:body_filter()
    end

    if ngx.ctx.ACCESSED then
        ngx.ctx.GATEWAY_RECEIVE_TIME = now() - ngx.ctx.GATEWAY_HEADER_FILTER_STARTED_AT
    end
end

function Gateway.log()
    for _, plugin in ipairs(loaded_plugins) do
        plugin.handler:log()
    end
end

function Gateway.update()
    ngx.say("更新ok..........")
end

function Gateway.checkupstream(upstreams)
    -- # config a_upstream check
  
    local ok, err = hc.spawn_checker {
    shm = "healthcheck",
    upstream = upstreams,
    type = "http",
    http_req = "GET /health HTTP/1.0\r\nHost: "..upstreams.."\r\n\r\n",
    interval = 2000,
    timeout = 5000,
    fall = 3,
    rise = 2,
    valid_statuses = {200, 302},
    concurrency = 1,
    }

end



return Gateway
