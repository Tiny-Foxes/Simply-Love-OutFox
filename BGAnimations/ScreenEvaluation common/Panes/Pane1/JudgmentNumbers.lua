local player, side = unpack(...)

local pn = ToEnumShortString(player)
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

local Name, Length = LoadModule("Options.SmartTapNoteScore.lua")()
local CurPrefTiming = LoadModule("Config.Load.lua")("SmartTimings","Save/OutFoxPrefs.ini")
table.sort(Name)
Length = Length + 1
Name[#Name+1] = "Miss"

local TapNoteScores = {
	Types = Name,
	-- x values for P1 and P2
	x = { P1=64, P2=94 }
}

local RadarCategories = {
	Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
	-- x values for P1 and P2
	x = { P1=-180, P2=218 }
}


local t = Def.ActorFrame{
	InitCommand=function(self)self:zoom(0.8):xy(90,_screen.cy-24) end,
	OnCommand=function(self)
		-- shift the x position of this ActorFrame to -90 for PLAYER_2
		if side == PLAYER_2 then
			self:x( self:GetX() * -1 )
		end
	end
}

-- do "regular" TapNotes first
local coloring = LoadModule("SL/SL.JudgmentColor.lua"):GetGameModeColor()
local yscaleset = Length > 6 and scale( Length, 6, 11, 35, 18.5 ) or 35
local zoomscale = Length > 6 and scale( Length, 6, 11, 1.15, 0.75 ) or 1.2
for i=1,#TapNoteScores.Types do
	local window = TapNoteScores.Types[i]
	local number = pss:GetTapNoteScores( "TapNoteScore_"..window )

	-- actual numbers
	t[#t+1] = Def.RollingNumbers{
		Font="Wendy/_wendy white",
		InitCommand=function(self)
			self:zoom( zoomscale ):horizalign(right)

			if CurPrefTiming ~= "ITG" then
				self:diffuse( coloring["TapNoteScore_" .. window] )
			end

			-- if some TimingWindows were turned off, the leading 0s should not
			-- be colored any differently than the (lack of) JudgmentNumber,
			-- so load a unique Metric group.
			local gmods = SL.Global.ActiveModifiers
			if gmods.TimingWindows[i]==false and i ~= #TapNoteScores.Types or
			 (SL.Global.GameMode == "StomperZ" and i == 5) then
				self:Load("RollingNumbersEvaluationNoDecentsWayOffs")
				self:diffuse(color("#444444"))

			-- Otherwise, We want leading 0s to be dimmed, so load the Metrics
			-- group "RollingNumberEvaluationA"	which does that for us.
			else
				self:Load("RollingNumbersEvaluationA")
			end
		end,
		BeginCommand=function(self)
			self:x( TapNoteScores.x[ToEnumShortString(side)] )
			self:y((i-1)*yscaleset -20)
			self:targetnumber(number)
		end
	}

end


-- then handle holds, mines, hands, rolls
for index, RCType in ipairs(RadarCategories.Types) do

	local performance = pss:GetRadarActual():GetValue( "RadarCategory_"..RCType )
	local possible = pss:GetRadarPossible():GetValue( "RadarCategory_"..RCType )

	-- player performance value
	t[#t+1] = Def.RollingNumbers{
		Font="Wendy/_wendy white",
		InitCommand=function(self) self:horizalign(right):Load("RollingNumbersEvaluationB") end,
		BeginCommand=function(self)
			self:y((index-1)*35 + 53):zoom(1.2)
			self:x( RadarCategories.x[ToEnumShortString(side)] )
			self:targetnumber(performance)
		end
	}

	--  slash
	t[#t+1] = LoadFont("Common Normal")..{
		Text="/",
		InitCommand=function(self) self:diffuse(color("#5A6166")):zoom(1.25):horizalign(right) end,
		BeginCommand=function(self)
			self:y((index-1)*35 + 53)
			self:x( ((side == PLAYER_1) and -168) or 230 )
		end
	}

	-- possible value
	t[#t+1] = LoadFont("Wendy/_wendy white")..{
		InitCommand=function(self) self:horizalign(right) end,
		BeginCommand=function(self)
			self:y((index-1)*35 + 53):zoom(1.2)
			self:x( ((side == PLAYER_1) and -114) or 286 )
			self:settext(("%03.0f"):format(possible))
			local leadingZeroAttr = { Length=3-tonumber(tostring(possible):len()), Diffuse=color("#5A6166") }
			self:AddAttribute(0, leadingZeroAttr )
		end
	}
end

return t
