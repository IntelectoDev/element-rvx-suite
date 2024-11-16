# mount.sh
#!/system/bin/sh
mount_app() {
    local pkg_name=$1
    local rv_path="/data/adb/revanced/${MODDIR##*/}_${pkg_name##*.}.apk"
    local base_path

    base_path=$(pm path "$pkg_name" 2>&1 </dev/null)
    base_path=${base_path##*:}
    base_path=${base_path%/*}

    [ -z "$base_path/base.apk" ] && return 1

    grep "$pkg_name" /proc/mounts | while read -r line; do
        mp=${line#* } mp=${mp%% *}
        umount -l "${mp%%\\*}"
    done

    chcon u:object_r:apk_data_file:s0 "$rv_path"
    chmod 0755 "$rv_path"
    mount -o bind "$rv_path" "$base_path/base.apk"
}

USER_CHOICE=$(cat "$MODDIR/.user_choice" 2>/dev/null || echo "Both")
case "$USER_CHOICE" in
    "YouTube")
        mount_app "$PKG_NAME_YT"
        ;;
    "YTMusic")
        mount_app "$PKG_NAME_YTM"
        ;;
    "Both")
        mount_app "$PKG_NAME_YT"
        mount_app "$PKG_NAME_YTM"
        ;;
esac