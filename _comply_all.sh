#!/bin/bash

for i in $(ls *.c)
do
	if [[ $(cat $i  | wc -l) ]]
	then
		echo "complying to betty ..."
		betty-comply.pl $i
	else
		echo "empty file : $i  skipping..."
	fi
done
