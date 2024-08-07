#!/bin/bash

set -x

echo 602 >> /tmp/pear_update.log

rm -f /etc/init.d/pear_init
rm -f /etc/rc3.d/S14pear_init
rm -f /etc/rc5.d/S14pear_init
rm -f /etc/rcS.d/K14pear_init

exit 0
