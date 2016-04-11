-- difficulty.lua

local http = require("socket.http")

print('starting')

body, statusCode, headers, statusLine = http.request(
"http://www.thebluealliance.com/event/2014gal")

if not body then
   print('no body')
   return
end

if not body:find( 'Quals ' ) then
   print( 'No Quals' )
end

local redalliances = {}
local bluealliances = {}
local redscores = {}
local bluescores = {}

--file = io.open( 'matches.txt', 'w' )
local prevqn = 0
for qn, more in body:gmatch('Quals (%d+)([^Q]+)') do
   if qn ~= prevqn then
      local qualifier = tonumber(qn)
	  if qualifier == nil then
		continue
	  end
      local pos = 1

      local alliance = {}
      for i = 1,3 do
         pos = more:find('/team/', pos)
         if pos then pos = pos + 6 end
         local team = more:match('(%d+)', pos)
         if pos then pos = pos + #team end
         alliance[#alliance+1] = team
      end
      redalliances[qualifier] = alliance

      alliance = {}
      for i = 1,3 do
         pos = more:find('/team/', pos)
         if pos then pos = pos + 6 end
         local team = more:match('(%d+)', pos)
         if pos then pos = pos + #team end
         alliance[#alliance+1] = team
      end
      bluealliances[qualifier] = alliance

      pos = more:find('Score', pos)
      local score = more:match('%D+>(%d+)<', pos)
      if score then
         pos = pos + #score
         redscores[qualifier] = score
      end

      pos = more:find('Score', pos)
      local score = more:match('%D+>(%d+)<', pos)
      if score then
         pos = pos + #score
         bluescores[qualifier] = score
      end
	  
	  --[[
	  file = io.stdout
      file:write( qn, ' ',
      redalliances[qn][1], ' ', redalliances[qn][2], ' ', redalliances[qn][3], ' ' )
      if redscores[qn] then
         file:write( redscores[qn] )
      end
      file:write( bluealliances[qn][1], ' ', bluealliances[qn][2], ' ', bluealliances[qn][3], ' ' )
      if bluescores[qn] then
         file:write( bluescores[qn] )
      end
      file:write( '\n' )
	  ]]
   end
   prevqn = qn
end

--io.close(file)
print('done with match query')

f = io.open("oprs.txt", 'r')
local oprstring = f:read("*all")
pat = "(%d+)%s+([%-%d%.]+)%s+"
local oprs = {}
local orderedteams = {}
local totalopr = 0
for team, opr in string.gmatch(oprstring, pat) do
   local oprnum = tonumber(opr)
   oprs[ team ] = oprnum
   orderedteams[#orderedteams+1] = team
   totalopr = totalopr + oprnum
end
print( 'avg opr: ' .. totalopr / #orderedteams )
f:close()

psums = {}
osums = {}
pcounts = {}
ocounts = {}

for _, team in ipairs(orderedteams) do
   psums[team] = 0
   osums[team] = 0
   pcounts[team] = 0
   ocounts[team] = 0
end

for qn, _ in ipairs(redalliances) do
   for i = 1,3 do
      local team = redalliances[qn][i]
      for j = 1,3 do
         if redalliances[qn][j] ~= team then
            psums[team] = psums[team] + oprs[ redalliances[qn][j] ]
            pcounts[team] = pcounts[team] + 1
         end
      end
      for j = 1,3 do
         osums[team] = osums[team] + oprs[ bluealliances[qn][j] ]
         ocounts[team] = ocounts[team] + 1
      end

      team = bluealliances[qn][i]
      for j = 1,3 do
         osums[team] = osums[team] + oprs[ redalliances[qn][j] ]
         ocounts[team] = ocounts[team] + 1
      end
      for j = 1,3 do
         if bluealliances[qn][j] ~= team then
            psums[team] = psums[team] + oprs[ bluealliances[qn][j] ]
            pcounts[team] = pcounts[team] + 1
         end
      end
   end
end

function round( num, modulus )
   return math.floor( num / modulus ) * modulus
end

print( '\nTeam', 'Partner', 'Oppos', 'Difficulty' )
for _, team in ipairs(orderedteams) do
   local partner = psums[team] / pcounts[team]
   local oppos = osums[team] / ocounts[team]
   local difficulty = oppos - partner
   print( team,
   round( partner, .01 ),
   round( oppos, .01 ),
   round( difficulty, .01 ) )
end
