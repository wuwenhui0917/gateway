local ipairs = ipairs
local type = type
local encode_base64 = ngx.encode_base64
local string_format = string.format
local string_gsub = string.gsub
local tabel_insert = table.insert

local utils = require("gateway.utils.utils")
local gateway_db = require("gateway.store.gateway_db")
local judge_util = require("gateway.utils.judge")
local handle_util = require("gateway.utils.handle")
local BasePlugin = require("gateway.plugins.base_handler")
local extractor_util = require("gateway.utils.extractor")
local json = require("gateway.utils.json")


local SignatureBodyHandler = BasePlugin:extend()
SignatureBodyHandler.PRIORITY = 2000

function SignatureBodyHandler:new(store)
    SignatureBodyHandler.super.new(self, "sig_body")
    self.store = store
end

local function res_json()
    local res = {}
    res["message"] = "你希望输出的内容"
    res["code"] = "你希望输出的内容"
    return json.encode(res)
end

function SignatureBodyHandler:header_filter()

    ngx.log(ngx.ERR, "[ SignatureBodyHandler->header_filter ]  ")


    local  tempbody = res_json()
    ngx.header["Content-Length"] = #tempbody
end   

function SignatureBodyHandler:body_filter()
    local chunk, eof = ngx.arg[1], ngx.arg[2]  -- 获取当前的流 和是否时结束
    local  tempbody = res_json()
    ngx.log(ngx.ERR, "[ tempbody ] " .. chunk.." size===="..#tempbody)

    -- ngx.header["Content-Length"] = #tempbody
    ngx.arg[1] = tempbody

    -- local info = ngx.ctx.buf
    -- chunk = chunk or ""
    -- local  tempbody = res_json()
    -- ngx.log(ngx.ERR, "[ tempbody ] " .. chunk)
    -- if info then
    --     ngx.ctx.buf = info .. chunk -- 这个可以将原本的内容记录下来
    -- else
    --     ngx.ctx.buf = chunk
    -- end
    -- if eof then
    --     ngx.ctx.buffered = nil
    --     ngx.header["Content-Length"] = 1000
    --     ngx.arg[1] = tempbody

    --     -- if status == 413 or status == "413" then  -- 413是nginx request body 超过限制时的状态吗
    --     --     ngx.header["Content-Length"] = 100
    --     --     ngx.arg[1] =tempbody -- 这个是你期待输出的内容
    --     --     -- ngx.header["Content-Length"]=string.len(tempbody)
    --     --     -- ngx.header["Content-Length"] = #tempbody
    --     -- else
    --     --     ngx.log(ngx.ERR, "[ Internal Exception ] " .. ngx.ctx.buf)
    --     --     ngx.header["Content-Length"] = 1000
    --     --     ngx.arg[1] = tempbody
    --     --     -- ngx.say(tempbody)
           

    --     -- end
    -- else
    --     -- ngx.header["Content-Length"] = #tempbody
    --     -- ngx.arg[1] = nil -- 这里是为了将原本的输出不显示
        
    -- end
    -- -- ngx.header.content_length = 10


end


   

return SignatureBodyHandler
