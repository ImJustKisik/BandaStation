/**
 * Contains the subsystem controller for managing fission reactors.
 */

/datum/controller/subsystem/fission
	name = "Fission"
	init_stage = INITSTAGE_MAIN
	ss_flags = SS_NO_INIT_LOG | SS_KEEP_FOR_REBOOT

	var/list/active_reactors = list()

	var/list/active_coolant_channels = list()

/datum/controller/subsystem/fission/Initialize(timeofday)
	SS_INIT_LOG_INFO("Initializing fission subsystem.")
	..()
	return INITIALIZE_HINT_NORMAL

/datum/controller/subsystem/fission/proc/register_reactor(obj/machinery/power/fission/core/reactor)
	if(!istype(reactor))
		return
	if(reactor in active_reactors)
		return

	active_reactors += reactor
	for(var/obj/machinery/atmospherics/pipe/simple/fuel_channel/FC in reactor.fuel_assemblies)
		active_coolant_channels += FC

	if(!processing.len)
		begin_processing()

/datum/controller/subsystem/fission/proc/unregister_reactor(obj/machinery/power/fission/core/reactor)
	if(!istype(reactor))
		return
	if(!(reactor in active_reactors))
		return

	active_reactors -= reactor
	for(var/obj/machinery/atmospherics/pipe/simple/fuel_channel/FC in reactor.fuel_assemblies)
		active_coolant_channels -= FC

	if(!active_reactors.len)
		end_processing()

/datum/controller/subsystem/fission/process(delta_time)
	for(var/obj/machinery/power/fission/core/R in active_reactors)
		R.process_reaction(delta_time)

	for(var/obj/machinery/atmospherics/pipe/simple/fuel_channel/FC in active_coolant_channels)
		FC.process()
