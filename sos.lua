local http = require("socket.http")
local json = require('cjson')

event = arg[1]
print(arg[1])
if not event then
	event = "2016pncmp"
	--event = "2016orore"
	--event = "2016orwil"
end

strMatches, statusCode, headers, statusLine = http.request("http://www.thebluealliance.com/api/v2/event/" .. event .. "/matches?X-TBA-App-Id=frc2471:strengthOfScheduls:v01")
if not strMatches then
   print('no matches')
   return
end
local matches = json.decode(strMatches)

strStats, statusCode, headers, statusLine = http.request("http://www.thebluealliance.com/api/v2/event/" .. event .. "/stats?X-TBA-App-Id=frc2471:strengthOfScheduls:v01")
if not strStats then
   print('no stats')
   return
end
local stats = json.decode(strStats)

psums = {}
osums = {}
pcounts = {}
ocounts = {}
totalopr = 0
oprcount = 0

for team, opr in pairs(stats["oprs"]) do
	--print( team, opr )
	totalopr = totalopr + opr
	oprcount = oprcount + 1

	-- partners and opponents accumulators
	psums[team] = 0
	osums[team] = 0
	pcounts[team] = 0
	ocounts[team] = 0
end

function round( num, modulus )
   return math.floor( num / modulus ) * modulus
end

print( 'avg-opr: ' .. round( totalopr / oprcount, .01) )

for _, match in ipairs(matches) do
	if match["comp_level"] == "qm" then
		for i = 1,3 do
	    	local team = match["alliances"]["red"]["teams"][i]:sub(4)
	    	for j = 1,3 do
		        if match["alliances"]["red"]["teams"][j]:sub(4) ~= team then
		            psums[team] = psums[team] + stats["oprs"][ match["alliances"]["red"]["teams"][j]:sub(4) ]
		            pcounts[team] = pcounts[team] + 1
		        end
		    end
		    for j = 1,3 do
		        osums[team] = osums[team] + stats["oprs"][ match["alliances"]["blue"]["teams"][j]:sub(4) ]
		        ocounts[team] = ocounts[team] + 1
		    end

		    team = match["alliances"]["blue"]["teams"][i]:sub(4)
		    for j = 1,3 do
		         osums[team] = osums[team] + stats["oprs"][ match["alliances"]["red"]["teams"][j]:sub(4) ]
		         ocounts[team] = ocounts[team] + 1
		    end
		    for j = 1,3 do
		    	if match["alliances"]["blue"]["teams"][j]:sub(4) ~= team then
		        	psums[team] = psums[team] + stats["oprs"][ match["alliances"]["blue"]["teams"][j]:sub(4) ]
		            pcounts[team] = pcounts[team] + 1
		        end
		    end
		end
	end
end

sos = {}

for team, opr in pairs(stats["oprs"]) do
	local member = {}
	--print( team, pcounts[team], ocounts[team] )
	member.team = team
	member.partner = psums[team] / pcounts[team]
   	member.opposition = osums[team] / ocounts[team]
   	member.difficulty = member.opposition - member.partner
   	member.opr = opr
   	table.insert(sos, member)
end

table.sort( sos, function(a,b) return a.difficulty>b.difficulty end )

print( '\nTeam', 'Partner', 'Oppos', 'Diff', 'OPR' )
for index, member in ipairs(sos) do
   print( member.team,
    round( member.partner, .01 ),
    round( member.opposition, .01 ),
    round( member.difficulty, .01 ),
    round( member.opr, .01 ) )
end
