#!/bin/bash

PATH="${PATH}"

uname | grep -q "CYGWIN" && OS="CYGWIN" || OS="WINDOWS"
uname -a | grep -q "Microsoft" && OS="WINUX"
uname -a | grep -q "^Linux" && OS="LINUX"

if [ "${OS}" = "CYGWIN" ]; then
	HOME="/cygdrive/c/cd2podcast"
	DEV="0,1,0"
	CDDA2WAV="cdda2wav"
	SOX="sox"
	LAME="sox"
	NCFTPPUT="ncftpput"
elif [ "${OS}" = "WINUX" ]; then
	HOME="/home/enjoy/cd2podcast"
	CDDA2WAV="${HOME}/bin/cdda2wav.exe"
	NIRCMD="${HOME}/bin/nircmd.exe"
	SOX="sox"
	LAME="lame"
	NCFTPPUT="ncftpput"
elif [ "${OS}" = "LINUX" ]; then
	HOME="/home/dottey/git/cd2podcast"
	CDDA2WAV="cdda2wav"
	# NIRCMD="${HOME}/bin/nircmd.exe"
	SOX="sox"
	LAME="lame"
	NCFTPPUT="ncftpput"
else
	HOME="c:/cd2podcast"
fi

URL="http://www.enjoydaybreak.com/"
ALBUM="Daybreak Community Church"
COMMENT="${ALBUM} - ${URL}"
YEAR=2019
GENRE=101
UPLOAD=0
DEBUG=1
OUTROFILE="${HOME}/intro/daybreak_podcast_outro.wav"
PODCAST_LOGO="${HOME}/daybreak_podcast_icon.jpg"
ARCHIVE="${HOME}/archive"
LIBSYN_CONF="${HOME}/libsyn_ftp.conf"
TEMP="${HOME}/temp/"

/bin/which eject >/dev/null 2>&1 || function eject () {
	${NIRCMD} cdrom open
}

die ()
{
	echo $1
	exit 1
}

# box_out modified from http://unix.stackexchange.com/questions/70615/bash-script-echo-output-in-box
function box_out() {
        input_char=$(echo "$@" | wc -c)
        line=$(for i in `seq 0 $input_char`; do printf "-"; done)
        # tput This should be the best option. what tput does is it will read the terminal info and render the correctly escaped ANSI code for you. code like \033[31m will break the readline library in some of the terminals.
        tput bold
        line="$(tput setaf 3)${line}"
        #space=${line//-/ }
		space=`echo ${line} | sed -e "s|-| |g"`
        echo " ${line}"
        printf '|' ; echo -n "$space" ; printf "%s\n" '|';
        printf '| ' ;tput setaf 4; echo -n "$@"; tput setaf 3 ; printf "%s\n" ' |';
        printf '|' ; echo -n "$space" ; printf "%s\n" '|';
        echo " ${line}"
        tput sgr 0
}

usage ()
{
    echo "Usage: $0 [-u user] [-p pass] [-U] [-S] [-c] [-T track] [-w WAV file]"
    echo
    echo "  -t TITLE                   specify the title"
    echo "  -a ARTIST                  specify the artist name"
    echo "  -d DATE STAMP              specify the date stamp in form of YYYYMMDD"
    #echo "  -D DEVICE                  specify the device (/dev/cdrecorder)"
	echo "  -T TRACK                   specify a specific track number to rip: START[+END]"
	echo "  -w WAV file                use a specific wav file instead of ripping from a CD"
	echo "  -x                         do not upload to the FTP server"
	echo "  -z                         DEBUG"
}

while getopts ":t:a:d:D:h?T:w:xz" Option
do
  case $Option in
    t   ) TITLE=$OPTARG;;
    a   ) ARTIST=$OPTARG;;
    d   ) TIMESTAMP=$OPTARG;;
    #D   ) DEV=$OPTARG;;
	T	) TRACK=$OPTARG;;
	w	) WAV=$OPTARG;;
	x	) UPLOAD=1;;
	z   ) DEBUG=0;;
    h|? ) usage
		  exit 0;;
    *   ) echo "Unimplemented option chosen."
          usage
		  exit 1;;
  esac
done

which ${SOX} > /dev/null 2>&1 || die "sox is not installed!"
which ${LAME} > /dev/null 2>&1 || die "lame is not installed!"
which ${CDDA2WAV} > /dev/null 2>&1 || die "cdda2wav / cdrtools is not installed!"
which ${NCFTPPUT} > /dev/null 2>&1 || die "ncftp is not installed!"

[ -f ${LIBSYN_CONF} ] || die "Libsyn FTP conf file ${LIBSYN_CONF} does not exist."

mkdir -p ${ARCHIVE} || die "Unable to make archive folder ${ARCHIVE}."
mkdir -p ${TEMP} || die "Unable to make temp folder ${TEMP}."
/bin/rm -rf ${TEMP}/* || die "Unable to cleanup the temp folder ${TEMP}."

if [ ${DEBUG} -eq 0 ]; then
	echo "DEBUG"
	echo "Artist = $ARTIST"
	echo "Title = $TITLE"
	echo "Date = $TIMESTAMP"
fi

if [ -z "${TITLE}" ]; then
	echo -n "Please enter a value for TITLE, without quotes: (eg Juicy Fruit - Gentleness)"
	read  TITLE
	if [ -z "${TITLE}" ]; then
		echo
		usage
		exit 1
	fi
fi

if [ -z "${ARTIST}" ]; then
	echo -n "Please enter a value for ARTIST, without quotes (eg David Hakes): "
	read ARTIST
	if [ -z "${ARTIST}" ]; then
		echo
		usage
		exit 1
	fi
fi

if [ -z "${TIMESTAMP}" ]; then
	echo -n "Please enter a value for TIMESTAMP, without quotes (eg 20150705): "
	read TIMESTAMP
	if [ -z "${TIMESTAMP}" ]; then
		echo
		usage
		exit 1
	fi
fi

if [ ${DEBUG} -eq 0 ]; then
	echo "DEBUG"
	echo "After possible prompts"
	echo "Artist = $ARTIST"
	echo "Title = $TITLE"
	echo "Date = $TIMESTAMP"
fi

FILENAME="$TIMESTAMP-`echo $TITLE | sed -e 's| |\_|g' | sed -e 's|\_\-\_|\-|g'`"
[ ${DEBUG} -eq 0 ] && echo "Filename = ${FILENAME}"

cd ${TEMP}

if [ -z $WAV ]; then
	if [ -z $TRACK ]; then
		# No tracks specified, lets rip 'em all!
		if [ "${OS}" = "CYGWIN" ]; then
			${CDDA2WAV} -B -D ${DEV} --no-infofile ${FILENAME}.wav || die "Error extracting from CD"
		else
			${CDDA2WAV} -B --no-infofile ${FILENAME}.wav || die "Error extracting from CD"
		fi
	else
		# Rip only the track specified
		if [ "${OS}" = "CYGWIN" ]; then
			${CDDA2WAV} -D ${DEV} -t ${TRACK} --no-infofile ${FILENAME}.wav || die "Error extracting from CD"
		else
			${CDDA2WAV} -t ${TRACK} --no-infofile ${FILENAME}.wav || die "Error extracting from CD"
		fi

	fi

	echo
	echo
	box_out "CD extraction complete.  It is now safe to eject the CD."
	echo
	echo
	eject
else
	if [ "${WAV}" != "${FILENAME}.wav" ]; then
		mv ${WAV} "${FILENAME}.wav"
	fi
fi

case $ARTIST in
	"David Hakes" ) INTROFILE="${HOME}/intro/Intro_Hakes-Pastor.wav";;
	#"Kevin Grando" ) INTROFILE="${HOME}/intro/Intro_Grando.wav";;
	#"Dan Houck" ) INTROFILE="${HOME}/intro/Intro_Houck.wav";;
	* ) INTROFILE="${HOME}/intro/Intro_Generic.wav";;
esac

FILE_COUNT=`ls ${FILENAME}_*.wav 2>/dev/null | wc -l`
if [ ${FILE_COUNT} -gt 1 ]; then
	echo "More than one track - splicing them together!"
	${SOX} ${FILENAME}_*.wav ${OUTROFILE} ${FILENAME}-no_intro.wav || die "Error concatenating files."
else
	echo "Only one file.  Still have to add the outro."
	mv ${FILENAME}.wav ${FILENAME}-only.wav
	${SOX} ${FILENAME}-only.wav ${OUTROFILE} ${FILENAME}-no_intro.wav || die "Error concatenating files."
fi

# Remove silence from beginning of audio
${SOX} ${FILENAME}-no_intro.wav ${FILENAME}-no_silence.wav silence 1 0.3 1% || die "Error while removing silence from beginning of audio."

cp ${INTROFILE} ${FILENAME}-intro.wav

# Cross-fade the intro with the audio
FADE1="${FILENAME}-intro.wav"
FADE2="${FILENAME}-no_silence.wav"

# Weird workaround
[ "${OS}" != "CYGWIN" ] && chmod 664 *.wav

${HOME}/crossfade.sh 4 ${FADE1} ${FADE2}

${SOX} cfo_${FADE1} cfi_${FADE2} ${FILENAME}.wav || die "Error while concatonating the final files."

[ ${DEBUG} -eq 0 ] && echo "DEBUG - Concat should be done now..."

echo
box_out "Converting WAV to 64 kbps MP3 file for upload to FTP site."
echo
${LAME} -m j -q 2 --resample 22.05 --tt "${TITLE}" --ta "${ARTIST}" --tl "${ALBUM}" --ty ${YEAR} --tc "${COMMENT}" --tg ${GENRE} --ti ${PODCAST_LOGO} --add-id3v2 -b 64 ${FILENAME}.wav ${FILENAME}-64.mp3 || die "Error while converting wav to 64 kbps mp3"

[ ${DEBUG} -eq 0 ] && ls -l ${FILENAME}*

if [ ${UPLOAD} -eq 0 ]; then
	echo
	box_out "Uploading MP3 to Libsyn FTP Site."
	echo
	mv ${FILENAME}-64.mp3 ${FILENAME}.mp3
	$NCFTPPUT -f ${LIBSYN_CONF} /daybreak/dropbox/ ${FILENAME}.mp3
	if [ $? -ne 0 ]; then
		echo
		echo
		box_out "There was a problem during the upload process."
		echo
		echo
	else
		echo
		echo
		box_out "Ignore any \"Could not preserve times\" warnings.  MP3 upload completed successfully.  You may now post podcast via Libsyn."
		echo
		echo
	fi
	mv ${FILENAME}.mp3 ${FILENAME}-64.mp3
fi

echo
box_out "Converting WAV to 320 kbps MP3 file for higher quality archival."
echo
${LAME} -m j -q 2 --resample 44.1 --tt "${TITLE}" --ta "${ARTIST}" --tl "{$ALBUM}" --ty ${YEAR} --tc "${COMMENT}" --tg ${GENRE} --ti ${PODCAST_LOGO} --add-id3v2 -b 320 ${FILENAME}.wav ${FILENAME}-320.mp3 || die "Error while converting wav to 320 kbps mp3"

echo "Moving newly created MP3s into local archive."
mv ${FILENAME}*.mp3 ${ARCHIVE}

echo "Cleaning up more files..."
rm -f cfo_${FADE1} cfi_${FADE2} ${FILENAME}*.wav

echo
echo
box_out "All processing is now complete."
echo
echo

cd - > /dev/null
