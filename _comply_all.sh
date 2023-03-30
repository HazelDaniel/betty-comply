#!/bin/bash


for i in $(ls *.c)
do
	if [[ $(cat $i  | wc -l) ]]
	then
		echo "complying to betty ..."
		_bettyComply $i
	else
		echo "empty file : $i  skipping..."
	fi
done

if [[ $? -eq 0 ]]
then
	echo -e "done. \u2713\n"
fi
