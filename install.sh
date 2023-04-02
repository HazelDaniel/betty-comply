#!/bin/bash

if [ "$(id -u)" != "0" ]
then
	echo "Sorry, you are not root."
	exit 1
fi

COMPLY_ALL="_comply_all"
BETTY_COMPLY="betty-comply"
BETTY_WATCH_COMPLY="_watch_n_comply"
COMPLY_ALL_SYM="_complyAll"
BETTY_COMPLY_SYM="_bettyComply"
BETTY_WATCH_COMPLY_SYM="_watchComply"



APP_PATH="/opt/betty-comply"
BIN_PATH="/usr/local/bin"
MAN_PATH="/usr/local/share/man/man1"

echo -e "Installing binaries.."

mkdir -p "${APP_PATH}"

cp "${COMPLY_ALL}.sh" "${APP_PATH}/${COMPLY_ALL}"
cp "${BETTY_COMPLY}.pl" "${APP_PATH}/${BETTY_COMPLY}"
cp "${BETTY_WATCH_COMPLY}.sh" "${APP_PATH}/${BETTY_WATCH_COMPLY}"

chmod +x "${APP_PATH}/${COMPLY_ALL}"
chmod +x "${APP_PATH}/${BETTY_COMPLY}"
chmod +x "${APP_PATH}/${BETTY_WATCH_COMPLY}"

ln -s "${APP_PATH}/${COMPLY_ALL}" "${BIN_PATH}/${COMPLY_ALL_SYM}"
ln -s "${APP_PATH}/${BETTY_COMPLY}" "${BIN_PATH}/${BETTY_COMPLY_SYM}"
ln -s "${APP_PATH}/${BETTY_WATCH_COMPLY}" "${BIN_PATH}/${BETTY_WATCH_COMPLY_SYM}"

echo -e "Installing man pages.."

mkdir -p "${MAN_PATH}"

cp "man/betty_comply.1" "${MAN_PATH}"

echo -e "Updating man database.."

mandb

echo -e "All set."
