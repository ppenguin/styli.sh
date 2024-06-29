#!/usr/bin/env bash

# filters plugin defining functions for styli.sh
# provides filters that can be applied to fetched wallpapers by executing an
# imagemagick (required dependency for this) hook

err=0

MAGICK=$(command -v magick) || err=$?

if [[ $err -gt 0 ]]; then
	echo "WARNING: imagemagick not found, filters not functional" | $NOTIFY_ERR
fi

# logo_overlay <logo file>
logo_overlay() {
	if [ ! $# -eq 1 ]; then
		echo "logo_overlay requires 1 argument, $# given, doing nothing" | $NOTIFY_ERR
		return
	fi
	if [ ! -f "$1" ]; then
		echo "logo_overlay: $1 does not exist, doing nothing" | $NOTIFY_ERR
		return
	fi
	# set -x
	tmpdir=$(mktemp -d)

	logo="$1"
	origwp="$tmpdir/origwp.png"
	mask="$tmpdir/mask.png"
	cutmask="$tmpdir/cut.png"
	invert="$tmpdir/invert.png"

	$MAGICK "$WALLPAPER" "$origwp" 2>/dev/null # convert instead of copy to get the type right (png from jpg to do alpha stuff)
	wpgeom="$($MAGICK identify "$origwp" | awk '{ print $3 }')"
	echo "wpgeom: $wpgeom" | outdbg

	# shellcheck disable=SC2086
	exdbg $MAGICK "$logo" -alpha extract -resize "$wpgeom" "$mask"
	exdbg $MAGICK composite -compose CopyOpacity "$mask" "$origwp" "$cutmask"
	exdbg $MAGICK "$cutmask" -channel RGB -negate "$invert"
	exdbg $MAGICK "$origwp" "$invert" -gravity center -composite "$WALLPAPER"

	[ -d "$tmpdir" ] && rm -rf "$tmpdir"
	# set +x
}
