-- redis store: will store plgin info into redis.
-- author:wuwh(wuwh6@asiainfo.com)
local type = type
local Store = require("gateway.store.base")
-- local redis = require "resty.redis"
local redis_cluster = require "resty.rediscluster"
local redis = require "resty.redis"

local stringy = require ("gateway.utils.stringy")
local table_insert = table.insert
local table_concat = table.concat
local RedisStore = Store:extend()
local json = require("gateway.utils.json")

config = {
    name = "gateway-adapter",
    serv_list = {
        
       {ip="127.0.0.1", port = 30201},
       {ip="127.0.0.1", port = 30202},
       {ip="127.0.0.1", port = 30203},
       {ip="127.0.0.1", port = 30204},
       {ip="127.0.0.1", port = 30205},
       {ip="127.0.0.1", port = 30206}
    },
    
}

config2 = {
    name = "test",
    serv_list = {
        {ip="127.0.0.1", port = 30201},
        {ip="127.0.0.1", port = 30202},
        {ip="127.0.0.1", port = 30203},
        {ip="127.0.0.1", port = 30204},
        {ip="127.0.0.1", port = 30205},
        {ip="127.0.0.1", port = 30206},
    },
}
function RedisStore:new(options)

    local serv_list = {
        
        -- {ip="127.0.0.1", port = 30206},
    };
    self._name = options.name or "redis-store"
    RedisStore.super.new(self, self._name)
    self.store_type = "redis"
    local serverlist = options.serv_list
    ngx.log(ngx.INFO,"serverlist"..serverlist);
    if serv_list then
        for _dex,server in ipairs(stringy.split(serverlist,",")) do
            local server = stringy.split(server,":")
            ngx.log(ngx.INFO,"serverlist"..server[1].." port "..server[2]);
            local jsonparam = {};
            jsonparam.ip = server[1];
            jsonparam.port = 30206;
            -- server['ip']=server[1];
            -- server['port']=server[2];
            -- table_insert(serv_list,server);
            serv_list[_dex]=jsonparam;

        end    
    end    

    -- self.redisconfig = {};
    -- self.redisconfig.name="gateway-redis";
    -- self.redisconfig.serv_list = serv_list;
    self.redisconfig=config2;
    -- self.redisconfige = config;
    ngx.log(ngx.INFO,"redis..........."..json.encode(self.redisconfig));

    

    -- ngx.log(ngx.INFO,"okkkkkkkkkkkkddddddd"..connect_config);
    -- self.host=connect_config.host
    -- self.port = connect_config.port
    -- self.connection_address = connect_config.host .. ":" .. connect_config.port
    -- ngx.log(ngx.INFO,"okkkkkkkkkkkkddddddd"..self.connection_address);
    self.redis=nil;
    
    -- local tcp = ngx.socket.tcp
    -- local socket = tcp();
    -- ngx.log(ngx.INFO,"socket..........."..self.connection_address);


    -- local redis1 = require "resty.redis";
    -- local red = redis1:new();
    -- red:set_timeout(100000);
    -- local ok, err  =red:connect("wuwenhui", 10201);

    -- if not ok then    -- 链接失败的时候
    --     ngx.log(ngx.DEBUG, "error:" .. err);
    -- else
    --     red:set("1","2");
    -- end
    -- ngx.log(ngx.INFO,"new  init  end"..self.connection_address);





    -- self.redis = redis_cluster:new(config);
    -- self.redis:init_pipeline()
    -- self.redis:set("k1", "hello");
    -- self.redis.close();
    -- local res = self.redis:commit_pipeline();
    -- local cjson = require "cjson"
    -- ngx.log(ngx.INFO,cjson.encode(res));
    -- self.redis:close()


    

end


function RedisStore:getRedis()
    local red = redis:new()  --创建一个对象，注意是用冒号调用的
    --设置超时（毫秒）  
    red:set_timeout(10000)
    --建立连接  
    local ip = "127.0.0.1"  
    local port = 10201
    local ok, err = red:connect(ip, port)
    ngx.log(ngx.INFO,"redis  connection  ok");
    if ok  then
        return red
    else
        return nil
    end        


end    

function RedisStore:init()
   
        ngx.log(ngx.INFO,'ddddddddddddddddddd'..json.encode(config));
        self.redis = RedisStore:getRedis();
        -- local redis1 = redis_cluster:new(config);
        -- ngx.log(ngx.INFO,"redis..........."..json.encode(redis1.config));
        -- redis1.set("123","1222");
         
  


end    

function RedisStore:query(opts)


    if not opts or opts == "" then return nil end
    local param_type = type(opts)
    local key;
    if param_type == "string" then
        key = opts
    elseif param_type == "table" then
        key = opts.key
    end

    -- ngx.log(ngx.INFO,"redis  11111111111111111111"..key);
    -- -- RedisStore:int();
    -- ngx.log(ngx.INFO,'ddddddddddddddddddd'..json.encode(config));
    -- local redis=redis_cluster:new(config);
    local red = RedisStore:getRedis();
    ngx.log(ngx.INFO,"redis  11111111111111111111"..key);
    -- ngx.log(ngx.INFO,"redis  value===="..json.encode(red.get(key)));
    
    if  red  then
        local ok,error = red:get(key)
        if ok then
            ngx.log(ngx.INFO,"redis"..key.."value="..json.encode(ok));
            return ok
        end    
 
    end    
   
    -- if redis  then
        
    --     -- ngx.log(ngx.INFO,"redis  get..........."..redis.get(key));

    
    --       redis.set(key,"1");
    -- end   
    
    return 0;

   
  
end

function RedisStore:insert(opts)
   
end

function RedisStore:delete(opts)
    
end

function RedisStore:update(opts)
    
end

function RedisStore:getHashInfo(plugin,key)
    if not plugin or plugin == "" then return nil end
    if not key or key == "" then return nil end
    local hashtalename = plugin.."_plugin"
    ngx.log(ngx.INFO,"---------------------------getHashInfo------------------------"..hashtalename.." key"..key);
    local red=self.redis
    if  red  then
        ngx.log(ngx.INFO,"---------------------------getHashInforedis------------------------");

        local ok,err= red:hget(hashtalename,key)
        if ok then
           -- ngx.log(ngx.INFO,"---------------------------getHashInfo------------------------"..json.decode(ok));
            -- return json.decode(ok)
            return ok
        end
    else 
        ngx.log(ngx.INFO,"---------------------------redis------------------------ error");
   
    end 
    ngx.log(ngx.INFO,"---------------------------getHashInfo------------------------ error"..hashtalename.." key"..key);

    return nil   
end

function RedisStore:getMHashInfo(plugin,keys)
    ngx.log(ngx.INFO,"getHashByKeyTag");
   

    if not plugin or plugin == "" then return nil end
    if not keys or keys == "" then return nil end
    local hashtalename=plugin.."_plugin";
    local red=self.redis
    if  red  then
        local ok,error= red:hmget(hashtalename,keys)
        if ok then
           ngx.log(ngx.INFO,"%%%%%%%%%%%%%%%%%%getMHashInfo"..hashtalename..":value=="..json.encode(ok));
          return ok
        else 
            ngx.log(ngx.ERR,"%%%%%%%%%%%%%%%%%%getMHashInfo"..hashtalename..":value==",error);
   
        end  

    end 
    return nil   
end

--获取redis中的key开头的配置
function RedisStore:getHashByKeyTag(plugin,keystag)
    ngx.log(ngx.INFO,"%%%%%%%%%%%%%%%%%%getHashByKeyTag"..plugin.." keystag"..keystag);
   
    if not plugin or plugin == "" then return nil end
    if not keystag or keystag == "" then return nil end
    local hashtalename = plugin.."_plugin"
    local red=self.redis
    local param={};
    if  red  then
        local values= red:hgetall(hashtalename)
        for _, s in ipairs(values) do
            if stringy.startswith(s,keystag) then
                -- table_insert(param,RedisStore:getHashInfo(plugin,s));
                local info = self:getHashInfo(plugin,s);
                if info then
                    table_insert(param,json.decode(info));
                end
            end    
            
        end
        
        return param;
    end 
    return nil;
end    

return RedisStore
