#!/usr/local/bin/bash

poudriere ports -p myports -u && \
        poudriere bulk -j ourjail -p myports \
                -f /usr/local/etc/poudriere.d/pkglist && \
