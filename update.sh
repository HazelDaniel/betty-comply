#!/bin/bash

if [ "$(id -u)" != "0" ]
then
	echo "Sorry, you are not root."
	exit 1
fi


echo -e "Running update.."

./flush.sh
./install.sh
