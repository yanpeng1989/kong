local cassandra = require "cassandra"


local fmt = string.format
local null = ngx.null
local concat = table.concat
local insert = table.insert


local Plugins = {}


function Plugins:select_by_ids(name, route_id, service_id, consumer_id, api_id)
  local connector = self.connector
  local cluster = connector.cluster
  local errors = self.errors

  local res   = {}
  local count = 0

  local exp = {}
  local args = {}
  if name ~= nil and name ~= null then
    insert(exp, "name = ?")
    insert(args, cassandra.text(name))
  end
  if route_id ~= nil and route_id ~= null then
    insert(exp, "route_id = ?")
    insert(args, cassandra.uuid(route_id))
  end
  if service_id ~= nil and service_id ~= null then
    insert(exp, "service_id = ?")
    insert(args, cassandra.uuid(service_id))
  end
  if consumer_id ~= nil and consumer_id ~= null then
    insert(exp, "consumer_id = ?")
    insert(args, cassandra.uuid(consumer_id))
  end
  if api_id ~= nil and api_id ~= null then
    insert(exp, "api_id = ?")
    insert(args, cassandra.uuid(api_id))
  end

  local select_q = "SELECT id, name, created_at, " ..
                   "api_id, route_id, service_id, " ..
                   "consumer_id, config, enabled FROM plugins WHERE " ..
                   concat(exp, " AND ") ..
                   " ALLOW FILTERING"
print(">>> NEW CQL: ITERATE WITH {", select_q, "} ON ", require'inspect'(args))
  for rows, err in cluster:iterate(select_q, args) do
    if err then
      return nil,
             errors:database_error(fmt("could not fetch plugins: %s", err))
    end

    for i = 1, #rows do
      count = count + 1
      res[count] = rows[i]
    end
  end

  for i, row in ipairs(res) do
    res[i] = self:deserialize_row(row)
  end

  return res
end


return Plugins
