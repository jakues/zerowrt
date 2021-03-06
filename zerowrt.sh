#!/usr/bin/bash
#!/usr/bin/zsh

# Set var
export OPENWRT_ORIGINAL_URL="https://downloads.openwrt.org/releases"
export OPENWRT_RASPI="bcm27xx"
export ECMD="echo"
export SLP="sleep 1"

# Select OpenWrt version from official repository
OPENWRT_VERSION () {
    ${SLP} ; ${ECMD}
    PS3="Select version : [ctrl+c to quit] "
    opts1=("21.02.0-rc1" "21.02.0-rc2" "21.02.0-rc3")
        select opt in "${opts1[@]}"
        do
            case $opt in
                "21.02.0-rc1")
                    export OPENWRT_VERZION="21.02.0-rc1"
                    break
                    ;;
                "21.02.0-rc2")
                    export OPENWRT_VERZION="21.02.0-rc2"
                    break
                    ;;
                "21.02.0-rc3")
                    export OPENWRT_VERZION="21.02.0-rc3"
                    break
                    ;;
                *)
                    ${ECMD} "invalid option $REPLY"
                    ;;
            esac
        done
    ${ECMD} -e "Selected Version : ${OPENWRT_VERZION}\n" ; ${SLP}
}

# Select Raspberry Pi Model
OPENWRT_MODEL () {
export MODEL_1="Raspberry Pi 1 (32 bit) compatible on pi 0,0w,1B,1B+"
export MODEL_2="Raspberry Pi 2 (32 bit) compatible on pi 2B,2B+,3B,3B+,CM3,4B,CM4"
export MODEL_3="Raspberry Pi 3 (64 bit) compatible on pi 3B,3B+,CM3"
export MODEL_4="Raspberry Pi 4 (64 bit) compatible on pi 4B,CM4"
        ${ECMD} "   ───────────────────────────────────────────────────────────────────────────────"
        ${ECMD} "   │  Model  │                           Descriptions                            │"
        ${ECMD} "   ───────────────────────────────────────────────────────────────────────────────"
        ${ECMD} "   │ bcm2708 │ ${MODEL_1}              │"
        ${ECMD} "   │ bcm2709 │ ${MODEL_2} │"
        ${ECMD} "   │ bcm2710 │ ${MODEL_3}               │"
        ${ECMD} "   │ bcm2711 │ ${MODEL_4}                   │"
        ${ECMD} "   ───────────────────────────────────────────────────────────────────────────────"
        ${ECMD} ; ${SLP}
            PS3="Select RaspberryPi model : [ctrl+c to quit] "
            opts2=("bcm2708" "bcm2709" "bcm2710" "bcm2711")
                select opt in "${opts2[@]}"
                do
                    case $opt in
                        "bcm2708")
                            export MODEL_ARCH="bcm2708"
                            export INFO_MODEL="rpi"
                            export ARCH="arm_arm1176jzf-s_vfp"
                            export MODELL="${MODEL_1}"
                            break
                            ;;
                        "bcm2709")
                            export MODEL_ARCH="bcm2709"
                            export INFO_MODEL="rpi-2"
                            export ARCH="arm_cortex-a7_neon-vfpv4"
                            export MODELL="${MODEL_2}"
                            break
                            ;;
                        "bcm2710")
                            export MODEL_ARCH="bcm2710"
                            export INFO_MODEL="rpi-3"
                            export ARCH="aarch64_cortex-a53"
                            export MODELL="${MODEL_3}"
                            break
                            ;;
                        "bcm2711")
                            export MODEL_ARCH="bcm2711"
                            export INFO_MODEL="rpi-4"
                            export ARCH="aarch64_cortex-a53"
                            export MODELL="${MODEL_4}"
                            break
                            ;;
                        *)
                            ${ECMD} "invalid option $REPLY"
                            ;;
                    esac
                done
        ${ECMD} -e "Selected model: ${INFO_MODEL}\n" ; ${SLP}
}

OPENWRT_SIZE () {
    # Set partition size of kernel
    read -r -p "Write size of /boot [Mb] : " BOOTFS
    ${ECMD} -e "CONFIG_TARGET_KERNEL_PARTSIZE=${BOOTFS}\n"
    ${SLP}
    # Set partition size of /rootfs
    read -r -p "Write size of /root [Mb] : " ROOTFS
    ${ECMD} -e "CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS}\n"
    ${SLP}
}

# Preparation before cooking ZeroWrt
OPENWRT_PREPARE () {
export IMAGEBUILDER_DIR="openwrt-imagebuilder-${OPENWRT_VERZION}-${OPENWRT_RASPI}-${MODEL_ARCH}.Linux-x86_64"
export IMAGEBUILDER_FILE="${IMAGEBUILDER_DIR}.tar.xz"
export IMAGEBUILDER_URL="${OPENWRT_ORIGINAL_URL}/${OPENWRT_VERZION}/targets/${OPENWRT_RASPI}/${MODEL_ARCH}/${IMAGEBUILDER_FILE}"
export ROOT_DIR="${IMAGEBUILDER_DIR}/files"
export HOME_DIR="${ROOT_DIR}/root"
        ${ECMD} -e "Preparing Tools\n" \
            ; wget -q ${IMAGEBUILDER_URL} \
            ; tar xf ${IMAGEBUILDER_FILE} \
            ; rm ${IMAGEBUILDER_FILE} \
            ; cp packages.txt ${IMAGEBUILDER_DIR} \
            ; cp disabled.txt ${IMAGEBUILDER_DIR} \
            ; wget -q -P ${IMAGEBUILDER_DIR}/ https://github.com/lutfailham96/libernet/raw/main/binaries.txt \
            ; export ZEROWRT_PACKAGES="$(echo $(cat packages.txt))" \
            ; export ZEROWRT_DISABLED="$(echo $(cat disabled.txt))"
        ${ECMD} -e "Preparing Data\n" \
            ; mkdir -p ${ROOT_DIR} \
            ; cp -arf $(pwd)/data/* ${ROOT_DIR} \
            ; cd ${IMAGEBUILDER_DIR} \
            ; sed -i -e "s/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=${BOOTFS}/" .config \
            ; sed -i -e "s/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS}/" .config \
            ; git clone https://github.com/ohmyzsh/ohmyzsh.git files/root/.oh-my-zsh \
            ; mkdir -p packages \
            ; export V2RAY_VERSION="4.39.2-1" \
            ; wget -q -P packages/ https://github.com/kuoruan/openwrt-v2ray/releases/download/v${V2RAY_VERSION}/v2ray-core_${V2RAY_VERSION}_${ARCH}.ipk \
            ; ${ECMD} "src v2ray-core file:packages" >> repositories.conf
        ${ECMD} -e "Preparation Done\n"
}

LIBERNET_PREPARE () {
    while IFS= read -r line; do
        if ! which ${line} > /dev/null 2>&1 ; then
        bin="files/usr/bin/${line}"
        echo "Installing ${line} ..."
        curl -sLko "${bin}" "https://github.com/lutfailham96/libernet-proprietary/raw/main/${ARCH}/binaries/${line}"
        chmod +x "${bin}"
        fi
    done < binaries.txt
}

# Cook the image
OPENWRT_BUILD () {
    make image PROFILE="${INFO_MODEL}" \
    FILES="files/" EXTRA_IMAGE_NAME="zerowrt" \
    PACKAGES="${ZEROWRT_PACKAGES}" DISABLED_SERVICES="${ZEROWRT_DISABLED}"
}

main () {
    OPENWRT_VERSION
    OPENWRT_MODEL
    OPENWRT_SIZE
    OPENWRT_PREPARE
    LIBERNET_PREPARE
    OPENWRT_BUILD
}

main
