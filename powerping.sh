#!/bin/bash
#Copyright (c) 2012 Alykhan Nathoo.
#All rights reserved.
#
#Redistribution and use in source and binary forms are permitted
#provided that the above copyright notice and this paragraph are
#duplicated in all such forms and that any documentation,
#advertising materials, and other materials related to such
#distribution and use acknowledge that the software was developed
#by Alykhan Nathoo.  
#THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
#IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

#Specify one of the following OS
CYGWIN=0
LINUX=0
MAC=1
#linux ping is from iputils
#gawk must also be installed

#echo -e '\E[37;44m'"\033[1mContact List\033[0m"
if [ $MAC -eq 1 ]; then
  esc="\033"
else
  esc="\E"
fi

#black='\E[30;47m'
black='$esc[30;47m'
red='$esc[31;47m'
green='$esc[32;47m'
yellow='$esc[33;47m'
blue='$esc[34;47m'
magenta='$esc[35;47m'
cyan='$esc[36;47m'
white='$esc[37;47m'


passed=0
cnt=0
consecutivefailed=0
consecutivepassed=0
stconn="unknown"

old_tty=`stty -g`

connconn()
{
 if [ $consecutivefailed -eq 0 ]; then
   stconn="connection state unknown"
   if [ $consecutivepassed -ge 100 ]; then
     stconn="$esc[30;47m$esc[1mconn excellent$esc[0m\033[0m"
   else
     if [ $consecutivepassed -ge 10 ]; then
       stconn="$esc[45;36$esc[1mconn good$esc[0m\033[0m"
     else
       if [ $consecutivepassed -ge 5 ]; then
         stconn="$esc[33;40m$esc[1mconn ok$esc[0m\033[0m"
       else
         if [ $consecutivepassed -ge 2 ]; then
           stconn="$esc[33;40m$esc[1mconn almost ok$esc[0m\033[0m"
         fi
       fi
     fi
   fi
 else
   stconn="$esc[33;47mconnection usable$esc[1m$esc[0m\033[0m"
   if [ $consecutivefailed -ge 3 ]; then
     stconn="connection somewhat usable"
     if [ $consecutivefailed -ge 5 ]; then
       stconn="connection mostly unusable"
       if [ $consecutivefailed -ge 10 ]; then
         stconn="$esc[33;47mconnection completely unusable$esc[1m$esc[0m\033[0m"
       fi
     fi
   fi
 fi
}


#file=pingstats$$
file=/dev/null
on_die()
{
  echo done. $passed passed in $cnt tries `date`.
  echo done. $passed passed in $cnt tries `date`. >> $file
  stty "$old_tty"
  stty sane
  exit
}

helptext()
{
  echo ===========
  echo $0 Help
  echo   q to quit
  echo   h for help
  echo   s summary results
  echo ===========
}

echo starting `date` > $file 

trap 'on_die' SIGHUP SIGINT SIGTERM

if [ "$#" -eq 0 ]; then
  echo Please provide ip address. Something deep within the internet.
  exit 1
fi

if [ "$#" -eq 1 ]; then
  echo "Please provide option 'full' or 'line' depending on if you want"
  echo to use the entire screen, or just one line on the screen.
  exit 1
fi

if [ "$2" != "full" ]; then
  if [ "$2" != "line" ]; then
    echo "specify 'full' or 'line' for 2nd parameter."
    echo e.g $0 www.google.ca line
    echo e.g $0 www.google.ca full
    exit 2
  fi
fi

if [ "$2" == "line" ]; then
  clear
fi
stty -icanon -echo min 0 time 4

echo -en "pinging..."
while [ 1 ]; do
# read -t 1 inch <&1
 read -t 1 inch
 if [ -z "$inch" ]; then
  inch=""
 else
  if [ $inch == "q" ]; then
    on_die
  fi
  if [ $inch == "s" ]; then
    echo Summary: $passed passed in $cnt tries `date`.
  else
    helptext
  fi

 fi
 if [ $LINUX -eq 1 ]; then
   # rtt min/avg/max/mdev = 24.631/24.631/24.631/0.000 ms
   tms=`ping -c 1 $1 | grep rtt | awk -F= '{print $2}' | awk -F. '{print $1}'`
   ping -c 1 $1 | grep rtt
 else 
   if [ $MAC -eq 1 ]; then
     tms=`ping -s 64 -c 1 $1 | grep time= | awk -F= '{print $4}' | awk '{print $1}'`
   else
     tms=`ping $1 64 1 | grep time= | awk -F= '{print $4}' | awk '{print $1}'`
   fi
 fi

 tms=51

 if [ $tms -gt 50 ]; then
   rt="-"
   tmsStr="$esc[33;40m$esc[1m$tms$esc[0m\033[0m"
   if [ $tms -gt 500 ]; then
     rt="--"
     tmsStr="$esc[30;41m$esc[1m$esc[5m$tms$esc[0m\033[0m"
   fi
 else
   rt="$esc[1m+$esc[0m"
   tmsStr="$esc[32;47m$esc[1m$tms$esc[0m\033[0m"
 fi
 if [ $LINUX -eq 1 ]; then
   ping -c 1 $1  > /dev/null
 else
   if [ $MAC -eq 1 ]; then
     ping -c 1 -s 64 $1 | grep " 0.0%" > /dev/null
   else
     ping $1 64 1 | grep " 0.0%" > /dev/null
   fi
 fi
 pstat=$?
# echo $?
 if [ $pstat -eq 0 ]; then
#   echo passed $pstat.
#   echo passed $consecutivepassed in a row.
   (( passed += 1 ))
   (( consecutivepassed += 1 ))
   consecutivefailed=0
   sleep 1
 else
   if [ $consecutivepassed -eq 0 ]; then
    a=1
   else
     echo passed $consecutivepassed in a row.
     consecutivepassed=0
   fi
   (( consecutivefailed += 1 ))
#   echo FAILED $consecutivefailed in a row `date`.
 fi
 (( cnt += 1 ))
 connconn
 if [ $2 == 'line' ]; then
   echo -en "$esc[2K\r$stconn $passed/$cnt. p:$consecutivepassed f:$consecutivefailed $rt:$tmsStr `date +"%I:%M%P %a %d %b"`  "
 else
   echo -e "$stconn $passed/$cnt. p:$consecutivepassed f:$consecutivefailed $rt:$tmsStr `date +"%I:%M%P %a %d %b"`  "
 fi
done
echo
echo $passed passed in $cnt tries `date`.
stty "$old_tty"
stty sane
