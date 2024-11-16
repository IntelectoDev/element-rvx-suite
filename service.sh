# service.sh
#!/system/bin/sh
MODDIR="${0%/*}"
MODNAME="${MODDIR##*/}"
TMPFILE="/data/adb/modules/$MODNAME/module.prop"
. "$MODDIR/utils.sh"

while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 1; done
while [ ! -d "/sdcard/Android" ]; do sleep 1; done

check_mount() {
    local pkg_name=$1
    BASEPATH=$(pm path "$pkg_name" 2>&1 </dev/null)
    if [ $? -ne 0 ]; then
        sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 😅 Files mounted globally - Dynamic mount not working ] /g' "$MODDIR/module.prop"
    else
        BASEPATH=${BASEPATH##*:}
        BASEPATH=${BASEPATH%/*}
        [ -e "$MODDIR/loaded" ] || { check_app && . "$MODDIR/mount.sh"; } || exit 0
    fi
}

USER_CHOICE=$(cat "$MODDIR/.user_choice" 2>/dev/null || echo "Both")
case "$USER_CHOICE" in
    "YouTube")
        check_mount "$PKG_NAME_YT"
        ;;
    "YTMusic")
        check_mount "$PKG_NAME_YTM"
        ;;
    "Both")
        check_mount "$PKG_NAME_YT"
        check_mount "$PKG_NAME_YTM"
        ;;
esac