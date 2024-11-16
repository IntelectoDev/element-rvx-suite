# utils.sh
#!/system/bin/sh
. "$MODDIR/config"

# Read user choice saved during installation
USER_CHOICE=$(cat "$MODDIR/.user_choice" 2>/dev/null || echo "Both")

check_app() {
    local status=0
    local check_yt=false
    local check_ytm=false
    
    case "$USER_CHOICE" in
        "YouTube") check_yt=true ;;
        "YTMusic") check_ytm=true ;;
        "Both") check_yt=true; check_ytm=true ;;
    esac

    if [ "$check_yt" = true ]; then
        if BASEPATH=$(pm path "$PKG_NAME_YT" 2>&1 </dev/null); then
            BASEPATH=${BASEPATH##*:} 
            BASEPATH=${BASEPATH%/*}

            if [ ! -d "$BASEPATH/lib" ]; then
                sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ❌ YouTube Zygote has crashed ] /g' "$MODDIR/module.prop"
                status=1
            else
                VERSION=$(dumpsys package "$PKG_NAME_YT" | grep -m1 versionName)
                VERSION="${VERSION#*=}"
                if [ "$VERSION" != "$PKG_VER_YT" ] && [ "$VERSION" ]; then
                    sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ❌ The current version of YouTube does not match ] /g' "$MODDIR/module.prop"
                    status=1
                fi
            fi
        else
            if [ "$check_ytm" = false ]; then
                sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ❌ YouTube is not installed ] /g' "$MODDIR/module.prop"
                status=1
            fi
        fi
    fi

    if [ "$check_ytm" = true ] && [ $status -eq 0 ]; then
        if BASEPATH=$(pm path "$PKG_NAME_YTM" 2>&1 </dev/null); then
            BASEPATH=${BASEPATH##*:} 
            BASEPATH=${BASEPATH%/*}

            if [ ! -d "$BASEPATH/lib" ]; then
                sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ❌ YT Music Zygote has crashed ] /g' "$MODDIR/module.prop"
                status=1
            else
                VERSION=$(dumpsys package "$PKG_NAME_YTM" | grep -m1 versionName)
                VERSION="${VERSION#*=}"
                if [ "$VERSION" != "$PKG_VER_YTM" ] && [ "$VERSION" ]; then
                    sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ❌ The current version of YT Music does not match ] /g' "$MODDIR/module.prop"
                    status=1
                fi
            fi
        else
            if [ "$check_yt" = false ]; then
                sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ❌ YT Music is not installed ] /g' "$MODDIR/module.prop"
                status=1
            fi
        fi
    fi

    return $status
}