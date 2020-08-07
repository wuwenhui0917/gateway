local ipairs = ipairs
local type = type
local tostring = tostring
local table_insert = table.insert
local json = require("gateway.utils.json")
local gateway_db = require("gateway.store.gateway_db")
local utils = require("gateway.utils.utils")
local stringy = require("gateway.utils.stringy")
local dao = require("gateway.store.dao")


local BaseAPI = require("gateway.plugins.base_api")
local common_api = require("gateway.plugins.common_api")

local api = BaseAPI:new("key-auth-api", 2)
api:merge_apis(common_api("key_auth"))


local key_authapi = {}


key_authapi["/key_auth/addRule"]={

       GET=function(store)
           return function(req,res,next)
               res:json({
                    success = false,
                    msg = "okkkkk",
                }) 
             
		         
                  
           end
       end


}



api:merge_apis(key_authapi)



return api
