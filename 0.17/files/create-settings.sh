#!/bin/bash

# updateTemplate 
#
# replaces the template string with either the default, or 
# the value in the passed in environment variable.
#
# $1 Template String: The value that is replaced in the template.
# $2 Environment Variable String: the environment variable that is checked for a value.
# $3 Default Value: The default value used if the environment variable is empty or invalid.
updateTemplate () {
	#get the value from the environment varaible and put it in val
	val=${!2}
	#Test if there was a value that was set.
	if [[ -z "$val" ]]
	then
		#replace the value in the template file with the default value
		sed -i "s/$1/$3/g" "$TEMPLATE_FILE"
	else
		#Replace the value in the template file with the value in the environment Variable
		sed -i "s/$1/$val/g" "$TEMPLATE_FILE"
	fi
	
}

# updateTemplateBool 
#
# replaces the template string with either the default, or 
# the value in the passed in environment variable.
# if the value in the variable is not 'true' or 'false', the default is used.
#
# $1 Template String: The value that is replaced in the template.
# $2 Environment Variable String: the environment variable that is checked for a value.
# $3 Default Value: The default value used if the environment variable is empty or invalid.
updateTemplateBool (){
	#get the value from the environment varaible and put it in val
	val=${!2}
	#Test if there was a value that was set to true or false
	if [[ ${val} =~ ^(true)|(false)$ ]]
	then
		#replace the value in the template file with the argument
		sed -i "s/$1/$val/g" "$TEMPLATE_FILE"
	else
		#Replace the value in the template file with the default
		sed -i "s/$1/$3/g" "$TEMPLATE_FILE"
	fi
}

# updateTemplateNumber 
#
# replaces the template string with either the default, or 
# the value in the passed in environment variable.
# if the value in the variable is not anumber, the default is used.
#
# $1 Template String: The value that is replaced in the template.
# $2 Environment Variable String: the environment variable that is checked for a value.
# $3 Default Value: The default value used if the environment variable is empty or invalid.
updateTemplateNumber (){
	#get the value from the environment varaible and put it in val
	val=${!2}
	#Test if there was a value that was set to true or false
	if [[ ${val} =~ ^[0-9]+\.?[0-9]*$ ]]
	then
		#replace the value in the template file with the argument
		sed -i "s/$1/$val/g" "$TEMPLATE_FILE"
	else
		#Replace the value in the template file with the default
		sed -i "s/$1/$3/g" "$TEMPLATE_FILE"
	fi
}

# updateTemplateEmpty
#
# replaces the template string with either an empty string, or 
# the value in the passed in environment variable.
#
# $1 Template String: The value that is replaced in the template.
# $2 Environment Variable String: the environment variable that is checked for a value
updateTemplateEmpty(){
	#get the value from the environment varaible and put it in val
	val=${!2}

	#Test if there was a value that was set.
	if [[ -z "$val" ]]
	then
		#replace the value in the template file with the default value
		sed -i "s/$1//g" "$TEMPLATE_FILE"
	else
		#Replace the value in the template file with the value in the environment Variable
		sed -i "s/$1/$val/g" "$TEMPLATE_FILE"
	fi
}

#Using the template, generate a map-settings.json file
mapSettings () {
	echo Creating map generation settings file
	TEMPLATE_FILE=map-settings-template.json
	
	updateTemplateNumber	templateMapDifficultyRecipe					TEMPLATE_MAP_DIFFICULTY_RECIPE						0
	updateTemplateNumber	templateMapDifficultyTechnology				TEMPLATE_MAP_DIFFICULTY_TECHNOLOGY					0
	updateTemplateNumber	templateMapDifficultyTechPrice				TEMPLATE_MAP_DIFFICULTY_TECH_PRICE					1
	updateTemplate			templateMapDifficultyResearchQueue			TEMPLATE_MAP_DIFFICULTY_RESEARCH_QUEUE				"after-victory"
	updateTemplateBool		templateMapPollutionEnabled					TEMPLATE_MAP_POLLUTION_ENABLED						true
	updateTemplateNumber	templateMapPollutionDiffusionRatio			TEMPLATE_MAP_POLLUTION_DIFFUSION_RATIO				0.02
	updateTemplateNumber	templateMapPollutionMinToDefuse				TEMPLATE_MAP_POLLUTION_MIN_TO_DEFUSE				15
	updateTemplateNumber	templateMapPollutionAgeing					TEMPLATE_MAP_POLLUTION_AGEING						1
	updateTemplateNumber	templateMapPollutionExpectedMaxPerChunk		TEMPLATE_MAP_POLLUTION_EXPECTED_MAX_PER_CHUNK		150
	updateTemplateNumber	templateMapPollutionMinToShowPerChunk		TEMPLATE_MAP_POLLUTION_MIN_TO_SHOW_PER_CHUNK		50
	updateTemplateNumber	templateMapPollutionMinToDamageTrees		TEMPLATE_MAP_POLLUTION_MIN_TO_DAMAGE_TREES			60
	updateTemplateNumber	templateMapPollutionMaxForestDamage			TEMPLATE_MAP_POLLUTION_MAX_FOREST_DAMMAGE			150
	updateTemplateNumber	templateMapPollutionPerTreeDamage			TEMPLATE_MAP_POLLUTION_PER_TREE_DAMAGE				50
	updateTemplateNumber	templateMapPollutionRestoredPerTreeDamage	TEMPLATE_MAP_POLLUTION_RESTORED_PER_TREE_DAMAGE		10
	updateTemplateNumber	templateMapPollutionMaxToRestoreTrees		TEMPLATE_MAP_POLLUTION_MAX_TO_RESTORE_TREES			20
	updateTemplateNumber	templateMapPollutionBiterAttackModifier		TEMPLATE_MAP_POLLUTION_BITER_ATTACK_MODIFIER		1
	updateTemplateBool		templateMapEvolutionEnabled					TEMPLATE_MAP_EVOLUTION_ENABLED						true
	updateTemplateNumber	templateMapEvolutionTimeFactor				TEMPLATE_MAP_EVOLUTION_TIME_FACTOR					0.000004
	updateTemplateNumber	templateMapEvolutionDestroyFactor			TEMPLATE_MAP_EVOLUTION_DESTROY_FACTOR				0.002
	updateTemplateNumber	templateMapEvolutionPollutionFactor			TEMPLATE_MAP_EVOLUTION_POLLUTION_FACTOR				0.0000009
	updateTemplateBool		templateMapExpansionEnabled					TEMPLATE_MAP_EXPANSION_ENABLED						true
	updateTemplateNumber	templateMapExpansionMinBaseSpacing			TEMPLATE_MAP_EXPANSION_MIN_BASE_SPACING				3
	updateTemplateNumber	templateMapExpansionMaxExpansionDistance	TEMPLATE_MAP_EXPANSION_MAX_EXPANSION_DISTANCE		7
	updateTemplateNumber	templateMapExpansionFriendlyBaseRadius		TEMPLATE_MAP_EXPANSION_FRIENDLY_BASE_RADIUS			2
	updateTemplateNumber	templateMapExpansionBiterBaseRadius			TEMPLATE_MAP_EXPANSION_BITER_BASE_RADIUS			2
	updateTemplateNumber	templateMapExpansionBuildingCff				TEMPLATE_MAP_EXPANSION_BUILDING_CFF					0.1
	updateTemplateNumber	templateMapExpansionOtherBaseCff			TEMPLATE_MAP_EXPANSION_OTHER_BASE_CFF				2.0
	updateTemplateNumber	templateMapExpansionNeighbourChunkCff		TEMPLATE_MAP_EXPANSION_NEIGHBOUR_CHUNK_CFF			0.5
	updateTemplateNumber	templateMapExpansionNeighbourBaseChunkCff	TEMPLATE_MAP_EXPANSION_NEIGHBOUR_BASE_CHUNK_CFF		0.4
	updateTemplateNumber	templateMapExpansionMaxCollidingTilesCff	TEMPLATE_MAP_EXPANSION_MAX_COLLIDING_TILES_CFF		0.9
	updateTemplateNumber	templateMapExpansionSettlerGroupMin			TEMPLATE_MAP_EXPANSION_SETTLER_GROUP_MIN			5
	updateTemplateNumber	templateMapExpansionSettlerGroupMax			TEMPLATE_MAP_EXPANSION_SETTLER_GROUP_MAX			20
	updateTemplateNumber	templateMapExpansionMinCooldown				TEMPLATE_MAP_EXPANSION_MIN_COOLDOWN					14400
	updateTemplateNumber	templateMapExpansionMaxCooldown				TEMPLATE_MAP_EXPANSION_MAX_COOLDOWN					216000

	#unit_group, Steering, Path_finder, and max_failed_behavior_count settings not included at this time
	#as they are likely very optimized by the developers;

}

#Using the template, generate a map-gen-settings.json file
mapGenSettings () {
	echo Creating map settings file
	TEMPLATE_FILE=map-gen-settings-template.json

	updateTemplateNumber	templateGenTerrainSegmentation		TEMPLATE_GEN_TERRAIN_SEGMENTATION		1
	updateTemplateNumber	templateGenTerrainWater				TEMPLATE_GEN_TERRAIN_WATER				1
	updateTemplateNumber	templateGenMapWidth					TEMPLATE_GEN_MAP_WIDTH					0
	updateTemplateNumber	templateGenMapHeight				TEMPLATE_GEN_MAP_HEIGHT					0
	updateTemplateNumber	templateGenMapStartingArea			TEMPLATE_GEN_MAP_STARTING_AREA			1
	updateTemplateBool		templateGenPeacefullMode			TEMPLATE_GEN_PEACEFULL_MODE				false
	#coal
	updateTemplateNumber	templateGenCoalRichness				TEMPLATE_GEN_COAL_RICHNESS				1
	updateTemplateNumber	templateGenCoalSize					TEMPLATE_GEN_COAL_SIZE					1
	updateTemplateNumber	templateGenCoalFrequency			TEMPLATE_GEN_COAL_FREQUENCY				1
	#stone
	updateTemplateNumber	templateGenStoneRichness			TEMPLATE_GEN_STONE_RICHNESS				1
	updateTemplateNumber	templateGenStoneSize				TEMPLATE_GEN_STONE_SIZE					1
	updateTemplateNumber	templateGenStoneFrequency			TEMPLATE_GEN_STONE_FREQUENCY			1
	#Copper
	updateTemplateNumber	templateGenCopperRichness			TEMPLATE_GEN_COPPER_RICHNESS			1
	updateTemplateNumber	templateGenCopperSize				TEMPLATE_GEN_COPPER_SIZE				1
	updateTemplateNumber	templateGenCopperFrequency			TEMPLATE_GEN_COPPER_FREQUENCY			1
	#Iron
	updateTemplateNumber	templateGenIronRichness				TEMPLATE_GEN_IRON_RICHNESS				1
	updateTemplateNumber	templateGenIronSize					TEMPLATE_GEN_IRON_SIZE					1
	updateTemplateNumber	templateGenIronFrequency			TEMPLATE_GEN_IRON_FREQUENCY				1
	#Uranium
	updateTemplateNumber	templateGenUraniumRichness			TEMPLATE_GEN_URANIUM_RICHNESS			1
	updateTemplateNumber	templateGenUraniumSize				TEMPLATE_GEN_URANIUM_SIZE				1
	updateTemplateNumber	templateGenUraniumFrequency			TEMPLATE_GEN_URANIUM_FREQUENCY			1
	#Crude
	updateTemplateNumber	templateGenCrudeRichness			TEMPLATE_GEN_CRUDE_RICHNESS				1
	updateTemplateNumber	templateGenCrudeSize				TEMPLATE_GEN_CRUDE_SIZE					1
	updateTemplateNumber	templateGenCrudeFrequency			TEMPLATE_GEN_CRUDE_FREQUENCY			1
	#Trees
	updateTemplateNumber	templateGenTreesRichness			TEMPLATE_GEN_TREES_RICHNESS				1
	updateTemplateNumber	templateGenTreesSize				TEMPLATE_GEN_TREES_SIZE					1
	updateTemplateNumber	templateGenTreesFrequency			TEMPLATE_GEN_TREES_FREQUENCY			1
	#Biters
	updateTemplateNumber	templateGenBiterRichness			TEMPLATE_GEN_BITER_RICHNESS				1
	updateTemplateNumber	templateGenBiterSize				TEMPLATE_GEN_BITER_SIZE					1
	updateTemplateNumber	templateGenBiterFrequency			TEMPLATE_GEN_BITER_FREQUENCY			1
	#cliffs
	updateTemplate			templateGenCliffName				TEMPLATE_GEN_CLIFF_NAME					"cliff"
	updateTemplateNumber	templateGenCliffElevationZero		TEMPLATE_GEN_CLIFF_ELEVATION_ZERO		10
	updateTemplateNumber	templateGenCliffElevationInterval	TEMPLATE_GEN_CLIFF_ELEVATION_INTERVAL	10
	updateTemplateNumber	templateGenCliffRichness			TEMPLATE_GEN_CLIFF_RICHNESS				1
	#expression Names
	updateTemplate			templateGenExpressionElevation		TEMPLATE_GEN_EXPRESSION_ELEVATION		"0_17-island"
	updateTemplateNumber	templateGenAuxBias					TEMPLATE_GEN_AUX_BIAS					"0.300000"
	updateTemplateNumber	templateGenAuxMultiplier			TEMPLATE_GEN_AUX_MULTIPLIER				"1.333333"
	updateTemplateNumber	templateGenMoistureBias				TEMPLATE_GEN_MOISTURE_BIAS				"0.100000"
	updateTemplateNumber	templateGenMoistureMultiplier		TEMPLATE_GEN_MOISTURE_MULTIPLIER		"0.500000"
	#Starting Point
	updateTemplateNumber	templateGenStartingPointX			TEMPLATE_GEN_STARTING_POINT_X			1000
	updateTemplateNumber	templateGenStartingPointY			TEMPLATE_GEN_STARTING_POINT_Y			2000
	#seed
	updateTemplateNumber	templateGenMapSeed					TEMPLATE_GEN_MAP_SEED					null
}

#Using the template, generate a server-settings.json file.
serverSettings(){
	echo Creating server settings file
	TEMPLATE_FILE=server-settings-template.json

	updateTemplate				templateServerName						TEMPLATE_SERVER_NAME						"my-server"
	updateTemplate				templateServerDescription				TEMPLATE_SERVER_DESCRIPTION					"my-server"
	updateTemplate				templateServerTags						TEMPLATE_SERVER_TAGS						'"kubernetes","docker"'
	updateTemplateNumber		templateServerMaxPlayers				TEMPLATE_SERVER_MAX_PLAYERS					0
	updateTemplateBool			templateServerPulicVisibility			TEMPLATE_SERVER_PUBLIC_VISIBILITY			true
	updateTemplateBool			templateServerLanVisibility				TEMPLATE_SERVER_LAN_VISIBILITY				true
	updateTemplateEmpty			templateServerUsername					TEMPLATE_SERVER_USERNAME 
	updateTemplateEmpty			templateServerPassword					TEMPLATE_SERVER_PASSWORD
	updateTemplateEmpty			templateServerGameToken					TEMPLATE_SERVER_TOKEN
	updateTemplateEmpty			templateServerGamePassword				TEMPLATE_SERVER_GAME_PASSWORD
	updateTemplateBool			templateServerRequireUserVerification	TEMPLATE_SERVER_REQUIRE_USER_VERIFICATION	true
	updateTemplateNumber		templateServerMaxUploadCount			TEMPLATE_SERVER_MAX_UPLOAD					0
	updateTemplateNumber		templateServerMaxUploadSlots			TEMPLATE_SERVER_MAX_UPLOAD_SLOTS			5
	updateTemplateNumber		templateServerMinimumLatenctInTicks		TEMPLATE_SERVER_MIN_LATENCY_TICKS			0
	updateTemplateBool			templateServerIgnoreLimitForReturning	TEMPLATE_SERVER_IGNORE_LIMIT_FOR_RETURNING	false
	updateTemplate				templateServerAllowCommands				TEMPLATE_SERVER_ALLOW_COMMANDS				"admins-only"
	updateTemplateNumber		templateServerAutosaveInterval			TEMPLATE_SERVER_AUTOSAVE_INTERVAL			5
	updateTemplateNumber		templateServerAutosaveSlots				TEMPLATE_SERVER_AUTOSAVE_SLOTS				3
	updateTemplateNumber		templateServerAFKAutokickInterval		TEMPLATE_SERVER_AFK_KICK_INTERVAL			0
	updateTemplateBool			templateServerAutoPause					TEMPLATE_SERVER_AUTOPAUSE					true
	updateTemplateBool			templateServerOnlyAdminsPause			TEMPLATE_SERVER_ADMIN_ONLY_PAUSE			true
	updateTemplateBool			templateServerAutosaveOnlyOnServer		TEMPLATE_SERVER_SERVER_ONLY_AUTOSAVE		true
	updateTemplateBool			templateServerNonblockingSaving			TEMPLATE_SERVER_NONBLOCKING_SAVE			false
	updateTemplateNumber		templateServerMinSegmentSizeCount		TEMPLATE_SERVER_MIN_SEGMENT_SIZE			25
	updateTemplateNumber		templateServerMinSegmentSizePeer		TEMPLATE_SERVER_MIN_SEGMENT_SIZE_PEER		20
	updateTemplateNumber		templateServerMaxSegmentSizeCount		TEMPLATE_SERVER_MAX_SEGMENT_SIZE			100
	updateTemplateNumber		templateServerMaxSegmentSizePeer		TEMPLATE_SERVER_MAX_SEGMENT_SIZE_PEER		10
}


#call the functions to generate and copy the files from the templates.
if [[ ! -f $CONFIG/server-settings.json ]]; then
	# Copy default settings if server-settings.json doesn't exist
	serverSettings
	cp ./server-settings-template.json "$CONFIG/server-settings.json"
fi

if [[ ! -f $CONFIG/map-gen-settings.json ]]; then
	mapGenSettings
	cp ./map-gen-settings-template.json "$CONFIG/map-gen-settings.json"
fi

if [[ ! -f $CONFIG/map-settings.json ]]; then
	mapSettings
	cp ./map-settings-template.json "$CONFIG/map-settings.json"
fi




