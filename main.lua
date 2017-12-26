
local utils = require("utils")
local loader = require("loader")
local json = require("json")

local function convertMidiFile(midi)
	local file = midi.file;
	local mainTrack = midi.mainTrack;
	local path = system.pathForFile("files/"..file, system.ResourceDirectory)
	local loadResult = loader.load(path)
	print("file " .. file .. " has " .. size(loadResult.tracks) .. " tracks")

	local converted = {}
	converted.header = {
		PPQ = loadResult.ppq
	}
	converted.tracks = {}

	local tempo = loadResult.tempoEvents[1][3]
	local function tickToSecond( ticks )
		return ticks*tempo/(1000*1000*loadResult.ppq)
	end

	local trackCount = 0
	for trackName,trackData in pairs(loadResult.tracks) do
		local track = {notes = {}}
		if (trackCount == mainTrack) then
			print("mainTrack name = ", trackName)
			table.insert(converted.tracks, 1, track)
		else
			table.insert(converted.tracks, track)
		end
		trackCount = trackCount + 1
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

for i,midi in ipairs(require("MidiFiles")) do
	print("\nconvert file: ", midi.file)
	convertMidiFile(midi)
end