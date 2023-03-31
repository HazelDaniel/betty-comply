#!/bin/bash

if [ "$(id -u)" != "0" ]
then
	echo "Sorry, you are not root."
	exit 1
fi

COMPLY_ALL="_comply_all"
BETTY_COMPLY="betty-comply"
COMPLY_ALL_SYM="_complyAll"
BETTY_COMPLY_SYM="_bettyComply"



APP_PATH="/opt/betty-comply"
BIN_PATH="/usr/local/bin"
MAN_PATH="/usr/local/share/man/man1"

echo -e "Removing binaries.."

rm "${APP_PATH}/${COMPLY_ALL}"
rm "${APP_PATH}/${BETTY_COMPLY}"
rm "${BIN_PATH}/${COMPLY_ALL_SYM}"
rm "${BIN_PATH}/${BETTY_COMPLY_SYM}"



echo -e "Deleting man pages.."


rm  "${MAN_PATH}/betty_comply.1"


echo -e "All set."
