--Reduce Batswarm II to Range 25 to make range increases per level consistent at 20,25,30
Ability.HVampireBatSwarm02.RangeMax = 25


-- Schwiegerknecht start

-- Make description for Vampiric Aura more accurate
Ability.HVampireVampiricAura01.GetLifeSteal = function(self) return math.floor( Buffs['HVampireVampiricAura01'].Affects.LifeSteal.Add * 100) end
Ability.HVampireVampiricAura01.Description = 'Lord Erebus gains a [GetLifeSteal]% Life Steal Aura.'


--Increase Army of the Night buffs: 40% Attack Speed (from 5) and + 100% Lifesteal (from 10%)
Buffs.HVampireArmyoftheNight.Affects.RateOfFire.Mult = 0.4
Buffs.HVampireArmyoftheNight.Affects.LifeSteal.Add = 1.0

-- Give Nightcrawlers a WeaponProc to reduce armor
-- Add ability via Buff in the ArmyBonusBlueprint
Buffs.HVampireArmyoftheNight.OnBuffAffect = function(self, unit, instigator)
    Abil.AddAbility(unit, 'HVampireArmyoftheNightMinionAbil', true)
end
-- Give WeaponProc to Night Walkers
AbilityBlueprint {
    Name = 'HVampireArmyoftheNightMinionAbil',
    DisplayName = 'Army of the Night Armor Shred',
    Description = 'Erebus\' Night Walkers have a [GetProcChance]% chance on each auto attack to reduce their targets armor.',
    GetProcChance = function(self) return math.floor( self.WeaponProcChance ) end,
    AbilityType = 'WeaponProc',
    WeaponProcChance = 50,
    OnWeaponProc = function(self, unit, target, damageData)
        if EntityCategoryContains(categories.ALLUNITS, target) and not EntityCategoryContains(categories.UNTARGETABLE, target) then
            Buff.ApplyBuff(target, 'HVampireArmyoftheNightProcDebuff', unit)
            # Play altered impact effects on top of normal effects
            #FxDeadeyeImpact(unit, damageData.Origin)
            #FxDeadeyeImpact(target)
        end
    end,
    Icon = '/DGVampLord/NewVamplordArmyoftheNight01',
}
-- Debuff applied on Proc
BuffBlueprint {
    Name = 'HVampireArmyoftheNightProcDebuff',
    DisplayName = 'Army of the Night',
    Description = 'Armor reduced.',
    BuffType = 'HVAMPIREVAMPIREPROC',
    EntityCategory = 'ALLUNITS - UNTARGETABLE',
    Debuff = true,
    CanBeDispelled = true,
    Stacks = 'Always',
    Duration = 5,
    Affects = {
        Armor = {Add = -75},
    },
    Icon = '/DGVampLord/NewVamplordArmyoftheNight01',
}
-- Adjust description
Ability.HVampireArmyoftheNight.GetLifeStealBonus = function(self) return math.floor( Buffs['HVampireArmyoftheNight'].Affects.LifeSteal.Add * 100 ) end
Ability.HVampireArmyoftheNight.GetProcChance = function(self) return math.floor( Ability['HVampireArmyoftheNightMinionAbil'].WeaponProcChance ) end
Ability.HVampireArmyoftheNight.GetArmorReduction = function(self) return math.floor( Buffs['HVampireArmyoftheNightProcDebuff'].Affects.Armor.Add * -1 ) end

Ability.HVampireArmyoftheNight.Description = 'Lord Erebus leads his Night Walkers as a bloodthirsty pack. Their Attack Speed is increased by [GetAttackBonus]% and they gain [GetLifeStealBonus]% lifesteal. They also have a [GetProcChance]% chance on auto attack to reduce the target\'s armor by [GetArmorReduction].'

__moduleinfo.auto_reload = true


--[[The below works once for existing Night Crawlers, not new ones after adding ability. Use Coven function instead. Or maybe the ArmyBonus right away?
Ability.HVampireArmyoftheNight.OnAbilityAdded = function(self, unit)
    unit:GetAIBrain():AddArmyBonus( 'HVampireArmyoftheNight', self )
    local vampirelings = ArmyBrains[unit:GetArmy()]:GetListOfUnits(categories.hvampirevampire01, false)
    for k,vampireling in vampirelings do
        Buff.ApplyBuff(vampireling, 'HVampireArmyoftheNightPlaceholder', unit)
    end
end
]]

-- Testing if you can call the new class EliteCrawler. But you can't that easily.
--[[
function RaiseVampire(abilDef, deadUnit)
    local inst = deadUnit.AbilityData.VampLord.VampireConversionInst
    if not inst or inst:IsDead() or deadUnit == inst then
        return
    end
    local rand = Random(1, 100)
    if rand > abilDef.VampireChance then
        return
    end

    local numVampires = ArmyBrains[inst:GetArmy()]:GetCurrentUnits(categories.elitecrawler)
    #LOG('*DEBUG: num vampires = ' .. numVampires)
    if(numVampires < inst.AbilityData.Vampire.VampireMax) then
        local pos = deadUnit:GetPosition()
        local orient = deadUnit:GetOrientation()
        local brainNum = inst:GetArmy()
        local vampireling = CreateUnitHPR('EliteCrawler', brainNum, pos[1], pos[2], pos[3], orient[1], orient[2],orient[3])
        if not vampireling then
            return
        end
		vampireling:AdjustHealth( vampireling:GetMaxHealth() )
        IssueGuard({vampireling}, inst)

        # Apply Coven buff to new vampire
        for i = 1, 3 do
            if(Validate.HasAbility(inst, 'HVampireCoven0' .. i)) then
                Buff.ApplyBuff(vampireling, 'HVampireCovenTarget0' .. i, inst)
            end
            if(Validate.HasAbility(inst, 'HVampireConversion0' .. i)) then
                Buff.ApplyBuff(vampireling, 'HVampireConversionTarget0' .. i, inst)
                vampireling:AdjustHealth(vampireling:GetMaxHealth())
            end
        end
    end
end

function Coven(buffDef, vampLord, buffName)
    if(vampLord and not vampLord:IsDead()) then
        if(not vampLord.AbilityData.Vampire) then
            vampLord.AbilityData.Vampire = {}
        end
        if buffDef.VampireMax then
            vampLord.AbilityData.Vampire.VampireMax = buffDef.VampireMax
        end

        # Apply Coven buff to existing vampires
        # Vampirelings Health is increased by the difference between their old max Health and their new max Health
        if(buffName) then
            local vampirelings = ArmyBrains[vampLord:GetArmy()]:GetListOfUnits(categories.elitecrawler, false)
            for k, v in vampirelings do
                if(v and not v:IsDead()) then
                    local oldHealth = v:GetHealth()
                    local oldMaxHealth = v:GetMaxHealth()
                    Buff.ApplyBuff(v, buffName, vampLord)
                    local newMaxHealth = v:GetMaxHealth()
                    local adjustedHealth = newMaxHealth - (oldMaxHealth - oldHealth)
                    v:AdjustHealth(adjustedHealth)
                end
            end
        end
    end
end
]]