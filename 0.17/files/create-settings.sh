#! /bin/bash




# updateTemplate
# Template String
# Default Value
# New Value
# 
updateTemplate () {
	echo Template Value $1
	echo Default Value $2
	echo Environment Variable $3
	echo file $TEMPLATE_FILE

	val=${!3}
	echo val: $val

	if [ -z "$val" ]
	then
		echo "\$val is empty"
		sed -i 's/$1/$2/g' $TEMPLATE_FILE
		echo replacing $1 with default $2 
	else
		echo "\$val is NOT empty"
		echo replacing $1 with $val
		sed -i 's/$1/$val/g' $TEMPLATE_FILE
	fi
	
}
ENVIRONMENT_VAL=123
TEMPLATE_FILE=map-settings-template.json
updateTemplate template default ENVIRONMENT_VAL2