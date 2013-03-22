--- Lua Hue API
--
-- Copyright Pete Kazmier 2013

local M = {}

local json = require 'json'
local http = require 'socket.http'
local ltn12 = require 'ltn12'
local tablex = require 'pl.tablex'
local stringx = require 'pl.stringx'


--- Discovers any local Hue bridges on the network
-- @return a list of IP addresses
function M.discover()
   local r = M.json_request('http://www.meethue.com/api/nupnp')
   if r then 
      return tablex.imap(function(b) return b.internalipaddress end, r)
   end
end

-- Bridge object definition

M.Bridge = {}

--- Creates a new bridge object. Upon creation, the bridge is queried
-- for the valid lights that are registered to it.  
-- @param host the IP address of the bridge
-- @param username the username to authenticate with
-- @param o optional table containing initial state
-- @return instantiated Bridge object
function M.Bridge:new(host, username, o)
   assert(host,'hostname is nil')
   assert(username,'username is nil') 

   o = o or {}
   o.host = host
   o.username = username
   setmetatable(o, self)
   self.__index = self

   if not o:lights() then
      return nil
   else
      return o
   end
end

function M.Bridge:register(username, devicetype)
   assert(username,'username is nil')
   assert(devicetype,'devicetype is nil')
end

--- Returns the list of lights registered with the bridge.
-- @param no_cache if true, do not return previously cached results
-- @return array of lights
function M.Bridge:lights(no_cache)
   if not no_cache and self.ids then
      return self.ids,self.names
   end

   local r = self:request('/lights')
   if not r then 
      return nil
   end

   self.ids,self.names = {}, {}
   for k,v in pairs(r) do
      self.ids[k] = v.name
      self.names[v.name] = k
   end
   return self.ids,self.names
end

--- Returns the id of the specified light
-- @param light a string representing the id or name assigned to a light
-- @return the id as a string or nil if the light does not exist
function M.Bridge:lookup_id(light)
   return self.ids[light] and light or self.names[light]
end

--- Sets the state of the specified lights. State is specified as a table
-- of items specified from http://developers.meethue.com/1_lightsapi.html.
-- @param lights a list of lights specified by id or name
-- @param state a table containing the desired state
-- @return a table showing success or error for each attribute set
function M.Bridge:set_state(lights, state)
   resources,invalid = self:resource_uris(lights, '/state', '/action')
   local results = {}
   for light,uri in pairs(resources) do 
      results[light] = self:request(uri,'PUT',state)
   end
   return results
end

--- Gets the state of the specified lights. State is specified as a table
-- of items specified from http://developers.meethue.com/1_lightsapi.html.
-- @param lights a list of lights specified by id or name
-- @param path dotted string path of attribute to get
-- @return a table showing status of specified resources
function M.Bridge:get_state(lights, path)
   resources,invalid = self:resource_uris(lights)
   local results = {}
   for light,uri in pairs(resources) do 
      results[light] = M.table_path(self:request(uri), path)
   end
   return results
end

function M.Bridge:resource_uris(lights, light_suffix, group_suffix)
   light_suffix = light_suffix or ''
   group_suffix = group_suffix or ''

   if #lights == 0 then 
      return {'/groups/0'..group_suffix}, {}
   end

   local resources,invalid = {},{}
   for _,l in ipairs(lights) do
      local id = self:lookup_id(l)
      if id then 
         resources[l]='/lights/'..id..light_suffix
      else
         invalid[#invalid+1]=l
      end
   end
   return resources,invalid
end

function M.Bridge:request(resource, method, body)
   resource = resource or '/'

   local url = 'http://'..self.host..'/api/'..self.username..resource

   return M.json_request(url, method, body)
end

-- Utility functions

function M.table_path(t, path)
   if not path then return t end
   for _,p in ipairs(stringx.split(path,'.')) do
      if t[p] then 
         t = t[p]
      else
         return t
      end
   end
   return t
end

function M.json_request(url, method, body)
   assert(url)
   method = method or 'GET'

   if body then
      body = json.encode(body)
   end

   local results = {}
   local _, code = http.request {
      url = url,
      method = method,
      headers = { ['content-type']='application/json', 
                  ['content-length']=body and #body or 0},
      source = ltn12.source.string(body),
      sink = ltn12.sink.table(results),
   }

   if string.sub(code,1,2) ~= "20" then
      return nil, code
   end

   results = table.concat(results)
   return json.decode(results), code
end


-- End of module

return M
