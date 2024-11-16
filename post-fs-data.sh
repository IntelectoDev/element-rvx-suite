# post-fs-data.sh
#!/system/bin/sh
MODDIR="${0%/*}"
MODNAME="${MODDIR##*/}"

PROPFILE="/data/adb/modules/$MODNAME/module.prop"
TMPFILE="/data/adb/modules/$MODNAME/revanced.prop"
cp -af "$MODDIR/module.prop" "$TMPFILE"

USER_CHOICE=$(cat "$MODDIR/.user_choice" 2>/dev/null || echo "Both")

if [ -e "$MODDIR/loaded" ]; then
    case "$USER_CHOICE" in
        "YouTube")
            sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ▶️ YouTube v'"$PKG_VER_YT"': ✓ ] /g' "$TMPFILE"
            ;;
        "YTMusic")
            sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 🎵 YT Music v'"$PKG_VER_YTM"': ✓ ] /g' "$TMPFILE"
            ;;
        "Both")
            sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ▶️ YouTube v'"$PKG_VER_YT"': ✓ | 🎵 YT Music v'"$PKG_VER_YTM"': ✓ ] /g' "$TMPFILE"
            ;;
    esac
else
    sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ⛔ Module is not working ] /g' "$TMPFILE"
fi

flock "$MODDIR/module.prop"
mount --bind "$TMPFILE" "$PROPFILE"
rm -f "$MODDIR/loaded"

exit 0