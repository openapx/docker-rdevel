#! /bin/bash
#
# create a local workbench user
#
# usage:
#   rworkbench_adduser.sh <user>


# -- get user name 
USR=${1}

# -- verify user does not exist
if [ -n "$(grep \"^${USR}:\" /etc/passwd)" ]; then
  echo "User ${USR} exists"
  exit 0
fi


# -- create user
echo "-- Creating user ${USR}"
useradd -m ${USR}

echo "   Adding user to rworkbench group"
usermod --append --groups rworkbench ${USR}


# looks complicated ... but pull the home directory fom /etc/passwd
USRHOME=$(grep "^${USR}\:" /etc/passwd | awk -F: '{print $6}')


# -- configure user settings
echo "-- Configuring ${USR} defaults"

# Enable defauls Workbench profile
# note: inspired by rocker 
echo "   Enable default Posit/R-Studio Workbench profile"

mkdir -p ${USRHOME}/.config/rstudio

cat<<EOT > "${USRHOME}/.config/rstudio/rstudio-prefs.json"
{
    "load_workspace": false,
    "save_workspace": "never",
    "always_save_history": false,
    "reuse_sessions_for_project_links": false,
    "posix_terminal_shell": "bash",
    "initial_working_directory": "~"
}
EOT

chmod u+rw-x,g+rw-x,o-rwx ${USRHOME}/.config/rstudio/rstudio-prefs.json
find ${USRHOME}/.config -type d -user root -exec chmod -R u+rwx,g+rwx,o-rwx {} \;

# ensure everything is owned by user
echo "   Assign ownership of everything home to user"
chown -R ${USR}:${USR} ${USRHOME}


# -- prompt to set password
echo "-- Set initial password"
passwd ${USR}





