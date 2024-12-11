#! /bin/bash


# -- set up directory structures
echo "-- setting up script scaffolding"
mkdir -p /sources /scripts /logs/R/rdevworkbench


# -- general configuration
CRAN_REPO=https://cloud.r-project.org



# -- update for each R version

# note: not writing content to the R version install directory
# note: all configs under /opt/R/config for now

for R_VERSION in $( ls /opt/R | grep "^[0-9].[0-9].[0-9]$" ); do

  # identify lib directory .. sometime it is lib .. on others it is lib64 ... use ../R/library/base/DESCRIPTION (package) as trigger

  echo -n "-- identify lib vs lib64 for R ${R_VERSION}"
  RLIBX=$( find /opt/R/${R_VERSION} -type f -name DESCRIPTION | grep "/R/library/base/DESCRIPTION$" | awk -F/ '{print $5}' )
  echo "  ... found ${RLIBX}"


  # - install packages

  if [ -f "$(dirname $0)/R/install_packages.R" ]; then

    echo "-- deploying packages for R ${R_VERSION}"

    echo "   initiate /sources/packages directory"
    mkdir -p /sources/packages

    echo "   installing utility packages"
    /opt/R/${R_VERSION}/bin/R CMD BATCH --no-restore --no-save $(dirname $0)/R/install_packages.R /logs/R/rdevworkbench/${R_VERSION}-install-packages.log

    for XSOURCE in $( ls /sources/packages | sort ); do

      _MD5=($(md5sum /sources/packages/${XSOURCE}))
      _SHA256=($(sha256sum /sources/packages/${XSOURCE}))

      echo "   ${XSOURCE} (MD5 ${_MD5} / SHA-256 ${_SHA256})"

      unset _MD5
      unset _SHA256

    done


    echo "   install log assessment"
    grep -i "^ERROR:" /logs/R/rdevworkbench/${R_VERSION}-install-packages.log

    gzip -9 /logs/R/rdevworkbench/${R_VERSION}-install-packages.log
    chmod u+r-wx,g+r-wx,o+r-wx /logs/R/rdevworkbench/${R_VERSION}-install-packages.log.*

    echo "   clean source archive"
    rm -f /sources/packages/*

    echo "   set utils install to read-only"
    find ${RVER_UTILSLIB} -type f -exec chmod u+r-wx,g+r-wx,o+r-wx {} \;
    find ${RVER_UTILSLIB} -type d -exec chmod u+rx-w,g+rx-w,o+rx-w {} \;

  fi


  # - all done for now
done

# -- end of update for each R version


echo "-- init complete"
