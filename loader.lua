local M = {}

local midi = require "midi"

local tableInsert = table.insert

local nameForUnnamedTrack = "anonyme_"

local function getTempoEvents(opus)
	local tempoEvents = {}
	local tempoEventsByTicks = {}
	for i,track in ipairs(opus) do
		if type(track) == "table" then
			for j,event in ipairs(track) do
				if event[1] == "set_tempo" then 
					tempoEventsByTicks[tostring(event[2])] = event
				end
			end
		end
	end

	for k,tempo in pairs(tempoEventsByTicks) do
		tableInsert( tempoEvents, tempo )
	end

	table.sort( tempoEvents, function (a,b)
		return a[2] < b[2]
	end )

	return tempoEvents
end

function M.load(path)
	local file = io.open( path,"rb" )
	if not file then
		return print("File corrupted or path incorrect")
	end
	local fileContent = file:read("*a")
	file:close()

	local opus = midi.midi2opus(fileContent)
	if opus == nil then
		return print("Cannot convert midi to opus!")
	elseif #opus < 3  then 
		return print("No track")
	end
	local score = midi.opus2score(opus)

	local ppq
	local tracks = {}
	local patchChangesByChannel = {}
	local trackNames = {}

	for i,track in ipairs(score) do
		print("Begin parse track number " .. i)
		if type(track) == "table" then
			local trackName
			local noteEvents = {}
			local trackChannels = {}
			for j,event in ipairs(track) do
				if event[1] == "track_name" and not trackName then 
					trackName = event[3]
					print("trackName = ", trackName)
				elseif event[1] == "patch_change" then
					local eventChannel = event[3]
					if not patchChangesByChannel[eventChannel] then
						patchChangesByChannel[eventChannel] = {}
					end
					tableInsert( patchChangesByChannel[eventChannel], event )
				elseif event[1] == "note" then
					tableInsert( noteEvents, event )
					if not table.indexOf(trackChannels, event[4]) then
						tableInsert(trackChannels, event[4])
					end
				end
			end

			if size(trackChannels) > 0 then
				if not trackName or table.indexOf(trackNames, trackName) then
					print("track has noteEvents but no trackName: assign trackName to ", nameForUnnamedTrack..i)
					trackName = nameForUnnamedTrack..i
				end
				tableInsert(trackNames, trackName)

				tracks[trackName] = {
					noteEvents = noteEvents,
					trackChannels = trackChannels,
				}
				table.sort(noteEvents,function(a,b)
					return a[2] < b[2]
				end)
			end
		elseif type(track) == "number" then
			ppq = track
		end
	end

	if size(tracks) == 0 then
		return print("File has no note event")
	end
	
	for channel,patchChangeEvents in pairs(patchChangesByChannel) do
		table.sort(patchChangeEvents,function(a,b) 
			return a[2] < b[2]
		end)
	end

	return {
		ppq = ppq,
		patchChangesByChannel = patchChangesByChannel,
		tracks = tracks,
		tempoEvents = getTempoEvents(score),
	}
end

return M