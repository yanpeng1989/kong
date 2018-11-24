local blueprints = require "spec.fixtures.blueprints"
local helpers = require "spec.helpers"
local cjson = require "cjson"


local function api_send(method, path, body, forced_port)
  local api_client = helpers.admin_client(nil, forced_port)
  local res, err = api_client:send({
    method = method,
    path = path,
    headers = {
      ["Content-Type"] = "application/json"
    },
    body = body,
  })
  if not res then
    return nil, err
  end
  local resbody = res.status ~= 204 and res:read_body()
  api_client:close()
  if res.status == 204 then
    return nil
  elseif res.status < 300 then
    return cjson.decode(resbody)
  else
    return nil, "Error " .. tostring(res.status) .. ": " .. resbody
  end
end


local entities = {
  "snis",
  "certificates",
  "upstreams",
  "consumers",
  "targets",
  "plugins",
  "routes",
  "services",
  "jwt_secrets",
  "oauth2_credentials",
  "oauth2_tokens",
  "oauth2_authorization_codes",
  "keyauth_credentials",
  "hmacauth_credentials",
}


local admin_api_as_db = {}

for _, name in ipairs(entities) do
  admin_api_as_db[name] = {
    insert = function(_, tbl)
      return api_send("POST", "/" .. name, tbl)
    end,
    remove = function(_, tbl)
      return api_send("DELETE", "/" .. name .. "/" .. tbl.id)
    end,
  }
end


admin_api_as_db["basicauth_credentials"] = {
  insert = function(_, tbl)
    return api_send("POST", "/consumers/" .. tbl.consumer.id .. "/basic-auth", tbl)
  end,
  remove = function(_, tbl)
    return api_send("DELETE", "/consumers/" .. tbl.consumer.id .. "/basic-auth/" .. tbl.id)
  end,
}


return blueprints.new(nil, admin_api_as_db)
