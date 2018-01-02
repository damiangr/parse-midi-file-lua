
local utils = require("utils")
local loader = require("loader")
local json = require("json")

local function convertMidiFile(midi)
	local file = midi.file;
	local mainTrack = midi.mainTrack;
	print("\nconvert midi file: ", file)
	local path = system.pathForFile("files/"..file, system.ResourceDirectory)
	local loadResult = loader.load(path)
	print("\nfile " .. file .. " has " .. size(loadResult.tracks) .. " tracks")

	---[[
	local trackPoints = loadResult.tracks["trackpoints"]
	local checkPointTimes = {}
	if trackPoints then
		for i,checkPoint in ipairs(trackPoints.noteEvents) do
			table.insert(checkPointTimes, checkPoint[2])
		end
	end

	local trackCount = 0
	local mainTrackNotes = {}
	local mainTrackName
	local checkPoints = {}
	for trackName,trackData in pairs(loadResult.tracks) do
		if trackCount == mainTrack then
			mainTrackName = trackName
			print("mainTrack name = ", trackName)
			for i,note in ipairs(trackData.noteEvents) do
				mainTrackNotes[note[2]] = note
				if (checkPointTimes[1] and checkPointTimes[1] < note[2]) then
					table.insert( checkPoints, i - 2 )
					table.remove( checkPointTimes, 1 )
				end
			end
			break
		end
		trackCount = trackCount + 1
	end

	local function isDuplicate( note )
		local mainNote = mainTrackNotes[note[2]]
		return mainNote and mainNote[5] == note[5] and mainNote[6] == note[6]
	end

	for trackName,trackData in pairs(loadResult.tracks) do
		if (trackName ~= mainTrackName) then
			local duplicateCount = 0
			print("check duplicate: trackName = " .. trackName .. ", numNote = " .. #trackData.noteEvents)
			for i=#trackData.noteEvents,1,-1 do
				local note = trackData.noteEvents[i]
				if isDuplicate(note) then
					duplicateCount = duplicateCount + 1
					table.remove( trackData.noteEvents, i )
				end
			end
			print("duplicate notes = " .. duplicateCount ..", remaining note in track = " .. #trackData.noteEvents)
		end
	end
	--]]

	local converted = {}
	converted.header = {
		PPQ = loadResult.ppq
	}
	converted.tracks = {}

	local tempo = loadResult.tempoEvents[1][3]
	local function tickToSecond( ticks )
		return ticks*tempo/(1000*1000*loadResult.ppq)
	end

	for trackName,trackData in pairs(loadResult.tracks) do
		local track = {notes = {}}
		if (trackName == mainTrackName) then
			table.insert(converted.tracks, 1, track)
			track.checkPoints = checkPoints
			if (#checkPoints == 2) then
				print("add third checkPoint to mainTrack at index " .. (#trackData.noteEvents - 1))
				checkPoints[3] = #trackData.noteEvents - 1
			elseif (#checkPoints == 0) then
				print("add 3 checkPoints to mainTrack")
				checkPoints[1] = math.floor(#trackData.noteEvents / 3)
				checkPoints[2] = math.floor(2 * #trackData.noteEvents / 3)
				checkPoints[3] = #trackData.noteEvents - 1
			end
			print("mainTrack checkPoint = ")
			printTable(checkPoints)
		else
			table.insert(converted.tracks, track)
		end
		for i,note in ipairs(trackData.noteEvents) do
			table.insert( track.notes, {
				midi = note[5],
				time = tickToSecond(note[2]),
				duration = tickToSecond(note[3]),
			} )
		end
	end

	utils.ensureFolderExists("converted")
	local path = system.pathForFile("converted/"..string.gsub( file, "mid", "txt" ), system.DocumentsDirectory )
	local file = io.open(path,"wb+")
	file:write(json.encode(converted))
	io.close(file)
end

--[[
for i,midi in ipairs(require("MidiFiles")) do
	convertMidiFile(midi)
end
--]]

convertMidiFile({file = "Scaborough.mid", mainTrack = 1})