local M = {}

local MIDI = require "midi"

local indexOf = table.indexOf
local tableInsert = table.insert
local tableSize = function( t )
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end
	return count
end

local TRACK_NO_NAME_TAG = "r_no_name_"
local melodyTrackName = "melody"


local function find( s, pattern )
	return string.find( s, pattern, 1, true )
end

local function getTempoEvents(opus)
	local t = system.getTimer( )
	local tempo_events = {}
	local tempo_events_by_ticks = {}
	for i,track in ipairs(opus) do
		if type(track) == "table" then
			for j,event in ipairs(track) do
				if event[1] == "set_tempo" then 
					tempo_events_by_ticks[tostring(event[2])] = event
				end
			end
		end
	end

	for k,tempo in pairs(tempo_events_by_ticks) do
		tableInsert( tempo_events, tempo )
	end

	table.sort( tempo_events, function (a,b)
		return a[2] < b[2]
	end )
	-- printTable(tempo_events)
	print( ">>> getTempoEvents completed in:"..tostring(system.getTimer() - t))
	-- if true then 
	-- 	tempo_events = {
	-- 		{
	-- 			"set_tempo",
	-- 			2303,
	-- 			3000000
	-- 		}
	-- 	}
	-- end
	return tempo_events
end

function M.load(path)
	local file = io.open( path,"rb" )
	if not file then
		return print("File corrupted or path incorrect")
	end
	local fileContent = file:read("*a")
	file:close()

	local opus = MIDI.midi2opus(fileContent)
	if opus == nil then
		return print("Cannot convert MIDI to opus!")
	elseif #opus < 3  then 
		return print("No track")
	end
	local score = MIDI.opus2score(opus)

	local tickPerBeat
	local tracksContainNoteEvent = {}
	local patchChangesByChannel = {}
	local registeredTrackName = {}

	for i,track in ipairs(score) do
		print("\nBegin parse track number " .. i)
		if type(track) == "table" then
			local trackName
			local noteEvents = {}
			local trackChannels = {}
			for j,event in ipairs(track) do
				if event[1] == "track_name" and not trackName then 
					trackName = event[3]
					print("trackName = ", trackName)
					-- eventTracks[trackName] = track
				elseif event[1] == "patch_change" then
					local eventChannel = event[3]
					if not patchChangesByChannel[eventChannel] then
						patchChangesByChannel[eventChannel] = {}
					end
					tableInsert( patchChangesByChannel[eventChannel], event )
				elseif event[1] == "note" then
					tableInsert( noteEvents, event )
					if not indexOf(trackChannels, event[4]) then
						print("channel = ", event[4])
						tableInsert(trackChannels, event[4])
					end
				end
			end

			if tableSize(trackChannels) > 0 then
				if not trackName or indexOf(registeredTrackName, trackName) then
					print("track has noteEvents but no trackName: assign trackName to ", TRACK_NO_NAME_TAG..i)
					trackName = TRACK_NO_NAME_TAG..i
				end
				tableInsert(registeredTrackName, trackName)

				tracksContainNoteEvent[trackName] = {
					noteEvents = noteEvents,
					trackChannels = trackChannels,
				}
				table.sort(noteEvents,function(a,b)
					return a[2] < b[2]
				end)
			end
		elseif type(track) == "number" then
			tickPerBeat = track
		end
	end
	print("")

	if tableSize(tracksContainNoteEvent) == 0 then
		return print("File has no note event")
	end
	
	-- sort patchChangesByChannel
	for channel,patchChangeEvents in pairs(patchChangesByChannel) do
		table.sort(patchChangeEvents,function(a,b) 
			return a[2] < b[2]
		end)
	end

	return {
		tickPerBeat = tickPerBeat,
		patchChangesByChannel = patchChangesByChannel,
		tracksContainNoteEvent = tracksContainNoteEvent,
		tempo = getTempoEvents(score),
	}
end

return M