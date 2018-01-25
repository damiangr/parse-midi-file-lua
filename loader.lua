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
	local patchChanges = {}
	local trackNames = {}

	local function insertPatchChangeEvent( event )
		for i,patchChangeEvent in ipairs(patchChanges) do
			if patchChangeEvent[2] == event[2] and patchChangeEvent[3] == event[3] and patchChangeEvent[4] == event[4] then
				return
			end
		end
		table.insert(patchChanges, event)
	end

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
					-- local eventChannel = event[3]
					-- if not patchChanges[eventChannel] then
					-- 	patchChanges[eventChannel] = {}
					-- end
					-- tableInsert( patchChanges[eventChannel], event )
					insertPatchChangeEvent(event)
				elseif event[1] == "note" then
					tableInsert( noteEvents, event )
					if not table.indexOf(trackChannels, event[4]) then
						tableInsert(trackChannels, event[4])
					end
				end
			end

			if size(trackChannels) > 0 then
				if not trackName or table.indexOf(trackNames, trackName) then
					print("track ".. i .." has noteEvents but no trackName: assign trackName to ", nameForUnnamedTrack..i)
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
	
	table.sort(patchChanges,function(a,b) 
		return a[2] < b[2]
	end)

	return {
		ppq = ppq,
		patchChanges = patchChanges,
		tracks = tracks,
		tempoEvents = getTempoEvents(score),
	}
end

return M