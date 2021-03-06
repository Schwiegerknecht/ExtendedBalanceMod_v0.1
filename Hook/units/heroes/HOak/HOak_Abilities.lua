--Increase Rally duration to 10 seconds up from 5
Buffs.HOakRally.Duration = 10
Buffs.HOakRallyHeal.Duration = 10

-- Shield 
-- Adapt Shield durations for a linear progression (3/4/5/6). -- Schwiegerknecht
Buffs.HOAKShield03.Duration = 5 --(down from 6)
-- Also create a progression from damage immunity to cleanse to damage and debuff immunity -- Schwiegerknecht
-- Remove the cleanse from Shield I, so now it does what the description says.
Buffs.HOAKShield01.OnBuffAffect = function(self, unit, instigator)
    unit:SetInvulnerableMesh(true)

    # Shield activation effects
    FxShieldActivate( unit )
end
-- Adapt description for Shield II to include the debuff cleanse -- Schwiegerknecht
Ability.HOAKShield02.Description = 'Oak grants a shield to a target, cleansing them from debuffs and making them immune to damage for [GetBuffDuration] seconds.'
-- Adapt description for Shield III to include debuff immunity -- Schwiegerknecht
Ability.HOAKShield03.Description = 'Oak grants a shield to a target, making them immune to damage and debuffs for [GetBuffDuration] seconds.'
-- Adapt description for Shield IV to include debuff immunity -- Schwiegerknecht
Ability.HOAKShield04.Description = 'Oak grants a shield to a target, making them immune to damage and debuffs for [GetBuffDuration] seconds. Also, this powerful version of Shield removes debuffs and heals for [GetHealAmount].'