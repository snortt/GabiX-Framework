#!/bin/bash
#
# make-iso
#
# Este script cria uma imagem ISO do GabiX
# 
# Gabriel Marques - snortt@gmail.com
# Seg Jun  6 12:00:02 BRT 2011
#

GENISO="$(which genisoimage)"

# Carrega as definições globais
. includes.rc

if [ ! -f "$GENISO" ]; then
    printMsg " "
    printError "Não achei ${ERRO}genisoimage${TEXTO}" && exit 201
fi

if [ $# -ne 1 ]; then
    printMsg "Uso: ${0##*/} <gabix_cdroot_dir>"
	exit 202
else
	# Vamos ver qual boot loader utilizar
    case $BOOT_LOADER in
    	"grub") 
			bootfile="boot/grub/iso9660_stage1_5"
			bootcatfile="boot/grub/boot.cat"
		;;

		"isolinux") 
			bootfile="boot/isolinux/isolinux.bin"
			bootcatfile="boot/isolinux/boot.cat"
		;;
	esac
    	
    #printMsg " "
    printMsg "Gerando arquivo ISO para ${DEV}${NOMESTR}${TEXTO} usando ${AVISO}${BOOT_LOADER}"
	genisoimage -l -r -J -v -publisher "${PUBLISHERSTR}" -preparer "${PUBLISHERSTR}" -V "${PUBLISHERSTR}" \
        -iso-level 4 -R -U -hide-rr-moved \
		-cache-inodes -no-bak -pad -no-emul-boot -boot-info-table \
		-b ${bootfile} -c ${bootcatfile} -boot-load-size 4 \
        -o "${ISOFILESTR}" "$1"/ > /dev/null 2>&1 && printOK "${NOMESTR} : ISO : " || printError "${NOMESTR} : ISO : "

	chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${ISOFILESTR} && printOK "Posse de ${NOMESTR} ISO : " || printError "Posse de ${NOMESTR} ISO : "
fi


