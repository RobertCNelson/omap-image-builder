#!/bin/bash

#X-Server:
#quantal:1.13.0
#precise:1.11.4
#oneiric:1.10.4
#natty:1.10.1 -> http://processors.wiki.ti.com/index.php/RN_4_08_00_01
#maverick:1.9.0
#lucid:1.7.6

#Precise Schedule:
#https://wiki.ubuntu.com/PrecisePangolin/ReleaseSchedule
#alpha-1 : Dec 1st
PRECISE_ALPHA="ubuntu-precise-alpha1"
#alpha-2 : Feb 2nd
PRECISE_ALPHA2="ubuntu-precise-alpha2-1"
#beta-1 : March 1st
PRECISE_BETA1="ubuntu-precise-beta1"
#beta-2 : March 29th
PRECISE_BETA2="ubuntu-precise-beta2"
#12.04 : April 26th
PRECISE_RELEASE="ubuntu-12.04-r9"

PRECISE_CURRENT=${PRECISE_RELEASE}

#Quantal Schedule:
#https://wiki.ubuntu.com/QuantalQuetzal/ReleaseSchedule
#alpha-1 : June 7th
QUANTAL_ALPHA="ubuntu-quantal-alpha1"
#alpha-2 : June 28th
QUANTAL_ALPHA2="ubuntu-quantal-alpha2"
#alpha-3 : July 26nd
QUANTAL_ALPHA3="ubuntu-quantal-alpha3"
#beta-1 : September 6th
QUANTAL_BETA1="ubuntu-quantal-beta1"
#beta-2 : September 27th
QUANTAL_BETA2="ubuntu-quantal-beta2"
#12.04 : October 18th
QUANTAL_RELEASE="ubuntu-12.10-r2"

QUANTAL_CURRENT=${QUANTAL_RELEASE}

#Raring Schedule
#https://wiki.ubuntu.com/RaringRingtail/ReleaseSchedule
RARING_SNAPSHOT="ubuntu-raring-snapshot"
#12.04 : April 25th
RARING_RELEASE="ubuntu-13.04-r1"

RARING_CURRENT=${RARING_SNAPSHOT}

#rcn-ee: kernel version when doing releases...
#PRIMARY_KERNEL_OVERRIDE="v3.6.2-x3"
#SECONDARY_KERNEL_OVERRIDE="v3.2.32-psp25"
#THIRD_KERNEL_OVERRIDE="v3.2.32-x15"
#
