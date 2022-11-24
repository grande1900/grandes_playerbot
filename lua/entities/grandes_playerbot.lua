AddCSLuaFile()
CreateConVar("grandes_playerbot_ff",1,FCVAR_NONE,"Determines whether the bots kill each other or not")
CreateConVar("grandes_playerbot_ignoreplayers",0,FCVAR_NONE,"Determines whether the bots ignore real players or not")
CreateConVar("grandes_playerbot_seek",0,FCVAR_NONE,"Determines whether the bots will actively seek out a target")
MidLongWep,MidWep,CQCWep,LongWep,MeleeWep = CreateConVar("grandes_playerbot_midlong_weapon","weapon_crossbow",FCVAR_NONE,""),
CreateConVar("grandes_playerbot_mid_weapon","weapon_ar2",FCVAR_NONE,""),
CreateConVar("grandes_playerbot_cqc_weapon","weapon_shotgun",FCVAR_NONE,""),
CreateConVar("grandes_playerbot_long_weapon","weapon_rpg",FCVAR_NONE,""),
CreateConVar("grandes_playerbot_melee_weapon","weapon_crowbar",FCVAR_NONE,"")
SpawnSpread = CreateConVar("grandes_playerbot_spread",256,FCVAR_NONE,"Spawn area for playerbots")
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
local SpawnPos
local Speed = math.random(300,400)
ENT.PrintName = "Bot"
ENT.Author = "Grande1900"
ENT.Information = "A bot that runs around killing stuff"
ENT.Category = "Other"
ENT.Editable = false
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_OPAQUE
local models = {}
for _, i in pairs(player_manager.AllValidModels()) do
	table.insert(models,i)
end

function CreateBot(plyr)
    if ( !game.SinglePlayer() && player.GetCount() < game.MaxPlayers() ) then 
        local bot = player.CreateNextBot(plyr:GetName().."'s Bot")
		return bot
    else
		if game.SinglePlayer() then
			plyr:PrintMessage(HUD_PRINTTALK, "Can't Create Bot in Singleplayer!")
		elseif player.GetCount() == game.MaxPlayers() then
			plyr:PrintMessage(HUD_PRINTTALK, "Can't Create Bot, too many players!")
		end
	end
	return nil
end

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = CreateBot(ply)
	if !ent then return end
	ent:StripWeapons()
	ent.SpawnPos = SpawnPos
	ent.noise = 0
	ent.CustomEnemy = NULL
	ent:SetPos( ent.SpawnPos )
	ent.GrandesPlayerbot = true
	local model = math.random(#models)
	ent:SetModel(models[model])
	ent:ConCommand("gmod_toolmode remover")
	hook.Add("PostUndo", ent:GetName()..ent:EntIndex(), function(u)
		if ent then
			for _, i in ipairs(u.Entities) do
				if i == ent then
					ent:Kick("Removed")
					break
				end
			end
		end
	end)
	return ent
end

function ENT:Initialize()
	return true
end
hook.Add( "PostPlayerDeath", "GRANDES_SHITPACK_PLAYERBOT_RESPAWN", function( victim )
	local dmodel = victim:GetModel()
	if (victim.GrandesPlayerbot) then 
		victim:Spawn()
		victim:SetModel(dmodel) 
		
		victim:SetPos(Vector(math.random(victim.SpawnPos.x-SpawnSpread:GetInt(),victim.SpawnPos.x+SpawnSpread:GetInt()),
		math.random(victim.SpawnPos.y-SpawnSpread:GetInt(),victim.SpawnPos.y+SpawnSpread:GetInt()),
		victim.SpawnPos.z)) 
	end
end)
hook.Add( "PlayerSpawn", "GRANDES_SHITPACK_PLAYERBOT_RESPAWN_GIVE",function( victim )
	if (victim.GrandesPlayerbot) then
		for _, i in ipairs({MidLongWep:GetString(),MidWep:GetString(),CQCWep:GetString(),LongWep:GetString(),MeleeWep:GetString()}) do
			victim:Give(i)
		end
	end
end)
hook.Add( "EntityTakeDamage", "GRANDES_SHITPACK_PLAYERBOT_REGURGITATE", function( victim, dmginfo )
	if victim.GrandesPlayerbot and !GetConVar("ai_disabled"):GetBool() then
		local atkr = dmginfo:GetAttacker()
		if atkr:IsPlayer() then
			if atkr.GrandesPlayerbot then
				if GetConVar("grandes_playerbot_ff"):GetBool() then
					victim.CustomEnemy = atkr
				end
			elseif !GetConVar("grandes_playerbot_ignoreplayers"):GetBool() then
				victim.CustomEnemy = atkr
			end
		elseif !atkr:IsWorld() then
			victim.CustomEnemy = atkr
		end
	end
end)
hook.Add( "StartCommand", "GRANDES_SHITPACK_PLAYERBOT_FUNCTION", function( ply, cmd )

	-- If the player is not a bot or the bot is dead, do not do anything
	-- TODO: Maybe spawn the bot manually here if the bot is dead
	if ( !ply.GrandesPlayerbot or !ply:Alive() or GetConVar("ai_disabled"):GetBool() ) then return end
	local tr = util.TraceEntity({
	start = ply:GetPos(),
	endpos = ply:GetPos(),
	filter = ply,
	},ply)
	if tr.Hit and (tr.Entity:IsWorld() or tr.Entity:IsPlayer()) then
		ply:SetPos(Vector(math.random(ply.SpawnPos.x-SpawnSpread:GetInt(),ply.SpawnPos.x+SpawnSpread:GetInt()),
		math.random(ply.SpawnPos.y-SpawnSpread:GetInt(),ply.SpawnPos.y+SpawnSpread:GetInt()),
		ply.SpawnPos.z)) 
	end
	-- Clear any default movement or actions
	cmd:ClearMovement() 
	-- Bot has no enemy, try to find one
	if ply.CustomEnemy:IsValid() then
		if ply.CustomEnemy.GrandesPlayerbot and !GetConVar("grandes_playerbot_ff"):GetBool() then ply.CustomEnemy = NULL
		elseif ply.CustomEnemy:IsPlayer() and !ply.CustomEnemy.GrandesPlayerbot and GetConVar("grandes_playerbot_ignoreplayers"):GetBool() then ply.CustomEnemy = NULL end
	elseif GetConVar("grandes_playerbot_seek"):GetBool() then
		local blacklist = NULL
		for id, pl in ipairs( ents.FindInSphere(ply:GetPos(),4096 ) ) do
			if !GetConVar("ai_disabled"):GetBool() then
				if pl == ply then continue end
				if pl:IsPlayer() then
					if pl.GrandesPlayerbot and GetConVar("grandes_playerbot_ff"):GetBool() then
						ply.CustomEnemy = pl
						return
					elseif !GetConVar("grandes_playerbot_ignoreplayers"):GetBool() then
						ply.CustomEnemy = pl 
						return
					end
				elseif pl:IsNPC()||pl:IsNextBot()||pl:IsRagdoll()||pl:GetClass()=="npc_antlion_grub" then
					ply.CustomEnemy = pl
					return
				end
			end
		end
			if ( !IsValid( ply.CustomEnemy ) ) then return end
			local tr = util.TraceLine( {
			start = ply:GetShootPos(),
			endpos = ply:GetShootPos() + ( ply.CustomEnemy:GetPos() - ply:GetPos() ):GetNormalized() * 65536,
			filter = ply,
			mask = MASK_SHOT_HULL } )
		
		if tr.Entity ~= ply.CustomEnemy then
			blacklist = ply.CustomEnemy
			ply.CustomEnemy = NULL
		end
	end
	
	-- TODO: Maybe add a Line Of Sight check so bots won't walk into walls to try to get to their target
		-- Or add path finding so bots can find their way to enemies
	local weapons = ply:GetWeapons()
	-- We failed to find an enemy, don't do anything
	if ( !IsValid( ply.CustomEnemy ) ) or ply.CustomEnemy == ply then return end
	-- Move forwards at the bots normal walking speed
	cmd:SetForwardMove( Speed )
	if ( !IsValid( ply.CustomEnemy ) ) then return end
	local Dorps = ply.CustomEnemy:EyePos()

	-- Aim at our enemy
	--ply.noise = math.Clamp(ply.noise + math.random(-5,5),-15,15)
	cmd:SetViewAngles( ( Dorps - ply:GetShootPos() ):GetNormalized():Angle() )
	if 64 < ply:EyePos():Distance(Dorps) and ply:EyePos():Distance(Dorps) < 128 then ply:SelectWeapon(CQCWep:GetString()) cmd:SetViewAngles(-cmd:GetViewAngles())
	elseif 128 < ply:EyePos():Distance(Dorps) and ply:EyePos():Distance(Dorps) < 512 then ply:SelectWeapon(MidWep:GetString())
	elseif 512 < ply:EyePos():Distance(Dorps) and ply:EyePos():Distance(Dorps) < 2048 then ply:SelectWeapon(MidLongWep:GetString())
	elseif 2048 < ply:EyePos():Distance(Dorps) and ply:EyePos():Distance(Dorps) then ply:SelectWeapon(LongWep:GetString())
	elseif ply:GetPos():Distance(ply.CustomEnemy:GetPos()) < 64 then ply:SelectWeapon(MeleeWep:GetString()) cmd:SetViewAngles(-cmd:GetViewAngles()) end
	if ply:GetActiveWeapon():IsWeapon() then
		ply:GiveAmmo(1,ply:GetActiveWeapon():GetPrimaryAmmoType())
		ply:GiveAmmo(1,ply:GetActiveWeapon():GetSecondaryAmmoType())
	end
	ply:SetEyeAngles( ( Dorps - ply:GetShootPos() ):GetNormalized():Angle() )
	for _, i in ipairs({MidLongWep:GetString(),MidWep:GetString(),CQCWep:GetString(),LongWep:GetString(),MeleeWep:GetString()}) do
		ply:Give(i)
	end
	-- Hold Mouse 1 to cause the bot to attack
		local tr = util.TraceLine( {
			start = ply:GetShootPos(),
			endpos = ply:GetShootPos() + ( Dorps - ply:GetShootPos() ):GetNormalized() * 65536,
			filter = ply,
			mask = MASK_SHOT_HULL } )
		local r = math.random()
		if r<0.05 then
			cmd:SetButtons( IN_JUMP + IN_SPEED )
		elseif r<0.10 then
			cmd:SetButtons( IN_DUCK )
		elseif r<0.15 then
			cmd:SetButtons( IN_SPEED + IN_ATTACK2 )
		elseif r<0.20 then
			cmd:ClearButtons()
		else
			cmd:SetButtons( IN_ATTACK + IN_SPEED)
		end
	-- Enemy is dead, clear our enemy so that we may acquire a new one
	if !ply.CustomEnemy:IsValid() or ( ply.CustomEnemy:IsPlayer() and !ply.CustomEnemy:Alive() ) then
		ply.CustomEnemy = NULL
	end

end )

hook.Add( "AddToolMenuCategories", "GRANDES_SETTINGS", function()
	spawnmenu.AddToolCategory( "Utilities", "GrandesSettings", "#Grande's Settings" )
end )

hook.Add( "PopulateToolMenu", "GRANDES_BOT_SETTINGS", function()
	spawnmenu.AddToolMenuOption( "Utilities", "GrandesSettings", "BOTSETTINGS", "#Grande's Bot", "", "", function( panel )
		panel:CheckBox( "Friendly Fire", "grandes_playerbot_ff" )
		panel:CheckBox( "Ignore Players", "grandes_playerbot_ignoreplayers" )
		panel:CheckBox( "Seek Target", "grandes_playerbot_seek" )
		panel:TextEntry( "Melee weapon", "grandes_playerbot_melee_weapon" )
		panel:TextEntry( "CQC weapon", "grandes_playerbot_cqc_weapon" )
		panel:TextEntry( "Midrange weapon", "grandes_playerbot_mid_weapon" )
		panel:TextEntry( "Longrange weapon", "grandes_playerbot_midlong_weapon" )
		panel:TextEntry( "Longer-range weapon", "grandes_playerbot_long_weapon" )
		panel:NumSlider( "Random spawn area", "grandes_playerbot_spread", 0, 2048  )
		-- Add stuff here
	end )
end )
