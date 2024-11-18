#! /bin/bash

# -- container service entrypoint script


# -- start workbench service
# note: this should be the last command submitted 
# note: service is not used as container needs to have a forground process
# note: all config in /etc/rstudio/rserver.conf and /etc/rstudio/rsession.conf
# note: no command line args used
/usr/lib/rstudio-server/bin/rserver
