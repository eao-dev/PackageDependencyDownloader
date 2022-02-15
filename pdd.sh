#!/bin/bash

if [ "$(id -u)" -ne 0 ]
then
	echo "No root privileges!"
	exit 1
fi

SOURCES_LIST_FILE=./sources-list.txt
PACKAGES_FILE=./packages-list.txt

INSTALL_LIST=$(cat $PACKAGES_FILE)

function usageShow(){
	echo "Usage: script.sh [download | install] full_path_to_packages_dir"
	echo "install: installing packages from directory packages using specified list in the packages.list"
	echo "download: download .deb-packages(with dependencies) to directory packages"
	echo "packages.list contains list of packages"
}

if test -z $1; then
	usageShow
	return 1
fi

if [ $1 == "install" ]
then
	echo " INSTALL PACKAGES "
	
	rm $SOURCES_LIST_FILE &> /dev/null
	echo "deb [trusted=yes] file:$2 ./" >> $SOURCES_LIST
	
	apt-get update -o Dir::Etc::sourcelist="$SOURCES_LIST"
	
	cat $PACKAGES_FILE | while read package
	do
		echo "	[*] Try install package $package"
		apt install -y $package -o Dir::Etc::sourcelist="$SOURCES_LIST"
	done

elif [ $1 == "download" ]
then

	if  ! mkdir -p $2
	then
		echo "Error create directory $2"
		exit 1
	fi

	echo "DOWNLOAD PACKAGES WITH DEPENDENCIES (only amd64)"
	
	if [[ ! -f $PACKAGES_FILE ]] 
	then
		echo Error: $PACKAGES_FILE not found!
		exit 1
	fi
	
	sudo apt install -y dpkg-dev

	cd $2
	
	apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $INSTALL_LIST | grep "^\w" | grep -v "i386" | sort -u)
	dpkg-scanpackages . | gzip -9c > Packages.gz
else
	usageShow
fi

echo "[DONE]"

exit 0