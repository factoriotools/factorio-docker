# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    aws s3 cp /factorio $STORAGE --recursive
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

trap 'kill ${!}; term_handler' SIGTERM

# Load last saved game state
aws s3 cp $STORAGE /factorio --recursive

# run application
./docker-entrypoint.sh &
pid="$!"

# save game state every five minutes
while true
do
  aws s3 cp /factorio $STORAGE --recursive
  sleep $AUTOSAVE_RATE
done
