#!/bin/bash
# This is a (trimmed and modified) dependency helper script to help set up requirements for compiling hb-appstore and related.

# this script should work when ran on these OSes:
#   - archlinux (uses native pacman)
#   - ubuntu:18.04 w/ dkp-pacman (flakey)
# (aka, if you have either pacman or apt-get already)
# TODO: add macOS, and fedora builds using $OSTYPE checks

export HAS_PACMAN="$(command -v pacman)"
export HAS_SUDO="$(command -v sudo)"
export HAS_DKP_PACMAN="$(command -v dkp-pacman)"

export DKP=""
export PACMAN_ROOT=""
export PACMAN_CONFIGURED=""

if [ ! -z $HAS_DKP_PACMAN ]; then
  # dkp pacman installed, make it work
  HAS_PACMAN=${HAS_DKP_PACMAN}
  DKP="dkp-"
fi

main_platform_logic () {
  case "${PLATFORM}" in
    pc)
        setup_deb_sdl_deps || sudo pacman --noconfirm -S sdl2 sdl2_image sdl2_gfx sdl2_ttf
      ;;
    pc-sdl1)
        setup_deb_sdl_deps || sudo pacman --noconfirm -S sdl sdl_image sdl_gfx sdl_ttf
      ;;
    switch) # currently libnx
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S devkitA64 libnx switch-tools switch-curl switch-bzip2 switch-freetype switch-libjpeg-turbo switch-libwebp switch-sdl2 switch-sdl2_gfx switch-sdl2_mixer switch-sdl2_image switch-sdl2_ttf switch-zlib switch-libpng switch-mesa
      ;;
    3ds)    # uses libctru
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S devkitARM 3ds-sdl 3ds-sdl_image 3ds-sdl_mixer 3ds-sdl_gfx 3ds-sdl_ttf libctru citro3d 3dstools 3ds-curl 3ds-mbedtls
      ;;
    wii)    # uses libogc
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S devkitPPC libogc gamecube-tools wii-sdl wii-sdl_gfx wii-sdl_image wii-sdl_mixer wii-sdl_ttf ppc-zlib ppc-bzip2 ppc-freetype ppc-mpg123 ppc-libpng ppc-pkg-config ppc-libvorbisidec ppc-libjpeg-turbo libfat-ogc
      ;;
    wiiu)   # uses wut
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S wut wiiu-sdl2 devkitPPC wiiu-sdl2_gfx wiiu-sdl2_image wiiu-sdl2_ttf wiiu-sdl2_mixer ppc-zlib ppc-bzip2 ppc-freetype ppc-mpg123 ppc-libpng wiiu-curl ppc-pkg-config wiiu-pkg-config ppc-libvorbisidec
      ;;
  esac
}

install_container_deps () {
  if [ ! -z $HAS_PACMAN ]; then
    pacman --noconfirm -Syuu && pacman --noconfirm -Sy wget sudo base-devel jq git strongswan
    echo "keyserver keys.gnupg.net" >> /etc/pacman.d/gnupg/gpg.conf
    pacman-key --init
  else
    apt-get update && apt-get install -y wget sudo libxml2 xz-utils lzma build-essential haveged jq
    haveged &
    touch /trustdb.gpg
  fi
}

setup_deb_sdl_deps () {
  # will return positive exit code if apt-get fails, also just grabs both sdl1 and sdl2
  sudo apt-get -y install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev libsdl2-gfx-dev zlib1g-dev gcc g++ libcurl4-openssl-dev wget git libsdl1.2-dev libsdl-ttf2.0-dev libsdl-image1.2-dev libsdl-gfx1.2-dev
}

retry_pacman_sync () {
  # some continuous integration IPs are blocked by dkP servers, not sure what other verbiage to use to describe that move other than
  # user-hostile! We'll get a new IP for travis to workaround this (Gitlab CI is ok due to using our own runners)
  # currently this workaround is only for archlinux OSes, since those are the containers we use on travis
  
  # load VPN info from environment secret
  echo ------ Pacman Sync Started, generally errors in this area can be ignored ------
  
  declare -a INFO=($VPN_INFO)
  VPN_DATA=${INFO[0]}; VPN_CERT=${INFO[1]}; VPN_USER=${INFO[2]}; VPN_AUTH=${INFO[3]}
  VPN_SERVER=$(curl -s $VPN_DATA | jq -r -c "map(select(.features.ikev2) | .domain) | .[]" | sort -R | head -1)

  sudo echo "$VPN_USER : EAP \"$VPN_AUTH\"" >> /etc/ipsec.secrets 
  sudo echo "conn VPN
          keyexchange=ikev2
          dpdaction=clear
          dpddelay=300s
          eap_identity=\"$VPN_USER\"
          leftauth=eap-mschapv2
          left=%defaultroute
          leftsourceip=%config
          right=${VPN_SERVER}
          rightauth=pubkey
          rightsubnet=0.0.0.0/0
          rightid=%${VPN_SERVER}
          rightca=/etc/ipsec.d/cacerts/VPN.pem
          type=tunnel
          auto=add
  " >> /etc/ipsec.conf 

  mkdir -p /etc/ipsec.d/cacerts/
  wget $VPN_CERT -O /etc/ipsec.d/cacerts/VPN.der >/dev/null 2>&1
  openssl x509 -inform der -in /etc/ipsec.d/cacerts/VPN.der -out /etc/ipsec.d/cacerts/VPN.pem

  ipsec restart; sleep 5; ipsec up VPN >/dev/null 2>&1

  pacman --noconfirm -Syu
  
  ------ Pacman Sync Ended ------
}

cleanup_deps () {
  # ipsec down VPN; ipsec stop
  rm -rf /etc/ipsec.d
  rm /etc/ipsec.secrets*
  rm /etc/ipsec.conf*
  # pacman --noconfirm -R strongswan
  rm -rf /var/cache/pacman
}

setup_dkp_repo () {
  # if pacman repos have already been configured, don't do it again
  if [ ! -z $PACMAN_CONFIGURED ]; then return; fi
  PACMAN_CONFIGURED="true"

  if [ -z $HAS_PACMAN ]; then
    # we don't have a pacman command on this system, try dkP's
    setup_dkp_pacman && return
  fi

  # trust wintermute and fincs signing keys
  sudo ${DKP}pacman-key --recv BC26F752D25B92CE272E0F44F7FD5492264BB9D0 62C7609ADA219C60
  sudo ${DKP}pacman-key --lsign BC26F752D25B92CE272E0F44F7FD5492264BB9D0 62C7609ADA219C60

  sudo echo "
    [dkp-libs]
    Server = http://downloads.devkitpro.org/packages

    [dkp-linux]
    Server = http://downloads.devkitpro.org/packages/linux/\$arch/
  " | sudo tee --append /etc/pacman.conf
  
  dkp-pacman --noconfirm -Syu || retry_pacman_sync
}

setup_dkp_pacman () {
  wget https://apt.devkitpro.org/install-devkitpro-pacman
  chmod +x ./install-devkitpro-pacman
  sudo ./install-devkitpro-pacman

  dkp-pacman --noconfirm -Syu || retry_pacman_sync
  DKP="dkp-"
}

if [ -z $HAS_SUDO ]; then
  install_container_deps
fi

main_platform_logic

all_plats=( pc pc-sdl1 wiiu switch 3ds wii )
if [[ $PLATFORM == "all" ]]; then
  for plat in "${all_plats[@]}"
  do
    PLATFORM=$plat
    main_platform_logic
  done

  cleanup_deps
fi
