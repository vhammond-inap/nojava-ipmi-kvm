#!/bin/bash	
#############################################################################
#
# Copyright 2020 Internap.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author Valerie GvM vhammond<AT>internap.com 
#
#############################################################################

export SPLASH_TIMER=${SPLASH_TIMER-14}
export TRIES=3

_clipper_main() {
	if [ 3 != ${#} ] ; then
		echo usage: clipper.sh password clip application_name
		echo got ${#}: ${*}
		return 1
	fi

	local password=${1} ; shift
	local clip=${1} ; shift
	local name=${*} ; shift

	local start=0

	local splashed=1
	local clipped=1
	local delay=1

	local id=""

	while true ; do 
		# do nothing until the javaws window is available
		local now=$( _clipper_window_id "${name}" )
		if [ "" = "${id}" ] ; then
			id=${now}
			if [ "" = "${id}" ] ; then
				echo waiting on ${name}
				sleep 1
				continue;
			else
				echo hide the initial window
				_clipper_window_fullscreen ${id}
				_clipper_window_hide ${id}
			fi
		else 
			if [ "${now}" != "" ] && [ "${now}" != "${id}" ] ; then
				echo id changed from ${id} to ${now}
				id=${xox}
				_clipper_window_hide ${id}
				_clipper_window_fullscreen ${id}
			fi
		fi

		# start the splash timer if it's not running
		if [ 0 = ${start} ] ; then
			start=${SECONDS}
			echo start the splash counter
		fi

		# if we haven't closed the splash window yet
		# see if it is time yet
		if [ 0 != ${splashed} ] ; then
			let diff=${SECONDS}-${start}
			if [ ${diff} -gt ${SPLASH_TIMER} ] ; then
				splashed=0
				echo closing the splash...
				supervisorctl stop splash
				killall xview
				echo closed splash
				echo unhiding the window:
				/usr/bin/xdotool windowmap --sync ${id}
				echo k?
			else
				echo waiting to close splash: ${diff} of ${SPLASH_TIMER}, ${delay}
				sleep ${delay}
			fi
			continue;
		fi

		if [ 0 != ${clipped} ] ; then
			echo show the window for ${name}
			_clipper_window_fullscreen ${id}
			_clipper_window_show ${id}
			clipped=${?}
			if [ 0 = ${clipped} ] ; then
				/usr/bin/x11vnc -passwd ${password} -remote "id:${id}" --sync
				# shouldn't really need to clip again
				#/usr/bin/x11vnc -passwd ${password} -remote "clip:${clip}" --sync
				echo clipped successfully
				delay=3
			else
				echo could not clip yet: ${clipped}
				delay=2
			fi
		fi

		sleep ${delay}
	done
}

_clipper_window_id() {
	/usr/bin/xdotool search --onlyvisible --name "${name}" 2>/dev/null \
	| awk '{id=$1}END{if(1==NR)print id}'
}

_clipper_window_hide() {
	local id=${1} 
	if [ "" = "${id}" ] ; then
		return 33
	fi
	_clipper_window_xdotool windowunmap --sync ${id}
}

_clipper_window_show() {
	local id=${1} 
	if [ "" = "${id}" ] ; then
		return 33
	fi
	_clipper_window_xdotool windowmap --sync ${id}
}

_clipper_window_fullscreen() {
	local id=${1} 
	if [ "" = "${id}" ] ; then
		return 33
	fi
	local size=$( xdotool getdisplaygeometry )
	
	_clipper_window_set_position ${id} 0 0 
	_clipper_window_set_size ${id} ${size}
}

_clipper_window_set_position() {
	local id=${1}; shift
	local x=${1} ; shift
	local y=${1} ; shift

	local pos="${x} ${y}"
	echo "move window to ${pos}"
	
	for ((i=0;i<${TRIES};i++)) ; do
		local current=$( _clipper_window_get_position ${id} )
		if [ "${current}" = "${pos}" ] ; then
			break
		else
			echo "position should be ${pos}, not ${current}"
		fi
		_clipper_window_xdotool windowmove --sync ${id} ${x} ${y}
	done
	echo "current window position of ${id} is $( _clipper_window_get_position ${id} )"
}

_clipper_window_get_position() {
	local id=${1} 
	if [ "" = "${id}" ] ; then
		return 33
	fi
	/usr/bin/xdotool getwindowgeometry ${id} \
   	| awk '/Position:/{sub(/[+x,]/," ");print $2 " " $3}'
}

_clipper_window_set_size() {
	local id=${1} ; shift
	local width=${1}; shift
	local height=${1}; shift
	echo "resize ${id} to ${size}"
	for ((i=0;i<${TRIES};i++)) ; do
		local current=$( _clipper_window_get_size ${id} )
		if [ "${current}" = "${size}" ] ; then
			break
		else
			echo "size should be ${size}, not ${current}"
		fi
		_clipper_window_xdotool windowsize --sync ${id} ${size} 
	done
	echo "current window size of ${id} is $( _clipper_window_get_size ${id} )"
}

_clipper_window_get_size() {
	local id=${1} 
	if [ "" = "${id}" ] ; then
		return 33
	fi
	/usr/bin/xdotool getwindowgeometry ${id} \
	| awk '/Geometry:/{sub(/[+x]/," ");print $2 " " $3}'
}

_clipper_window_xdotool() {
	echo "/usr/bin/xdotool ${*}"
	/usr/bin/xdotool ${*}
}


password=${1} ; shift ; clip=${1} ; shift ; name=${*} 
_clipper_main "${password}" "${clip}" "${name}"
	
# EOF
#############################################################################
