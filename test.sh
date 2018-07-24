#!/bin/bash
set_ip="192.168.1.107"

ifconfig eth0|grep "inet addr:"
get_ip="$(ifconfig eth0:0|grep "inet addr:"| tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
echo $get_ip
first=${get_ip%%.*}
last3=${get_ip#*.}
second=${last3%%.*}
last2=${last3#*.}
third=${last2%.*}
fourth=${last2#*.}
echo "$get_ip -> $first, $second, $third, $fourth"
echo "third one is $third" 
if [ ! $third ];then
        echo "interface is empty"
fi

if [ "$third" != "1" ] || [ "$first" != "192" ] || [ "$second" != "168" ];then
        sudo ip addr add $set_ip/24 brd + dev eth0 label eth0:0
        echo "resetting ip addr"
        test_ip="$(ifconfig eth0:0|grep "inet addr:"| tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
last3=${test_ip#*.}
        last2=${last3#*.}
        third=${last2%.*}
        if [ "$third" == "1" ];then
        echo "set suceess!!"
        else for ((i=1; i <= 3; i++))
        do
                sudo ip addr del $set_ip/24 brd + dev eth0 label eth0:0
                echo "error ip addr add agin: $i"
                sudo ip addr add $set_ip/24 brd + dev eth0 label eth0:0
                test_ip="$(ifconfig|grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
                last3=${test_ip#*.}
                last2=${last3#*.}
                third=${last2%.*}
        if [ "$third" == "1" ];then
                sudo ip addr add $set_ip/24 brd + dev eth0 label eth0:0
                echo "set suceess!!!!"
        exit 1
        fi
        done
        fi

else PI=$(ping -c 1 $set_ip | grep -q 'ttl=' && echo "$set_ip yes"|| echo "$set_ip no")
echo "THIS $PI"

        if [ "$PI" == "192.168.1.107 yes" ];then
                echo "find the crame"
        else
                echo "can not find the crame"
        fi
fi



