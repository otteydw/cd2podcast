#!/bin/bash
#
# crossfade.sh
#
# Creates two new files that when played together have a crossfade
# of $1 seconds.  This means that $1/2 of the crossfade is in
# the 1st file and $1/2 in the second file.  Can be used to
# make audio CD's with a 0 second pregap between songs to
# have one song flow into the next; yet still be able to skip
# around the CD with minimal loss of song.
#
# Filenames are specified as $2 and $3.
#
# $4 is optional and specifies if a fadeout should be performed on
# first file.  Can be yes/no/auto.
# $5 is optional and specifies if a fadein should be performed on
# second file. Can be yes/no/auto
#
# Example: $0 10 infile1.wav infile2.wav auto auto
#
# By default, the script attempts to guess if the audio files
# already have a fadein/out on them or if they just have really
# low volumes that won't cause clipping when mixxing.  If this
# is not detected then the script will perform a fade in/out to
# prevent clipping.
#
# The user may specify "yes" or "no" to force the fade in/out
# to occur.  They can also specify "auto" which is the default.
#
# Crossfaded file $2 is prepended with cfo_ and $3 is prepended
# with cfi_.
#
# Original script from Kester Clegg.  Mods by Chris Bagwell to show
# more examples of sox features.
#

uname | grep -q "CYGWIN" && MY_OS="CYGWIN" || MY_OS="WINDOWS"
uname -a | grep -q "Microsoft" && MY_OS="WINUX"

if [ "${MY_OS}" = "CYGWIN" ] || [ "${MY_OS}" = "WINUX" ]; then
	SOX="/usr/bin/sox"
else
	SOX="sox.exe"
fi

#SOX=../src/sox

#alias bc="bc.exe"
#alias grep="grep.exe"
#alias cut="cut.exe"

if [ "$3" = "" ]; then
    echo "Usage: $0 crossfade_seconds first_file second_file [ fadeout ] [ fadein ]"
    echo
    echo "If a fadeout or fadein is not desired then specify \"no\" for that option.  \"yes\" will force a fade and \"auto\" will try to detect if a fade should occur."
    echo
    echo "Example: $0 10 infile1.wav infile2.wav auto auto"
    exit 1
fi

fade_length=$1
first_file=$2
second_file=$3

fade_first="auto"
if [ "$4" != "" ]; then
    fade_first=$4
fi

fade_second="auto"
if [ "$5" != "" ]; then
    fade_second=$5
fi

fade_first_opts=
if [ "$fade_first" != "no" ]; then
	# fade t = a linear (triangular) slope
    fade_first_opts="fade t 0 0:0:${fade_length} 0:0:${fade_length}"
	#fade_first_opts="fade t 0 0:0 =${fade_length} 0:0 =${fade_length}"
fi

fade_second_opts=
if [ "$fade_second" != "no" ]; then
    fade_second_opts="fade t 0:0:${fade_length}"
fi

echo "crossfade and concatenate files"
echo
echo  "Finding length of $first_file..."
first_length=$($SOX $first_file -n stat 2>&1 | grep Length | cut -d : -f 2 | cut -f 1 | sed -e 's| *||g' -e 's|\r||')
echo "Length is $first_length seconds"

#echo "first_length = $first_length"
#echo "fade_length = $fade_length"
trim_length=$(echo "$first_length - $fade_length" | bc | sed -e 's| *||g' -e 's|\r||')
echo "Trim length is $trim_length seconds"
crossfade_split_length=$(echo "scale=2; $fade_length / 2.0" | bc | sed -e 's| *||g' -e 's|\r||')
echo "Crossfade split length is $crossfade_split_length seconds"

# Get crossfade section from first file and optionally do the fade out
echo "Obtaining $fade_length seconds of fade out portion from $first_file..."
#$SOX "$first_file" -s -b 16 fadeout1.wav trim $trim_length $fade_first_opts
# WARN sox: Option `-s' is deprecated, use `-e signed-integer' instead.
#echo "trime_length = $trim_length"
#echo "fade_first_opts = $fade_first_opts"
$SOX $first_file -e signed-integer -b 16 fadeout1.wav trim $trim_length $fade_first_opts
#$SOX $first_file -e signed-integer -b 16 fadeout1.wav trim 28.706667 fade t 0 0:0:4 0:0:4

# When user specifies "auto" try to guess if a fadeout is needed.
# "RMS amplitude" from the stat effect is effectively an average
# value of samples for the whole fade length file.  If it seems
# quite then assume a fadeout has already been done.  An RMS value
# of 0.1 was just obtained from trail and error.

if [ "$fade_first" = "auto" ]; then
    RMS=$($SOX fadeout1.wav 2>&1 -n stat | grep RMS | grep amplitude | cut -d : -f 2 | cut -f 1 | sed -e 's| *||g' -e 's|\r||')
    should_fade=$(echo "$RMS > 0.1" | bc | sed -e 's| *||g' -e 's|\r||')
    if [ $should_fade -eq 0 ]; then
        echo "Auto mode decided not to fadeout with RMS of $RMS"
        fade_first_opts=""
    else
        echo "Auto mode will fadeout"
    fi
fi

$SOX fadeout1.wav fadeout2.wav $fade_first_opts

# Get the crossfade section from the second file and optionally do the fade in
echo "Obtaining $fade_length seconds of fade in portion from $second_file..."
#$SOX "$second_file" -s -b 16 fadein1.wav trim 0 $fade_length
$SOX "$second_file" -e signed-integer -b 16 fadein1.wav trim 0 $fade_length

# For auto, do similar thing as for fadeout.
if [ "$fade_second" = "auto" ]; then
    RMS=$($SOX fadein1.wav 2>&1 -n stat | grep RMS | grep amplitude | cut -d : -f 2 | cut -f 1 | sed -e 's| *||g' -e 's|\r||')
    should_fade=$(echo "$RMS > 0.1" | bc | sed -e 's| *||g' -e 's|\r||')
    if [ $should_fade -eq 0 ]; then
        echo "Auto mode decided not to fadein with RMS of $RMS"
        fade_second_opts=""
    else
        echo "Auto mode will fadein"
    fi
fi

$SOX fadein1.wav fadein2.wav $fade_second_opts

# Mix the crossfade files together at full volume
echo "Crossfading..."
$SOX -m -v 1.0 fadeout2.wav -v 1.0 fadein2.wav crossfade.wav

echo "Spliting crossfade into $crossfade_split_length lengths"
$SOX crossfade.wav crossfade1.wav trim 0 $crossfade_split_length
$SOX crossfade.wav crossfade2.wav trim $crossfade_split_length

echo "Trimming off crossfade sections from original files..."

#$SOX "$first_file" -s -b 16 song1.wav trim 0 $trim_length
#$SOX "$second_file" -s -b 16 song2.wav trim $fade_length
$SOX "$first_file" -e signed-integer -b 16 song1.wav trim 0 $trim_length
$SOX "$second_file" -e signed-integer -b 16 song2.wav trim $fade_length

echo "Creating crossfade files"
#$SOX song1.wav crossfade1.wav "cfo_${first_file}.wav"
#$SOX crossfade2.wav song2.wav "cfi_${second_file}.wav"
$SOX song1.wav crossfade1.wav "cfo_${first_file}"
$SOX crossfade2.wav song2.wav "cfi_${second_file}"

echo -e "Removing temporary files...\n" 
rm fadeout1.wav fadeout2.wav fadein1.wav fadein2.wav crossfade.wav crossfade1.wav crossfade2.wav song1.wav song2.wav
mins=$(echo "$trim_length / 60" | bc | sed -e 's| *||g' -e 's|\r||')
secs=$(echo "$trim_length % 60" | bc | sed -e 's| *||g' -e 's|\r||')
echo "The crossfade occurs at around $mins mins $secs secs in $first_file"

