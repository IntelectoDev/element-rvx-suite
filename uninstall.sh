#!/system/bin/sh

MODDIR=${0%/*}
MODNAME="${MODDIR##*/}"

cleanup() {
    local status=0
    
    # Cargar configuración y user choice
    if [ -f "$MODDIR/config" ]; then
        . "$MODDIR/config"
        [ -f "$MODDIR/.user_choice" ] && USER_CHOICE=$(cat "$MODDIR/.user_choice")
        
        # Detener las aplicaciones antes de la limpieza
        case "$USER_CHOICE" in
            "YouTube")
                am force-stop "$PKG_NAME_YT"
                ;;
            "YTMusic")
                am force-stop "$PKG_NAME_YTM"
                ;;
            "Both"|*)
                am force-stop "$PKG_NAME_YT"
                am force-stop "$PKG_NAME_YTM"
                ;;
        esac

        # Eliminar APKs de ReVanced según la elección del usuario
        case "$USER_CHOICE" in
            "YouTube")
                local rv_apk="/data/adb/revanced/${MODNAME}_${PKG_NAME_YT##*.}.apk"
                [ -f "$rv_apk" ] && rm -f "$rv_apk" || status=$?
                ;;
            "YTMusic")
                local rv_apk="/data/adb/revanced/${MODNAME}_${PKG_NAME_YTM##*.}.apk"
                [ -f "$rv_apk" ] && rm -f "$rv_apk" || status=$?
                ;;
            "Both"|*)
                for pkg in "$PKG_NAME_YT" "$PKG_NAME_YTM"; do
                    local rv_apk="/data/adb/revanced/${MODNAME}_${pkg##*.}.apk"
                    [ -f "$rv_apk" ] && rm -f "$rv_apk" || status=$?
                done
                ;;
        esac
    else
        # Si no hay config, limpiar cualquier APK relacionado
        rm -f "/data/adb/revanced/${MODNAME}"_*.apk || status=$?
    fi
    
    # Limpiar directorio ReVanced si está vacío
    if [ -d "/data/adb/revanced" ]; then
        if [ -z "$(ls -A /data/adb/revanced)" ]; then
            rmdir "/data/adb/revanced" 2>/dev/null || status=$?
        fi
    fi
    
    # Desmontar montajes residuales de manera más eficiente
    if [ -f "$MODDIR/config" ]; then
        case "$USER_CHOICE" in
            "YouTube")
                grep "$PKG_NAME_YT" /proc/mounts 2>/dev/null | while read -r line; do
                    mp=${line#* } mp=${mp%% *}
                    umount -l "${mp%%\\*}" 2>/dev/null
                done
                ;;
            "YTMusic")
                grep "$PKG_NAME_YTM" /proc/mounts 2>/dev/null | while read -r line; do
                    mp=${line#* } mp=${mp%% *}
                    umount -l "${mp%%\\*}" 2>/dev/null
                done
                ;;
            "Both"|*)
                for pkg in "$PKG_NAME_YT" "$PKG_NAME_YTM"; do
                    grep "$pkg" /proc/mounts 2>/dev/null | while read -r line; do
                        mp=${line#* } mp=${mp%% *}
                        umount -l "${mp%%\\*}" 2>/dev/null
                    done
                done
                ;;
        esac
    else
        # Fallback para desmontar sin config
        for pkg in "com.google.android.youtube" "com.google.android.apps.youtube.music"; do
            grep "$pkg" /proc/mounts 2>/dev/null | while read -r line; do
                mp=${line#* } mp=${mp%% *}
                umount -l "${mp%%\\*}" 2>/dev/null
            done
        done
    fi
    
    # Limpiar archivos temporales y de configuración
    rm -f "$MODDIR/revanced.prop" 2>/dev/null
    rm -f "$MODDIR/loaded" 2>/dev/null
    rm -f "$MODDIR/.user_choice" 2>/dev/null
    
    return $status
}

# Ejecutar limpieza en segundo plano con timeout
{
    cleanup
    # Asegurar que todas las apps están detenidas después de la limpieza
    am force-stop "com.google.android.youtube"
    am force-stop "com.google.android.apps.youtube.music"
} &

# Dar más tiempo para la limpieza completa
sleep 2