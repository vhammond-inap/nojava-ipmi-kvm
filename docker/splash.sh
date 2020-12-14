#!/bin/bash	

# from splash-show.sh ....

export SPLASH_IMAGE="/usr/local/bin/splash.png"
_splash_main() {
	echo reading geometry
	read screen_width screen_height < <(xdotool getdisplaygeometry)
	echo read geometry as ${screen_width} x ${screen_height}

	read image_width image_height < <(\
		xview -identify $SPLASH_IMAGE | \
		sed 's/.* \([0-9]*\)x\([0-9]*\) .*/\1 \2/g')
	echo read image size as ${image_width} ${image_height}

echo a1
    splash_width=$image_width
echo a2 ${splash_width}
    splash_width=${image_height}
echo a3 ${image_height}
    image_clip_x=$((screen_width/2-image_width/2))
echo a4 ${image_clip_x}
    image_clip_y=$((screen_height/2-image_height/2))
echo a5 ${image_clip_y}
    image_clip=${image_width}x${image_height}+${image_clip_x}+${image_clip_y}
echo a6 ${image_clip}

	# on the background 
	echo xview -center -onroot $SPLASH_IMAGE
    xview -center -onroot $SPLASH_IMAGE

	if [ 0 = 1 ] ; then 
		while true ; do
			sleep 13
		done
	else
		# in the foreground
		echo xview $SPLASH_IMAGE -geometry $image_clip 
		xview $SPLASH_IMAGE -geometry $image_clip &
		echo xview is running as ${xview_pid}

		xview_winid=$(xdotool search --sync --name $SPLASH_IMAGE)
		echo xview_winid is ${xview_winid}
		while xdotool windowraise $xview_winid ; do 
			true
			sleep 1
		done
		echo oof...
	fi
}

_splash_main ${*}
