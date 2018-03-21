#!/bin/bash

# Update default route on eth0
#echo "Reconfiguring routing table.." && echo "$(route)"
#route del default eth0
#route add -net 10.0.0.0 netmask 255.0.0.0 dev eth0
#route add default gw 10.0.0.254 netmask 255.0.0.0 dev eth0
#echo "Routing table now looks like " && echo "$(route)"

# Allow cowrie to listen as non-root on ports 22 and 23
touch /etc/authbind/byport/22 && \
    touch /etc/authbind/byport/23 && \
    chown cowrie:cowrie /etc/authbind/byport/22 && \
    chown cowrie:cowrie /etc/authbind/byport/23 && \
    chmod 777 /etc/authbind/byport/22 && \
    chmod 777 /etc/authbind/byport/23
sed -i 's/AUTHBIND_ENABLED=no/AUTHBIND_ENABLED=yes/' /cowrie/cowrie-git/bin/cowrie

## Start the cowrie service
su - cowrie -c "/cowrie/cowrie-git/bin/cowrie start -n"