#! /bin/bash

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
	if [[ ${val} =~ ^[0-9]+$ ]]
	then
		#replace the value in the template file with the argument
		sed -i "s/$1/$val/g" "$TEMPLATE_FILE"
	else
		#Replace the value in the template file with the default
		sed -i "s/$1/$3/g" "$TEMPLATE_FILE"
	fi
}

# updateTemplateEmptyDefault 
#
# replaces the template string with either an empty string, or 
# the value in the passed in environment variable.
#
# $1 Template String: The value that is replaced in the template.
# $2 Environment Variable String: the environment variable that is checked for a value
updateTemplateEmptyDefault(){
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
	
}

#Using the template, generate a map-gen-settings.json file
mapGenSettings () {
	echo Creating map settings file
	TEMPLATE_FILE=map-gen-settings-template.json
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
	updateTemplateEmptyDefault	templateServerUsername					TEMPLATE_SERVER_USERNAME 
	updateTemplateEmptyDefault	templateServerPassword					TEMPLATE_SERVER_PASSWORD
	updateTemplateEmptyDefault	templateServerGameToken					TEMPLATE_SERVER_TOKEN
	updateTemplateEmptyDefault	templateServerGamePassword				TEMPLATE_SERVER_GAME_PASSWORD
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

#call the functions to generate the files from the templates.
mapSettings
mapGenSettings
serverSettings
