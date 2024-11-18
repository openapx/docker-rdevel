#! /bin/bash


# utility script to install Posit Workbench 
#
#  install-workbench.sh [url]
#
#  <url>               The URL to install
#
#
#  note: uses ID in /etc/os-release to determine distribution and subsequent commands
#

# -- some defaults
CMD_INSTALL=


# -- process arguments

XURL=${1}

if [ -z ${XURL} ]; then
  echo "Posit Workbench download URL not specified "
  exit 1
fi

# -- end of process arguments


# -- get OS branch

OS_RELEASE=$( grep -i "^id=" /etc/os-release | awk -F '=' '{print $2}' | xargs )

# -- define some basic commands based on OS

case ${OS_RELEASE} in
   ubuntu | debian)

      ;;
    
   fedora | rocky)
      CMD_INSTALL="dnf install --assumeyes"
      ;;

    *)
      echo "Operating system ${OS_RELEASE} not supported"
      exit 1
      ;;
esac



# -- set up install environment
echo "-- set up script scaffolding"
mkdir -p /sources/rdevworkbench


# -- download Posit workbench (Open Source license)
echo "-- downloading ${XURL}" 
wget --quiet -P /sources/rdevworkbench ${XURL}

XSOURCE=/sources/rdevworkbench/$(basename ${XURL})

_MD5=($(md5sum ${XSOURCE}))
_SHA256=($(sha256sum ${XSOURCE}))

echo "   $(basename ${XSOURCE}) (MD5 ${_MD5} / SHA-256 ${_SHA256})"

unset _MD5
unset _SHA256




# -- install the server

case ${OS_RELEASE} in
   ubuntu | debian)

      # quick install of gdebi-core
      echo "-- pre-install setup"
      apt-get install --assume-yes --no-install-recommends --quiet gdebi-core

      echo "-- installing Posit Workbench $(basename ${XSOURCE})"
      gdebi --non-interactive ${XSOURCE}


      # stop workbench service ... if it was already started
      echo "-- stopping rstudio-server service (if automatically started)"
      service rstudio-server stop

      # quick uninstall of gdebi-core
      # note: known dirty as gdebi dependencies are left 
      echo "-- post-install"
      apt-get remove --assume-yes --quiet gdebi-core

      ;;
    
   fedora | rocky)

      echo "-- installing Posit Workbench $(basename ${XSOURCE})"
      dnf install --assumeyes ${XSOURCE}

      ;;

    *)
      echo "Operating system ${OS_RELEASE} not supported"
      exit 1
      ;;
esac

# -- end of install




# -- end of install Open Source verison of Posit/R-Studio Workbench



# R version for use with Posit/workbench R-Studio 
# Open Source version of Posit/R-Studio Workbench only supports
# one version of R 

# note: poor man sort to select the latest version
WORKBENCH_R=$(ls /opt/R | grep "^[0-9].[0-9].[0-9]$" | sort -r | head -n1)

# set up symbolic link as for selected R version
ln -s /opt/R/${WORKBENCH_R} /opt/R/posit-workbench

echo "-- Posit/R-Studio Workbench defaults to R version ${WORKBENCH_R}"


# -- rserver.conf updates
echo "-- Configuring Posit/R-Studio Workbench defaults"

# comment pointer to R if it exists ... not really tested
sed -e '/rsession-which-r/ s/^#*/#/' -i /etc/rstudio/rserver.conf

# add configuration
cat <<EOT >> /etc/rstudio/rserver.conf
# --- openapx configuration -------------------------------------------

# -- adding pointer to R version
rsession-which-r=/opt/R/posit-workbench/bin/R

# -- do not run Workbench server as a background deamon
server-daemonize=0

# --- end of openapx configuration ------------------------------------
EOT

# -- end of rserver.conf updates



# create R workbench user group
echo "-- Configuring Posit/R-Studio Workbench groups"
groupadd rworkbench


# -- clean-up
echo "-- Clean up"
rm -Rf /sources

