-- There's a lot of Lua in ./BGAnimations/ScreenGameplay overlay
-- and a LOT of Lua in ./BGAnimations/ScreenGameplay underlay
--
-- I'm using files in overlay for logic that *does* stuff without directly drawing
-- any new actors to the screen.
--
-- I've tried to title each file helpfully and partition the logic found in each accordingly.
-- Inline comments in each should provide insight into the objective of each file.
--
-- Def.Actor will be used for each underlay file because I still need some way to listen
-- for events broadcast by the engine.
--
-- I'm using files in Gameplay's underlay for actors that get drawn to the screen.  You can
-- poke around in those to learn more.
------------------------------------------------------------

local af = Def.ActorFrame{
	OnCommand=function(self) self:playcommand("UpdateDiscordInfo") end,
	UpdateDiscordInfoCommand=function(s)
		local player = GAMESTATE:GetMasterPlayerNumber()
		if GAMESTATE:GetCurrentSong() then
			local title = PREFSMAN:GetPreference("ShowNativeLanguage") and GAMESTATE:GetCurrentSong():GetDisplayMainTitle() or GAMESTATE:GetCurrentSong():GetTranslitFullTitle()
			local songname = title .. " - " .. GAMESTATE:GetCurrentSong():GetGroupName()
			local state = GAMESTATE:IsDemonstration() and "Watching Song" or "Playing Song"
			GAMESTATE:UpdateDiscordProfile(GAMESTATE:GetPlayerDisplayName(player))
			local stats = STATSMAN:GetCurStageStats()
			if not stats then
				return
			end
			local courselength = function()
				if GAMESTATE:IsCourseMode() then
					if GAMESTATE:GetPlayMode() ~= "PlayMode_Endless" then
						return GAMESTATE:GetCurrentCourse():GetDisplayFullTitle().. " (Song ".. stats:GetPlayerStageStats( player ):GetSongsPassed()+1 .. " of ".. GAMESTATE:GetCurrentCourse():GetEstimatedNumStages() ..")" or ""
					end
					return GAMESTATE:GetCurrentCourse():GetDisplayFullTitle().. " (Song ".. stats:GetPlayerStageStats( player ):GetSongsPassed()+1 .. ")" or ""
				end
			end
			GAMESTATE:UpdateDiscordSongPlaying(GAMESTATE:IsCourseMode() and courselength() or state,songname,GAMESTATE:GetCurrentSong():GetLastSecond())
		end
	end,
	CurrentSongChangedMessageCommand=function(s) s:playcommand("UpdateDiscordInfo") end,
}

af[#af+1] = LoadActor("./WhoIsCurrentlyWinning.lua")

for player in ivalues( GAMESTATE:GetHumanPlayers() ) do

	local pn = ToEnumShortString(player)

	-- Use this opportunity to create an empty table for this player's gameplay stats for this stage.
	-- We'll store all kinds of data in this table that would normally only exist in ScreenGameplay so that
	-- it can persist into ScreenEvaluation to eventually be processed, visualized, and complained about.
	-- For example, per-column judgments, judgment offset data, highscore data, and so on.
	--
	-- Sadly, this Stages.Stats[stage_index] data structure is not documented anywhere. :(
	SL[pn].Stages.Stats[SL.Global.Stages.PlayedThisGame+1] = {}

	af[#af+1] = LoadActor("./TrackTimeSpentInGameplay.lua", player)
	af[#af+1] = LoadActor("./ReceptorArrowsPosition.lua", player)
	af[#af+1] = LoadActor("./JudgmentOffsetTracking.lua", player)

	-- FIXME: refactor PerColumnJudgmentTracking to not be inside this loop
	--        the Lua input callback logic shouldn't be duplicated for each player
	af[#af+1] = LoadActor("./PerColumnJudgmentTracking.lua", player)
end

return af
