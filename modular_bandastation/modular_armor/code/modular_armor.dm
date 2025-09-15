#define POUCH (1<<12)

/obj/item/clothing/suit/armor/plate_carrier
        name = "плитник"
        desc = "Модульный жилет, в который вставляются бронеплиты."
	icon_state = "armor"
	body_parts_covered = CHEST
	var/list/modules
	var/datum/armor/base_armor_type = /datum/armor/none
	var/datum/armor_module_preset/preset_type

/obj/item/clothing/suit/armor/plate_carrier/Initialize(mapload)
	. = ..()
	modules = list(CHEST = null, ARMS = null, LEGS = null, POUCH = null)
	update_modules()
        if(preset_type)
                var/datum/armor_module_preset/preset = new preset_type
                preset.apply_to(src)

/obj/item/clothing/suit/armor/plate_carrier/proc/update_modules()
	var/datum/armor/new_armor = get_armor_by_type(base_armor_type)
	var/covered = CHEST
	var/slow = 0
	cut_overlays()
	for(var/slot in modules)
		var/obj/item/armor_module/M = modules[slot]
		if(!M)
			continue
	       new_armor = new_armor.add_other_armor(M.get_armor())
               if(slot & (CHEST|ARMS|LEGS))
		       covered |= slot
	       slow += M.slowdown
	       add_overlay(image(M.icon, M.icon_state))
	set_armor(new_armor)
	body_parts_covered = covered
	slowdown = slow

/obj/item/clothing/suit/armor/plate_carrier/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/armor_module))
		var/obj/item/armor_module/M = I
		if(modules[M.slot])
                        to_chat(user, span_warning("В этом слоте уже установлен модуль."))
			return
		if(user.transferItemToLoc(M, src))
			modules[M.slot] = M
			update_modules()
                        to_chat(user, span_notice("Вы вставляете [M] в [src]."))
		return
	..()

/obj/item/clothing/suit/armor/plate_carrier/attack_self(mob/user)
	var/list/options = list()
	for(var/slot in modules)
		var/obj/item/armor_module/M = modules[slot]
		if(M)
			options[slot_to_text(slot)] = slot
	if(!options.len)
		return ..()
        var/choice = input(user, "Какой модуль снять?", "[src]") as null|anything in options
        if(!choice || src.loc != user)
                return
        var/slot = options[choice]
        var/obj/item/armor_module/M = modules[slot]
        if(!M)
                return
        modules[slot] = null
        update_modules()
        user.put_in_hands(M)
        to_chat(user, span_notice("Вы снимаете [M] с [src]."))

// helper to name slots
/obj/item/clothing/suit/armor/plate_carrier/proc/slot_to_text(slot)
        switch(slot)
                if(CHEST)
                        return "Грудь"
                if(ARMS)
                        return "Руки"
                if(LEGS)
                        return "Ноги"
                if(POUCH)
                        return "Подсумок"
        return "Неизвестно"

/obj/item/armor_module
        name = "модуль брони"
	icon = 'icons/obj/clothing/suits/armor.dmi'
	icon_state = "armor"
	var/slot = CHEST
	var/armor_type = /datum/armor/none
	var/slowdown = 0

/obj/item/armor_module/Initialize(mapload)
	. = ..()
	set_armor(armor_type)

/obj/item/armor_module/pouch
        name = "подсумок"
	slot = POUCH
	icon_state = "pouch"

/obj/item/armor_module/pouch/Initialize(mapload)
	. = ..()
	create_storage(max_slots = 2, max_specific_storage = WEIGHT_CLASS_SMALL, max_total_storage = WEIGHT_CLASS_SMALL * 2)

/obj/item/armor_module/pouch/large
        name = "большой подсумок"
	icon_state = "pouch_large"

/obj/item/armor_module/pouch/large/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 4
	atom_storage.max_total_storage = WEIGHT_CLASS_NORMAL * 4
	atom_storage.max_specific_storage = WEIGHT_CLASS_NORMAL

/obj/item/armor_module/pouch/magazine
        name = "подсумок для магазинов"
	icon_state = "pouch_mag"

/obj/item/armor_module/pouch/magazine/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(list(/obj/item/ammo_box/magazine))

/obj/item/armor_module/chest/basic
        name = "обычная грудная плита"
	slot = CHEST
	armor_type = /datum/armor/plate_basic
	icon_state = "plate_chest"

/obj/item/armor_module/arms/basic
        name = "обычные защитные щитки для рук"
	slot = ARMS
	armor_type = /datum/armor/arm_basic
	icon_state = "plate_arms"

/obj/item/armor_module/legs/basic
        name = "обычные защитные щитки для ног"
	slot = LEGS
	armor_type = /datum/armor/leg_basic
	icon_state = "plate_legs"

/obj/item/armor_module/chest/heavy
        name = "тяжёлая грудная плита"
	slot = CHEST
	armor_type = /datum/armor/plate_heavy
	slowdown = 1
	icon_state = "plate_chest_heavy"

/obj/item/armor_module/arms/heavy
        name = "тяжёлые защитные щитки для рук"
	slot = ARMS
	armor_type = /datum/armor/arm_heavy
	slowdown = 0.5
	icon_state = "plate_arms_heavy"

/obj/item/armor_module/legs/heavy
        name = "тяжёлые защитные щитки для ног"
	slot = LEGS
	armor_type = /datum/armor/leg_heavy
	slowdown = 0.5
	icon_state = "plate_legs_heavy"

/datum/armor_module_preset
	var/list/modules = list()

/datum/armor_module_preset/proc/apply_to(obj/item/clothing/suit/armor/plate_carrier/PC)
	for(var/slot in modules)
		if(PC.modules[slot])
			continue
		var/path = modules[slot]
		PC.modules[slot] = new path(PC)
	PC.update_modules()

/datum/armor_module_preset/basic_chest
        modules = list(CHEST = /obj/item/armor_module/chest/basic)

/datum/armor_module_preset/full_basic
	modules = list(
		CHEST = /obj/item/armor_module/chest/basic,
		ARMS = /obj/item/armor_module/arms/basic,
		LEGS = /obj/item/armor_module/legs/basic,
	)

/datum/armor_module_preset/full_heavy
	modules = list(
		CHEST = /obj/item/armor_module/chest/heavy,
		ARMS = /obj/item/armor_module/arms/heavy,
		LEGS = /obj/item/armor_module/legs/heavy,
	)

/datum/armor_module_preset/pouch_basic
	modules = list(
	       POUCH = /obj/item/armor_module/pouch,
	)

/datum/armor_module_preset/pouch_magazine
	modules = list(
	       POUCH = /obj/item/armor_module/pouch/magazine,
	)

/datum/armor_module_preset/pouch_large
	modules = list(
	       POUCH = /obj/item/armor_module/pouch/large,
	)

/obj/item/clothing/suit/armor/plate_carrier/basic
        name = "плитник со стандартной плитой"
        preset_type = /datum/armor_module_preset/basic_chest

/obj/item/clothing/suit/armor/plate_carrier/full_basic
        name = "плитник с обычной бронёй"
        preset_type = /datum/armor_module_preset/full_basic

/obj/item/clothing/suit/armor/plate_carrier/full_heavy
        name = "плитник с тяжёлой бронёй"
        preset_type = /datum/armor_module_preset/full_heavy

/obj/item/clothing/suit/armor/plate_carrier/pouch_basic
        name = "плитник с подсумком"
        preset_type = /datum/armor_module_preset/pouch_basic

/obj/item/clothing/suit/armor/plate_carrier/pouch_magazine
        name = "плитник с подсумком для магазинов"
        preset_type = /datum/armor_module_preset/pouch_magazine

/obj/item/clothing/suit/armor/plate_carrier/pouch_large
        name = "плитник с большим подсумком"
        preset_type = /datum/armor_module_preset/pouch_large

/datum/armor/plate_basic
	melee = 30
	bullet = 30
	laser = 20
	energy = 20
	bomb = 15
	fire = 10
	acid = 10
	wound = 15

/datum/armor/arm_basic
	melee = 15
	bullet = 15
	wound = 10

/datum/armor/leg_basic
	melee = 15
	bullet = 15
	wound = 10

/datum/armor/plate_heavy
	melee = 40
	bullet = 40
	laser = 30
	energy = 25
	bomb = 25
	fire = 15
	acid = 15
	wound = 25

/datum/armor/arm_heavy
	melee = 25
	bullet = 25
	wound = 15

/datum/armor/leg_heavy
	melee = 25
	bullet = 25
	wound = 15

#undef POUCH
