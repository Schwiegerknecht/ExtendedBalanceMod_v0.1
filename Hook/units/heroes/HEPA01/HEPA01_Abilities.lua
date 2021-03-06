-- Increase wrath timers from 7 to 10 and 10 to 15
Buffs.HEPA01BestialWrath01.Duration = 10
Buffs.HEPA01BestialWrath02.Duration = 10
Buffs.HEPA01BestialWrath03.Duration = 10
Buffs.HEPA01BestialWrath04.Duration = 10
Buffs.HEPA01BestialWrath05.Duration = 15

--Increase diseased claw snare
Buffs.HEPA01DiseasedClaws02.Affects.MoveMult.Mult = -0.10
Buffs.HEPA01DiseasedClaws03.Affects.MoveMult.Mult = -0.15

--Increase Grasp Drain
Ability.HEPA01FoulGrasp02.Amount = 166
Ability.HEPA01FoulGrasp03.Amount = 249

--Decrease the damage mitigation by Acclimation (down from 40%) --Schwiegerknecht
Buffs.HEPA01Acclimation.Affects.DamageTakenMult = {Add = -0.25}

--Increase self damage from Ooze to 20/40/60/80 (from 20/30/40/50)
for i = 1,4 do
    Buffs['HEPA01OozeSelf0'..i].Affects.Health.Add = -20*i
end

--Make Foul Grasp I+II not ignore stun immunities anymore --Schwiegerknecht
-- I think this works, but need to test with people
BuffBlueprint {
    Name = 'HEPA01FoulGraspStun02',
    DisplayName = '<LOC ABILITY_HEPA01_0043>Foul Grasp',
    Description = '<LOC ABILITY_HEPA01_0044>Stunned.',
    BuffType = 'HEPA01FOULGRASPSTUN',
    Debuff = true,
    Stacks = 'ALWAYS',
    Duration = 2,
    TriggersStunImmune = true,
    Affects = {
        Stun = {Add = 0},
    },
    Icon = '/DGUncleanBeast/NewUncleanFoulGrasp01',
}
Ability.HEPA01FoulGrasp01.Description = 'Unclean Beast clutches a target in its claws, stunning them and draining [GetDamageAmt] life over [GetDuration] seconds. This Level of Foul Grasp should not ignore Stun Immunities anymore. TESTING REQUIRED!'
Ability.HEPA01FoulGrasp02.Description = 'Unclean Beast clutches a target in its claws, stunning them and draining [GetDamageAmt] life over [GetDuration] seconds. This Level of Foul Grasp should not ignore Stun Immunities anymore. TESTING REQUIRED!'

-- Create copies of the Foul Grasp functions, changing all instances of
-- HEPA01FoulGraspStun01
DrawLifeNoImmune = function(def, unit, target)
    unit:GetWeapon(1):SetStayOnTarget(true)

    # Add callbacks so we can interrupt Grasp
    unit.Callbacks.OnWeaponFire:Add(EndGraspNoImmune, def)
    unit.Callbacks.OnKilled:Add(EndGraspNoImmune, def)
    unit.Callbacks.OnStunned:Add(EndGraspNoImmune, def)
    unit.Callbacks.OnFrozen:Add(EndGraspNoImmune, def)
    target.Callbacks.OnKilled:Add(EndGraspNoImmune, def)
    unit.Callbacks.OnAbilityBeginCast:Add(EndGraspCancelNoImmune)

    Buff.ApplyBuff(unit, 'StayOnTarget', unit)
    Buff.ApplyBuff(target, 'WeaponDisable', unit, unit:GetArmy())
    Buff.ApplyBuff(unit, 'WeaponDisable', unit)
    target:GetNavigator():AbortMove()
    if target.Character then
        target.Character:AbortCast()
    end
    Buff.ApplyBuff(target, 'Immobile', unit, unit:GetArmy())
    Buff.ApplyBuff(target, 'HEPA01FoulGraspStun02', unit, unit:GetArmy())

    unit:GetNavigator():AbortMove()
    Buff.ApplyBuff(unit, 'Immobile', unit)

    unit.AbilityData.FoulGraspTarget = target
    
    WaitSeconds(0.1)
    unit.Character:PlayAction('CastFoulGraspStart')
    if not unit:IsDead() then
        unit.Callbacks.OnMotionHorzEventChange:Add(Moved, def)
    end
    WaitSeconds(0.3)

    # create Foul Grasp effects at target with a vector towards the Unclean Beast.
    local unitpos = table.copy(unit:GetPosition())
    unitpos[2] = unitpos[2]+3
    local dir = VDiff(unitpos,target:GetPosition())
    local dist = VLength( dir )
    local dirNorm = VNormal(dir)
    dirNorm[2] = dirNorm[2]/2
    local unitbp = target:GetBlueprint()
    local unitheight = unitbp.SizeY * 0.9
    local unitwidth = (unitbp.SizeX + unitbp.SizeZ) / 2.5
    local unitVol = (unitbp.SizeX + unitbp.SizeZ + unitheight) / 3
    local army = unit:GetArmy()

    local fx1 = EffectTemplates.UncleanBeast.FoulGrasp01
    local fx2 = EffectTemplates.UncleanBeast.FoulGrasp02
    local fx3 = EffectTemplates.UncleanBeast.FoulGrasp05
    unit.AbilityData.FoulGraspEffects = {}
    # Brown multiply wisps
    for k, v in fx1 do
        emit = CreateAttachedEmitter( target, -2, army, v )
        emit:SetEmitterCurveParam('EMITRATE_CURVE', unitVol*1.7, 0.0)
        emit:SetEmitterCurveParam('LIFETIME_CURVE', dist, dist*0.45)
        emit:SetEmitterCurveParam('XDIR_CURVE', dirNorm[1], 0.3)
        emit:SetEmitterCurveParam('YDIR_CURVE', dirNorm[2], 0.0)
        emit:SetEmitterCurveParam('ZDIR_CURVE', dirNorm[3], 0.3)
        emit:SetEmitterCurveParam('X_POSITION_CURVE', 0.0, unitwidth)
        emit:SetEmitterCurveParam('Y_POSITION_CURVE', unitheight*0.4, unitheight)
        emit:SetEmitterCurveParam('Z_POSITION_CURVE', 0.0, unitwidth)
        table.insert( unit.AbilityData.FoulGraspEffects, emit )
    end
    # Dark red blood
    for k, v in fx2 do
        emit = CreateAttachedEmitter( target, -2, army, v )
        emit:SetEmitterCurveParam('EMITRATE_CURVE', unitVol*3.0, 0.0)
        emit:SetEmitterCurveParam('LIFETIME_CURVE', dist*0.6, dist*0.2)
        emit:SetEmitterCurveParam('XDIR_CURVE', dirNorm[1], 0.3)
        emit:SetEmitterCurveParam('ZDIR_CURVE', dirNorm[3], 0.3)
        emit:SetEmitterCurveParam('X_POSITION_CURVE', 0.0, unitwidth)
        emit:SetEmitterCurveParam('Y_POSITION_CURVE', unitheight*0.4, unitheight)
        emit:SetEmitterCurveParam('Z_POSITION_CURVE', 0.0, unitwidth)
        table.insert( unit.AbilityData.FoulGraspEffects, emit )
    end
    # Healing wisps on Unclean Beast
    AttachEffectsAtBone( unit, EffectTemplates.UncleanBeast.FoulGrasp03, -2, nil, nil, nil, unit.AbilityData.FoulGraspEffects )
    # Blood along the ground
    AttachEffectsAtBone( unit, EffectTemplates.UncleanBeast.FoulGrasp04, -2, nil, nil, nil, unit.AbilityData.FoulGraspEffects )
    # Inward rings at target
    for k, v in fx3 do
        emit = CreateAttachedEmitter( target, -2, army, v )
        emit:SetEmitterCurveParam('BEGINSIZE_CURVE', unitwidth*2.0, unitwidth)
        table.insert( unit.AbilityData.FoulGraspEffects, emit )
    end

    local data = {
        Instigator = unit,
        InstigatorBp = unit:GetBlueprint(),
        InstigatorArmy = unit:GetArmy(),
        Type = 'Spell',
        DamageAction = def.Name,
        Radius = 0,
        DamageSelf = true,
        DamageFriendly = true,
        ArmorImmune = true,
        CanBackfire = false,
        CanBeEvaded = false,
        CanCrit = false,
        CanDamageReturn = false,
        CanMagicResist = false,
        CanOverKill = true,
        IgnoreDamageRangePercent = true,
        Group = "UNITS",
    }

    for i = 1, def.Pulses do
        if not target:IsDead() and not unit:IsDead() and not unit.Silenced then
            Leech( unit, target, data, def.Amount )
            WaitSeconds(0.5)
        else
            EndGraspNoImmune(def, unit, target)
        end
    end
    EndGraspNoImmune(def, unit, target)
end

function EndGraspNoImmune(def, unit)
    #LOG("*DEBUG: Ending foul grasp")
    unit.Callbacks.OnWeaponFire:Remove(EndGraspNoImmune)
    unit.Callbacks.OnKilled:Remove(EndGraspNoImmune)
    unit.Callbacks.OnStunned:Remove(EndGraspNoImmune)
    unit.Callbacks.OnFrozen:Remove(EndGraspNoImmune)
    unit.Callbacks.OnMotionHorzEventChange:Remove(Moved)
    unit.Callbacks.OnAbilityBeginCast:Remove(EndGraspCancelNoImmune)

    local target = unit.AbilityData.FoulGraspTarget
    if target and not target:IsDead() then
        Buff.RemoveBuff(target, 'Immobile')
        Buff.RemoveBuff(target, 'HEPA01FoulGraspStun02')
        if Buff.HasBuff(target, 'WeaponDisable') then
            Buff.RemoveBuff(target, 'WeaponDisable')
        end
        target.Callbacks.OnKilled:Remove(EndGraspNoImmune)
    end

    if unit.AbilityData.FoulGraspEffects then
        for kEffect, vEffect in unit.AbilityData.FoulGraspEffects do
            vEffect:Destroy()
        end
        unit.AbilityData.FoulGraspEffects = nil
    end

    if unit.AbilityData.FoulGraspThread then
        unit.AbilityData.FoulGraspThread:Destroy()
        unit.AbilityData.FoulGraspThread = nil
    end
    if Buff.HasBuff(unit, 'WeaponDisable') then
        Buff.RemoveBuff(unit, 'WeaponDisable')
    end
    if Buff.HasBuff(unit, 'StayOnTarget') then
        Buff.RemoveBuff(unit, 'StayOnTarget', unit)
        #Lets make sure that the last instance of the buff is removed
        if not Buff.HasBuff(unit, 'StayOnTarget') then
            unit:GetWeapon(1):SetStayOnTarget(false)
        end
    end

    Buff.RemoveBuff(unit, 'Immobile')
    unit.Character:PlayAction('CastFoulGraspEnd')
end

function EndGraspCancelNoImmune(def, unit)
    #LOG("*DEBUG: Ending foul grasp")
    unit.Callbacks.OnWeaponFire:Remove(EndGraspNoImmune)
    unit.Callbacks.OnKilled:Remove(EndGraspNoImmune)
    unit.Callbacks.OnStunned:Remove(EndGraspNoImmune)
    unit.Callbacks.OnFrozen:Remove(EndGraspNoImmune)
    unit.Callbacks.OnMotionHorzEventChange:Remove(Moved)
    unit.Callbacks.OnAbilityBeginCast:Remove(EndGraspCancelNoImmune)

    local target = unit.AbilityData.FoulGraspTarget
    if target and not target:IsDead() then
        Buff.RemoveBuff(target, 'Immobile')
        Buff.RemoveBuff(target, 'HEPA01FoulGraspStun02')
        if Buff.HasBuff(target, 'WeaponDisable') then
            Buff.RemoveBuff(target, 'WeaponDisable')
        end
        target.Callbacks.OnKilled:Remove(EndGraspNoImmune)
    end

    if unit.AbilityData.FoulGraspEffects then
        for kEffect, vEffect in unit.AbilityData.FoulGraspEffects do
            vEffect:Destroy()
        end
        unit.AbilityData.FoulGraspEffects = nil
    end

    if unit.AbilityData.FoulGraspThread then
        unit.AbilityData.FoulGraspThread:Destroy()
        unit.AbilityData.FoulGraspThread = nil
    end
    if Buff.HasBuff(unit, 'WeaponDisable') then
        Buff.RemoveBuff(unit, 'WeaponDisable')
    end
    if Buff.HasBuff(unit, 'StayOnTarget') then
        Buff.RemoveBuff(unit, 'StayOnTarget', unit)
        #Lets make sure that the last instance of the buff is removed
        if not Buff.HasBuff(unit, 'StayOnTarget') then
            unit:GetWeapon(1):SetStayOnTarget(false)
        end
    end

    Buff.RemoveBuff(unit, 'Immobile')
    unit.Character:PlayAction('CastFoulGraspEnd')
end
-- Use those functions In Foul Grasp I + II
Ability.HEPA01FoulGrasp01.OnStartAbility = function(self,unit,params)
    local target = params.Targets[1]
    local thd = ForkThread(DrawLifeNoImmune, self, unit, target)
    unit.Trash:Add(thd)
    target.Trash:Add(thd)
    unit.AbilityData.FoulGraspThread = thd
end
Ability.HEPA01FoulGrasp02.OnStartAbility = function(self,unit,params)
    local target = params.Targets[1]
    local thd = ForkThread(DrawLifeNoImmune, self, unit, target)
    unit.Trash:Add(thd)
    target.Trash:Add(thd)
    unit.AbilityData.FoulGraspThread = thd
end