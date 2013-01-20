#!/bin/bash

### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the unicorn web server
# Description:       starts unicorn
### END INIT INFO

# Add to auto-start on server start
# sudo update-rc.d unicorn_com.summercode.wiki defaults
# Remove from auto-start
# sudo update-rc.d -f unicorn_com.summercode.wiki remove

RVM_ENV="ruby-1.9.3-p362@git-wiki"
APP_NAME="com.summercode.wiki"
APP_PATH="/var/www/$APP_NAME"
EUSER="cr0t"

source /usr/local/rvm/environments/$RVM_ENV

CMD="cd $APP_PATH/current && bundle exec unicorn"
CMD_OPTS="-c $APP_PATH/current/config/unicorn.rb -E production -D"
PID="$APP_PATH/shared/pids/unicorn.pid"

NAME=`basename $0`
DESC="Unicorn app for $APP_NAME"

case "$1" in
  start)
    echo -n "Starting $DESC: "
    su - $EUSER -c "$CMD $CMD_OPTS"
    echo "$NAME."
  ;;

  stop)
    echo -n "Stopping $DESC: "
    if [ -f $PID ] && [ -e /proc/$(cat $PID) ]
    then
      kill -QUIT `cat $PID`
      echo "$NAME."
    else
      echo "Unable to get $PID file, or process is down"
    fi
  ;;

  restart)
    echo -n "Restarting $DESC: "
    if [ -f $PID ] && [ -e /proc/$(cat $PID) ]
    then
      kill -USR2 `cat $PID`
    else
      su - $EUSER -c "$CMD $CMD_OPTS"
    fi
    echo "$NAME."
  ;;

  *)
    echo "Usage: $NAME {start|stop|restart}" >&2
    exit 1
  ;;
esac

exit 0
