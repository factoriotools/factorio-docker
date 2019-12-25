#! /bin/bash




# Template String
# Default Value
# ENvironment Variable String
updateTemplate () {
	#get the value from the environment varaible and put it in val
	val=${!3}

	#Test if there was a value that was set.
	if [ -z "$val" ]
	then
		#replace the value in the template file with the default value
		sed -i 's/$1/$2/g' $TEMPLATE_FILE
	else
		#Replace the value in the template file with the value in the environment Variable
		sed -i 's/$1/$val/g' $TEMPLATE_FILE
	fi
	
}

# Template String
# Default Value
# ENvironment Variable String
updateTemplateBool (){
	#get the value from the environment varaible and put it in val
	val=${!3}
	#Test if there was a value that was set to true or false
	if [[ ${val} =~ ^(true)|(false)$ ]]
	then
		#replace the value in the template file with the argument
		sed -i 's/$1/$val/g' $TEMPLATE_FILE
	else
		#Replace the value in the template file with the default
		sed -i 's/$1/$2/g' $TEMPLATE_FILE
	fi
}

# Template String
# Default Value
# ENvironment Variable String
updateTemplateNumber (){
	#get the value from the environment varaible and put it in val
	val=${!3}
	#Test if there was a value that was set to true or false
	if [[ ${val} =~ ^[0-9]+$ ]]
	then
		#replace the value in the template file with the argument
		sed -i 's/$1/$val/g' $TEMPLATE_FILE
	else
		#Replace the value in the template file with the default
		sed -i 's/$1/$2/g' $TEMPLATE_FILE
	fi
}

# Template String
# ENvironment Variable String
updateTemplateEmptyDefault(){
	#get the value from the environment varaible and put it in val
	val=${!2}

	#Test if there was a value that was set.
	if [ -z "$val" ]
	then
		#replace the value in the template file with the default value
		sed -i 's/$1//g' $TEMPLATE_FILE
	else
		#Replace the value in the template file with the value in the environment Variable
		sed -i 's/$1/$val/g' $TEMPLATE_FILE
	fi
}

mapSettings () {
	echo Creating map generation settings file
	TEMPLATE_FILE=map-settings-template.json
	
}


mapGenSettings () {
	echo Creating map settings file
	TEMPLATE_FILE=map-gen-settings-template.json
}


serverSettings(){
	echo Creating server settings file
	TEMPLATE_FILE=server-settings-template.json
	updateTemplate templateServerName "my-server" TEMPLATE_SERVER_NAME
	updateTemplate templateServerDescription "my-server" TEMPLATE_SERVER_DESCRIPTION
	updateTemplate templateServerTage '"kubernetes","docker"' TEMPLATE_SERVER_TAGS
	updateTemplateNumber templateServerMaxPlayers 0 TEMPLATE_SERVER_MAX_PLAYERS
	updateTemplateBool templateServerPulicVisibility true TEMPLATE_SERVER_PUBLIC_VISIBILITY
	updateTemplateBool templateServerLanVisibility true TEMPLATE_SERVER_LAN_VISIBILITY
	updateTemplateEmptyDefault templateServerUsername TEMPLATE_SERVER_USERNAME
	updateTemplateEmptyDefault templateServerPassword TEMPLATE_SERVER_PASSWORD
	updateTemplateEmptyDefault templateServerGameToken TEMPLATE_SERVER_TOKEN
	updateTemplate templateServerGamePassword "password" TEMPLATE_SERVER_GAME_PASSWORD
	updateTemplateBool templateServerRequireUserVerification true TEMPLATE_SERVER_REQUIRE_USER_VERIFICATION
	updateTemplateNumber templateServerMaxUpload 0 TEMPLATE_SERVER_MAX_UPLOAD
	updateTemplateNumber templateServerMaxUploadSlots 5 TEMPLATE_SERVER_MAX_UPLOAD_SLOTS
	updateTemplateNumber templateServerMinimumLatenctInTicks 0 TEMPLATE_SERVER_MIN_LATENCY_TICKS
	updateTemplateBool templateServerIgnorePlayerLimitForReturningPlayers false TEMPLATE_SERVER_IGNORE_LIMIT_FOR_RETURNING
	updateTemplate templateServerAllowCommands "admins-only" TEMPLATE_SERVER_ALLOW_COMMANDS
	updateTemplateNumber templateServerAutosaveInterval 5 TEMPLATE_SERVER_AUTOSAVE_INTERVAL
	updateTemplateNumber templateServerAutosaveSlots 3 TEMPLATE_SERVER_AUTOSAVE_SLOTS
	updateTemplateNumber templateServerAFKAutokickInterval 0 TEMPLATE_SERVER_AFK_KICK_INTERVAL
	updateTemplateBool templateServerAutoPause true TEMPLATE_SERVER_AUTOPAUSE
	updateTemplateBool templateServerOnlyAdminsPause true TEMPLATE_SERVER_ADMIN_ONLY_PAUSE
	updateTemplateBool templateServerAutosaveOnlyOnServer true TEMPLATE_SERVER_SERVER_ONLY_AUTOSAVE
	updateTemplateBool templateServerNonblockingSaving false TEMPLATE_SERVER_NONBLOCKING_SAVE
	updateTemplateNumber templateServerMinSegmentSize 25 TEMPLATE_SERVER_MIN_SEGMENT_SIZE
	updateTemplateNumber templateServerMinSegmentSizePeer 20 TEMPLATE_SERVER_MIN_SEGMENT_SIZE_PEER
	updateTemplateNumber templateServerMaxSegmentSize 100 TEMPLATE_SERVER_MAX_SEGMENT_SIZE
	updateTemplateNumber templateServerMaxSegmentSizePeer 10 TEMPLATE_SERVER_MAX_SEGMENT_SIZE_PEER
}


mapSettings
mapGenSettings
serverSettings


