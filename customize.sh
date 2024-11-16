#!/system/bin/sh

# Extraer VolumeKey-Selector
unzip -o "$MODPATH/addon/VolumeKey-Selector.zip" -d "$MODPATH/addon/VolumeKey-Selector" &>/dev/null || abort "! ❌ Unzip failed"

# Cargar VolumeKey-Selector si existe
if [ -f "$MODPATH/addon/VolumeKey-Selector/install.sh" ]; then
    . "$MODPATH/addon/VolumeKey-Selector/install.sh"
else
    abort "! ❌ Volume selector library not found"
fi

if ! $BOOTMODE; then
    ui_print "! Installing from Recovery is not supported."
    abort "! Please install this module using your root manager app."
fi

# Variables de aplicación y entorno
. "$MODPATH/config"
STOCK_APK_YT="$MODPATH/app/$PKG_NAME_YT.apk"
STOCK_APK_YTM="$MODPATH/app/$PKG_NAME_YTM.apk"
RV_APK_YT="$MODPATH/app/base_yt.apk"
RV_APK_YTM="$MODPATH/app/base_ytm.apk"
MOD_PATH_APP="$MODPATH/app"
MOD_PATH_BIN="$MODPATH/bin"
PMT_MODULE_PATH="/data/adb/modules/magisk_proc_monitor"
PMT_VER_REQ=10
PMT_URL="https://github.com/HuskyDG/magisk_proc_monitor/releases"

# Verificación de arquitectura
if [ -n "$MODULE_ARCH" ] && [ "$MODULE_ARCH" != "$ARCH" ]; then
    ui_print "Your device: $ARCH"
    ui_print "Module: $MODULE_ARCH"
    abort "! ERROR: Wrong arch"
fi

# Verificación de Process Monitor Tool (PMT)
retry_count=0
while [ ! -d "$PMT_MODULE_PATH" ] && [ "$retry_count" -lt 5 ]; do
    ui_print "* 🔍 Checking Process Monitor Tool... ($retry_count)"
    sleep 2
    retry_count=$((retry_count+1))
done
if [ "$retry_count" -ge 5 ]; then
    abort "! ❌ ERROR: Process Monitor Tool not available. Install from: $PMT_URL"
fi

PMT_VER_CODE="$(grep_prop versionCode "$PMT_MODULE_PATH/module.prop")"
if [ "$PMT_VER_CODE" -lt "$PMT_VER_REQ" ]; then
    abort "! ❌ ERROR: Process Monitor Tool v2.3 or higher required. Update from: $PMT_URL"
fi

if [ -f "$PMT_MODULE_PATH/disable" ] || [ -f "$PMT_MODULE_PATH/remove" ]; then
    abort "! ❌ ERROR: Process Monitor Tool is disabled or will be removed"
fi

# Configuración según arquitectura
case "$ARCH" in
    arm) ARCH_LIB=armeabi-v7a; alias cmpr='$MODPATH/bin/arm/cmpr' ;;
    arm64) ARCH_LIB=arm64-v8a; alias cmpr='$MODPATH/bin/arm64/cmpr' ;;
    x86) ARCH_LIB=x86; alias cmpr='$MODPATH/bin/x86/cmpr' ;;
    x64) ARCH_LIB=x86_64; alias cmpr='$MODPATH/bin/x64/cmpr' ;;
    *) abort "! ❌ ERROR: Unsupported arch: ${ARCH}" ;;
esac

# Configuración de permisos
if [ ! -d "$MOD_PATH_BIN" ]; then
    mkdir -p "$MOD_PATH_BIN"
fi
set_perm_recursive "$MOD_PATH_BIN" 0 0 0755 0777

# Verificación de root
if su -M -c true >/dev/null 2>/dev/null; then
    alias mm='su -M -c'
else
    alias mm='nsenter -t1 -m'
fi

# Menú de selección mejorado
ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "        🚀 ReVanced App Installer"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""

APP_CHOICE="Both"
if $BOOTMODE; then
    ui_print "     📱 Installation Options"
    ui_print ""
    sleep 1

    if selector "* 🤔 Would you like to install a single app?" null "Yes ✓" "No ✗"; then
        if selector "* 📥 Select your preferred app:" null "📺 YouTube" "🎵 YT Music"; then
            APP_CHOICE="YouTube"
            ui_print ""
            ui_print "     ✅ Selected: YouTube"
        else
            APP_CHOICE="YTMusic"
            ui_print ""
            ui_print "     ✅ Selected: YT Music"
        fi
    else
        APP_CHOICE="Both"
        ui_print ""
        ui_print "     ✅ Selected: Complete Package"
    fi

    ui_print ""
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print "           📋 Installation Summary"
    ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ui_print ""
    case $APP_CHOICE in
        "YouTube")
            ui_print "     📺 YouTube"
            ui_print "        ↳ Premium Features Included"
            ;;
        "YTMusic")
            ui_print "     🎵 YT Music"
            ui_print "        ↳ Extended Features Included"
            ;;
        "Both")
            ui_print "     📺 YouTube"
            ui_print "        ↳ Premium Features Included"
            ui_print "     🎵 YT Music"
            ui_print "        ↳ Extended Features Included"
            ;;
    esac
    ui_print ""
fi
# Guardar la elección del usuario
echo "$APP_CHOICE" > "$MODPATH/.user_choice"

# Establecer permisos y contexto de seguridad
chmod 0644 "$MODPATH/.user_choice"  # Permisos de lectura para todos, escritura solo para el propietario
chcon u:object_r:system_file:s0 "$MODPATH/.user_choice"  # Contexto de seguridad SELinux adecuado

ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "        📦 Starting Installation"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""

# Función para manejar la instalación de cada app
handle_app_installation() {
    local pkg_name=$1
    local stock_apk=$2
    local app_name=$3
    local pkg_ver=$4
    local rv_apk=$5

    INS=true
    BASEPATH=""

    ui_print "* 📦 Processing $app_name..."
    
    mm grep "$pkg_name" /proc/mounts | while read -r line; do
        ui_print "* 🔄 Un-mounting $app_name"
        mp=${line#* } mp=${mp%% *}
        mm umount -l "${mp%%\\*}"
    done
    am force-stop "$pkg_name"

    if BASEPATH=$(pm path "$pkg_name" 2>&1 </dev/null); then
        BASEPATH=${BASEPATH##*:} BASEPATH=${BASEPATH%/*}
        if [ "${BASEPATH:1:6}" = system ]; then
            ui_print "* 📱 $app_name is a system app"
        elif [ ! -d "${BASEPATH}/lib" ]; then
            ui_print "* ⚠️ Invalid installation found. Uninstalling $pkg_name..."
            pm uninstall -k --user 0 "$pkg_name"
        elif [ ! -f "$stock_apk" ]; then
            ui_print "* ❗ No stock APK found for $app_name"
            VERSION=$(dumpsys package "$pkg_name" | grep -m1 versionName) VERSION="${VERSION#*=}"
            if [ "$VERSION" = "$pkg_ver" ] || [ -z "$VERSION" ]; then
                ui_print "* ✅ Skipping stock APK installation for $app_name"
                INS=false
            else
                ui_print "* 📱 Installed version of $app_name = $VERSION"
                ui_print "* 📦 Module version = $pkg_ver"
                abort "! ❌ ERROR: Version mismatch"
            fi
        elif cmpr "$BASEPATH/base.apk" "$stock_apk"; then
            ui_print "* ✅ $app_name is up to date"
            INS=false
        fi
    fi

    if [ "$INS" = true ]; then
        install_app "$stock_apk" "$pkg_name" "$app_name" "$pkg_ver"
    fi

    if [ "$INS" = true ]; then
        BASEPATH=$(pm path "$pkg_name" 2>/dev/null | awk -F':' '{print $2}' | xargs dirname)
        local basepathlib="${BASEPATH}/lib/${ARCH}"
        if [ -z "$(ls -A1 "$basepathlib")" ]; then
            ui_print "* 📚 Extracting native libraries for $app_name"
            mkdir -p "$basepathlib"
            if ! unzip -j "$stock_apk" lib/"${ARCH_LIB}"/* -d "$basepathlib" >/dev/null 2>&1; then
                abort "! ❌ ERROR: Failed to extract native libraries for $app_name"
            fi
            set_perm_recursive "${BASEPATH}/lib" 1000 1000 755 755 u:object_r:apk_data_file:s0
        fi
    fi

    set_perm "$rv_apk" 1000 1000 644 u:object_r:apk_data_file:s0
    mkdir -p "/data/adb/revanced"
    mv -f "$rv_apk" "/data/adb/revanced/${MODPATH##*/}_${pkg_name##*.}.apk"
    
    am force-stop "$pkg_name"
    nohup cmd package compile --reset "$pkg_name" >/dev/null 2>&1 &
}

# Install based on selection
case $APP_CHOICE in
    "YouTube")
        ui_print "* 📺 Installing YouTube..."
        handle_app_installation "$PKG_NAME_YT" "$STOCK_APK_YT" "$APP_NAME_YT" "$PKG_VER_YT" "$RV_APK_YT"
        ;;
    "YTMusic")
        ui_print "* 🎵 Installing YT Music..."
        handle_app_installation "$PKG_NAME_YTM" "$STOCK_APK_YTM" "$APP_NAME_YTM" "$PKG_VER_YTM" "$RV_APK_YTM"
        ;;
    "Both")
        ui_print "* ✨ Installing both apps..."
        handle_app_installation "$PKG_NAME_YT" "$STOCK_APK_YT" "$APP_NAME_YT" "$PKG_VER_YT" "$RV_APK_YT"
        handle_app_installation "$PKG_NAME_YTM" "$STOCK_APK_YTM" "$APP_NAME_YTM" "$PKG_VER_YTM" "$RV_APK_YTM"
        ;;
esac

# Cleanup
ui_print "* 🧹 Cleaning up..."
rm -rf "${MODPATH:?}/app" "${MODPATH:?}/bin"
[ -d "$MODPATH/addon" ] && rm -rf "$MODPATH/addon"

ui_print ""
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "    ✅ Installation Complete!"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print ""