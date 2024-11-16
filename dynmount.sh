# dynmount.sh
#!/system/bin/sh
MODDIR="${0%/*}"
MODNAME="${MODDIR##*/}"
TMPFILE="/data/adb/modules/$MODNAME/module.prop"
. "$MODDIR/utils.sh"

STAGE="$1"
PROC="$4"
USERID="$5"

RUN_SCRIPT() {
    case "$STAGE" in
    "prepareEnterMntNs")
        prepareEnterMntNs
        ;;
    "EnterMntNs")
        EnterMntNs
        ;;
    esac
}

prepareEnterMntNs() {
    USER_CHOICE=$(cat "$MODDIR/.user_choice" 2>/dev/null || echo "Both")
    
    case "$USER_CHOICE" in
        "YouTube")
            if [ "$PROC" == "$PKG_NAME_YT" ] || [ "$UID" -lt 10000 ] || [ "$PROC" == "com.android.systemui" ]; then
                touch "$MODDIR/loaded"
                check_app || exit 1
                sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ▶️ YouTube v'"$PKG_VER_YT"': ✓ ] /g' "$TMPFILE"
                exit 0
            fi
            ;;
        "YTMusic")
            if [ "$PROC" == "$PKG_NAME_YTM" ] || [ "$UID" -lt 10000 ] || [ "$PROC" == "com.android.systemui" ]; then
                touch "$MODDIR/loaded"
                check_app || exit 1
                sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 🎵 YT Music v'"$PKG_VER_YTM"': ✓ ] /g' "$TMPFILE"
                exit 0
            fi
            ;;
        "Both")
            if [ "$PROC" == "$PKG_NAME_YT" ] || [ "$PROC" == "$PKG_NAME_YTM" ] || [ "$UID" -lt 10000 ] || [ "$PROC" == "com.android.systemui" ]; then
                touch "$MODDIR/loaded"
                check_app || exit 1
                sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ▶️ YouTube v'"$PKG_VER_YT"': ✓ | 🎵 YT Music v'"$PKG_VER_YTM"': ✓ ] /g' "$TMPFILE"
                exit 0
            fi
            ;;
    esac
    exit 1
}

EnterMntNs() {
    . "$MODDIR/mount.sh"
    exit 1
}

RUN_SCRIPT