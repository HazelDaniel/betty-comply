#!/bin/bash

ARG_COUNT=$#;

if [[ "$ARG_COUNT" -gt 1 ]]
then
	echo "you can only watch a file at a time!"
	echo "exiting..."
	exit 0
fi

### Set initial time of file
LTIME=`stat -c %Y $1`

while true    
do
   ATIME=`stat -c %Y $1`

   if [[ "$ATIME" != "$LTIME" ]]
   then    
       _bettyComply $1
       LTIME=$ATIME
   fi
   sleep 2
done
