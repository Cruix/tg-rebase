
/datum/species/snail
	name = "Snail Person"
	id = "snail"
	limbs_id = "human"
	default_color = "59CE00"
	species_traits = list(MUTCOLORS, EYECOLOR)
	attack_verb = "slap"
	burnmod = 2
	heatmod = 1.5
	coldmod = 1.5
	acidmod = 2
	speedmod = 2
	disliked_food = SUGAR | JUNKFOOD //junkfood is often salty
	liked_food = FRUIT | VEGETABLES

	mutant_bodyparts = list("snail_shell")
	default_features = list("snail_shell" = "Plain")

	var/shell_health = 100
	var/shell_maxhealth = 100
	var/shell_armor
	var/in_shell = FALSE
	var/datum/action/innate/toggle_shell/toggle_shell_action = new /datum/action/innate/toggle_shell()
	var/obj/structure/snail_shell/my_shell = new /obj/structure/snail_shell(null)

/datum/species/snail/before_equip_job(datum/job/J, mob/living/carbon/human/H)
	to_chat(H, "<span class='info'><b>You are a Snail Person.</b> </span>")
	to_chat(H, "<span class='info'>Hide in your shell to avoid damage to yourself. Should your shell be damaged or destroyed, aquire calcium to allow it to heal.</span>")

/datum/species/snail/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	toggle_shell_action.Grant(C)
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		if(!H.dna.features["snail_shell"])
			H.dna.features["snail_shell"] = "[(H.client && H.client.prefs && LAZYLEN(H.client.prefs.features) && H.client.prefs.features["snail_shell"]) ? H.client.prefs.features["snail_shell"] : "Plain"]"
			handle_mutant_bodyparts(H)

/datum/species/snail/on_species_loss(mob/living/carbon/C)
	. = ..()
	toggle_shell_action.Remove(C)

/datum/species/snail/spec_life(mob/living/carbon/human/H)
	..()
	if(in_shell && (H.loc != my_shell))
		exit_shell(H)

/datum/species/snail/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	switch(chem.id)
		if("sodiumchloride")
			H.adjustToxLoss(3)
		if("milk")
			shell_health = min(shell_health + 3, shell_maxhealth)
	return FALSE


/datum/species/snail/spec_death(gibbed, mob/living/carbon/human/H)
	exit_shell()
	..()

/datum/species/snail/apply_damage(damage, damagetype = BRUTE, def_zone = null, blocked, mob/living/carbon/human/H)
	. = ..()

/datum/species/snail/after_move(mob/living/carbon/C, start, end, old_dir)
	if(!isturf(start) || !isturf(end) || !C.has_gravity())
		return
	var/trail_exists = FALSE

	for(var/obj/effect/decal/cleanable/trail_holder/H in start) //checks for blood splatter already on the floor
		trail_exists = TRUE
		break
	if(isturf(start))
		var/trail_type = pick(list("xltrails_1", "xltrails2"))
		var/newdir = get_dir(end, start)
		if(newdir != old_dir)
			newdir = newdir | old_dir
			if(newdir == 3) //N + S
				newdir = NORTH
			else if(newdir == 12) //E + W
				newdir = EAST
		if((newdir in GLOB.cardinals) && (prob(50)))
			newdir = turn(get_dir(end, start), 180)
		if(!trail_exists)
			new /obj/effect/decal/cleanable/trail_holder(start, C.get_static_viruses())

		for(var/obj/effect/decal/cleanable/trail_holder/TH in start)
			if((!(newdir in TH.existing_dirs) || trail_type == "trails_1" || trail_type == "trails_2") && TH.existing_dirs.len <= 16) //maximum amount of overlays is 16 (all light & heavy directions filled)
				TH.existing_dirs += newdir
				TH.add_overlay(image('icons/effects/blood.dmi', trail_type, dir = newdir))
				TH.transfer_mob_blood_dna(C)

/datum/species/snail/proc/toggle_shell(mob/living/carbon/C)
	if((shell_health > 0) && !in_shell)
		enter_shell(C)
	else
		exit_shell(C)

/datum/species/snail/proc/exit_shell(mob/living/carbon/C)
	if(!in_shell)
		return
	in_shell = FALSE
	C.visible_message("<span class='notice'>[C] emerges from [C.p_their()] shell.[prob(1) ? " Not socially or emotionally, though." : ""]</span>")
	if(my_shell)
		if(C.loc == my_shell)
			C.forceMove(get_turf(my_shell))
		my_shell.moveToNullspace()

/datum/species/snail/proc/enter_shell(mob/living/carbon/C)
	if(in_shell)
		return
	in_shell = TRUE
	C.visible_message("<span class='notice'>[C] enters [C.p_their()] shell.</span>")
	if(!my_shell)
		my_shell = new /obj/structure/snail_shell(get_turf(C))
	else
		my_shell.forceMove(get_turf(C))
	my_shell.icon_state = C.dna.features["snail_shell"]
	C.forceMove(my_shell)

/datum/action/innate/toggle_shell
	name = "Enter Shell"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "slimeheal"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_alien"

/datum/action/innate/toggle_shell/IsAvailable()
	var/mob/living/carbon/human/H = owner
	var/datum/species/snail/spec = H.dna.species
	if(..() && (spec.shell_health > 0))
		return TRUE
	return FALSE

/datum/action/innate/toggle_shell/Activate()
	var/mob/living/carbon/human/H = owner
	var/datum/species/snail/spec = H.dna.species
	spec.toggle_shell(H)

/obj/structure/snail_shell
	name = "Snail Shell"
	desc = "Someone is probably hiding inside it."
	icon = 'yogstation/icons/mob/shells.dmi'

/obj/structure/snail_shell/get_remote_view_fullscreens(mob/user)
	if(!(user.sight & (SEEOBJS|SEEMOBS)))
		user.overlay_fullscreen("remote_view", /obj/screen/fullscreen/impaired, 1)

/obj/structure/snail_shell/relaymove(mob/user)
	return
