#!/bin/sh
CONF=/etc/config/qpkg.conf
QPKG_NAME="Lucky"
QPKG_ROOT=`/sbin/getcfg $QPKG_NAME Install_Path -f ${CONF}`

case "$1" in
  start)
    ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
    if [ "$ENABLED" != "TRUE" ]; then
        echo "$QPKG_NAME 已禁用"
        exit 1
    fi

  /bin/ln -sf $QPKG_ROOT /opt/$QPKG_NAME

  /bin/chmod -Rf 777 $QPKG_ROOT/*
  cd $QPKG_ROOT
  ./lucky -c /opt/Lucky/lucky.conf &
    ;;

  stop)

	killall -9 lucky

  rm -rf /opt/$QPKG_NAME

	;;

  restart)

    $0 stop
    $0 start
 
	;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
