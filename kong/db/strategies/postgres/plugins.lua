local null = ngx.null
local concat = table.concat
local insert = table.insert


local Plugins = {}


function Plugins:select_by_ids(name, route_id, service_id, consumer_id, api_id)
  local connector = self.connector

  local exp = {}
  if name ~= nil and name ~= null then
    insert(exp, "name = " .. connector:escape_literal(name))
  end
  if route_id ~= nil and route_id ~= null then
    insert(exp, "route_id = " .. connector:escape_literal(route_id))
  end
  if service_id ~= nil and service_id ~= null then
    insert(exp, "service_id = " .. connector:escape_literal(service_id))
  end
  if consumer_id ~= nil and consumer_id ~= null then
    insert(exp, "consumer_id = " .. connector:escape_literal(consumer_id))
  end
  if api_id ~= nil and api_id ~= null then
    insert(exp, "api_id = " .. connector:escape_literal(api_id))
  end


  local select_q = "SELECT id, name, " ..
                   "EXTRACT(EPOCH FROM created_at AT TIME ZONE 'UTC') " ..
                   "AS created_at, api_id, route_id, service_id, " ..
                   "consumer_id, config, enabled FROM plugins WHERE " ..
                   concat(exp, " AND ") .. ";"

  local res, err = connector:query(select_q)
  if not res then
    return connector:toerror(self, err)
  end

  for i, row in ipairs(res) do
    res[i] = self.expand(row)
  end

  return res
end


return Plugins
