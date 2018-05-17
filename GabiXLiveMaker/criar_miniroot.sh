#!/bin/bash
#
# criar_miniroot.sh 
# 
# Este script cria uma imagem miniroot compactada.
#
# Gabriel Marques - snortt@gmail.com
# Sex Dez  4 14:46:58 BRST 2009 

# Carrega as definições globais
. includes.rc

if [ $# -lt 1 ]; then
    printMsg "Uso: ${0##*/} <miniroot_dir>"
	exit 201
fi

if [ ! -d $ROOTDIR ]; then
    printMsg "${VERMELHO}Erro${TEXTO}. Nao achei ${DEV}$ROOTDIR"
	printMsg "Experimente executar ${AVISO}make help"
	exit 202
else
    printMsg " "
    printMsg "Removendo arquivo ${DEV}${INITRD_NAME_GZ} ${TEXTO}anterior"
	if [ -f ${BOOTDIR}/${INITRD_NAME_GZ} ]; then 
        rm ${BOOTDIR}/${INITRD_NAME_GZ}
        printOK
    else
        printWarn "${DEV}${INITRD_NAME_GZ} ${RESET}anterior nao encontrado. Sem problemas! : "
    fi

	# ====================
	# Detectar arquitetura
	# ====================
	# Antes de prosseguir, vamos detectar a arquitetura.
    # ARM precisa de tratamentos diferenciados ;-)
	# Uma vez detectada a arquitetura, basta editar os templates apropriados
	# (veja confs/boot/) e, se necessário, o arquivo "funções" dentro 
	# de miniroot/etc/.
    printMsg " "
	detect_arch
	arch=$(cat ${arch_control_file})
		
	case ${arch} in 
		"armel")
			printMsg "Ajustando template para ARM"
			MINIROOT_INIT_TEMPLATE="${MINIROOT_INIT_TEMPLATE_ARM}"
			MINIROOT_FUNCOES_TEMPLATE="${MINIROOT_FUNCOES_TEMPLATE_ARM}"
			;;
		"x86"|"x86_64")
			printMsg "Ajustando template para PC"
			# Aqui precisamos verificar qual bootloader foi selecionad.
			printMsg "Usando ${VERDE}${BOOT_LOADER}"			
			case ${BOOT_LOADER} in
				"grub")
					MINIROOT_INIT_TEMPLATE="${MINIROOT_INIT_TEMPLATE_GRUB}"
					MINIROOT_FUNCOES_TEMPLATE="${MINIROOT_FUNCOES_TEMPLATE_GRUB}"
					;;
				"isolinux")
					MINIROOT_INIT_TEMPLATE="${MINIROOT_INIT_TEMPLATE_ISOLINUX}"
					MINIROOT_FUNCOES_TEMPLATE="${MINIROOT_FUNCOES_TEMPLATE_ISOLINUX}"
					;;
			esac
			;;
		*) printMsg "Problema ao detectar arquitetura para construir miniroot"
		   printError "Isso é um erro sério! Abortado."
		   exit 203
		   ;;
	esac

	cd $ROOTDIR

	# ====================
	# AJUSTES NO MINIROOT
	# ====================
	#
	# Arquivo /init  
    printMsg " "
	printMsg "Criando arquivo init no miniroot"
	printMsg "Usando $(basename ${MINIROOT_INIT_TEMPLATE})"
    
    cat ${MINIROOT_INIT_TEMPLATE} > ${MINIROOT_INIT} && \
		printOK "init :: ${MINIROOT_INIT#*miniroot} :: " || printError "init :: ${MINIROOT_INIT#*miniroot} :: "

    printMsg "Ajustando o nome para ${DEV}$NOMESTR"
    sed -i s/"__NOMESTR__/${NOMESTR}"/g ${MINIROOT_INIT} && \
		printOK "init :: $NOMESTR :: " || printError "init :: $NOMESTR :: "

	printMsg " "
	printMsg "Ajustando tamanho da área de memória para TMPFS usada pelo /dev"
    sed -i s/"__TMPFS_SIZE__/${TMPFS_SIZE}"/g ${MINIROOT_INIT} && \
		printOK "init :: ${TMPFS_SIZE} :: " || printError "init :: $TMPFS_SIZE :: "

	printMsg " "
	printMsg "Ajustando permissões do diretório /dev"	
    sed -i s/"__TMPFS_MODE__/${TMPFS_MODE}"/g ${MINIROOT_INIT} && \
		printOK "init :: ${TMPFS_MODE} :: " || printError "init :: $TMPFS_MODE :: "

	printMsg " "
	printMsg "Aplicando permissões no arquivo init"
    chmod +x ${MINIROOT_INIT} && printOK "Permissao exec :: init :: $NOMESTR :: " || printError "Permissao exec :: init :: $NOMESTR :: "

	# Arquivo /etc/funcoes.rc
	printMsg " "
	printMsg "Criando arquivo funcoes.rc no miniroot/etc/"
    cat ${MINIROOT_FUNCOES_TEMPLATE} > ${MINIROOT_FUNCOES} && \
		printOK "init :: ${MINIROOT_FUNCOES#*miniroot} :: " || printError "init :: ${MINIROOT_FUNCOES#*miniroot} :: "



	# =================================================
	# Criação da imagem initramfs, a partir do miniroot
	# =================================================
    printMsg " "
    printMsg "Criando imagem initramfs em ${DEV}${INITRD_NAME_GZ}"
	find . | cpio --quiet -o -H newc | gzip > ../${INITRD_NAME_GZ} && printOK || printError
	cd ../

    printMsg " "
    printMsg "Movendo ${DEV}${INITRD_NAME_GZ} ${TEXTO}para ${DEV}gabix/boot/${INITRD_NAME_GZ}"
	mv ${INITRD_NAME_GZ} ${BOOTDIR}/ && printOK || printError

	# Aqui usaremos o redirecionador ">" para zerar os arquivos existentes e populá-los à medida 
	# em que avançarmos nas configurações e tarefas deste arquivo.
    printMsg " "
    printMsg "Construindo menu de inicializacao do sistema usando ${ACERTO}${BOOT_LOADER}."
    case ${BOOT_LOADER} in
		"grub")
			cat ${GRUBCFG_TEMPLATE} | sed s/__VERSAO__/$KERNELVERSION/g > ${GRUBCFG} && printOK "${NOMESTR} :: Menu :: " || printError "${NOMESTR} :: Menu :: "
			cat ${GRUBCFG_TEMPLATE_LOCAL} | sed s/__VERSAO__/$KERNELVERSION/g > ${GRUBCFG_LOCAL} && printOK "${NOMESTR} :: Local :: " || printError "${NOMESTR} :: Local :: "	
			cat ${GRUBCFG_TEMPLATE_TOOLS} | sed s/__VERSAO__/$KERNELVERSION/g > ${GRUBCFG_TOOLS} && printOK "${NOMESTR} :: Tools :: " || printError "${NOMESTR} :: Tools :: "
			cat ${GRUBCFG_TEMPLATE_INSTALLDEB} | sed s/__VERSAO__/$KERNELVERSION/g > ${GRUBCFG_INSTALLDEB} && printOK "${NOMESTR} :: Installdeb :: " || printError "${NOMESTR} :: Installdeb :: "
			;;
		"isolinux")
			cat ${ISOLINUXCFG_TEMPLATE} | sed s/__VERSAO__/$KERNELVERSION/g > ${ISOLINUXCFG} && printOK "${NOMESTR} :: Menu :: " || printError "${NOMESTR} :: Menu :: "
			cat ${ISOLINUXCFG_TEMPLATE_LOCAL} | sed s/__VERSAO__/$KERNELVERSION/g > ${ISOLINUXCFG_LOCAL} && printOK "${NOMESTR} :: Local :: " || printError "${NOMESTR} :: Local :: "	
			cat ${ISOLINUXCFG_TEMPLATE_TOOLS} | sed s/__VERSAO__/$KERNELVERSION/g > ${ISOLINUXCFG_TOOLS} && printOK "${NOMESTR} :: Tools :: " || printError "${NOMESTR} :: Tools :: "
			#cat ${ISOLINUXCFG_TEMPLATE_INSTALLDEB} | sed s/__VERSAO__/$KERNELVERSION/g > ${ISOLINUXCFG_INSTALLDEB} && printOK "${NOMESTR} :: Installdeb :: " || printError "${NOMESTR} :: Installdeb :: "
			
			printMsg "Ajustando layout do menu"
			sed -e s/__ISOLINUX_MROWS__/"${ISOLINUX_MROWS}"/g \
				-e s/__ISOLINUX_MWIDTH__/"${ISOLINUX_MWIDTH}"/g \
				-e s/__ISOLINUX_TMSGROW__/"${ISOLINUX_TMSGROW}"/g \
				-e s/__ISOLINUX_MVSHIFT__/"${ISOLINUX_MVSHIFT}"/g \
				-e s/__ISOLINUX_MHSHIFT__/"${ISOLINUX_MHSHIFT}"/g \
				-e s/__ISOLINUX_MTIMEOUTROW__/"${ISOLINUX_MTIMEOUTROW}"/g -i ${ISOLINUXCFG} && \
				printOK "${ISOLINUXCFG}" || printError "${ISOLINUXCFG}"

			sed -e s/__ISOLINUX_MROWS__/"${ISOLINUX_MROWS}"/g \
				-e s/__ISOLINUX_MWIDTH__/"${ISOLINUX_MWIDTH}"/g \
				-e s/__ISOLINUX_TMSGROW__/"${ISOLINUX_TMSGROW}"/g \
				-e s/__ISOLINUX_MVSHIFT__/"${ISOLINUX_MVSHIFT}"/g \
				-e s/__ISOLINUX_MHSHIFT__/"${ISOLINUX_MHSHIFT}"/g \
				-e s/__ISOLINUX_MTIMEOUTROW__/"${ISOLINUX_MTIMEOUTROW}"/g -i ${ISOLINUXCFG_LOCAL} && \
				printOK "${ISOLINUXCFG_LOCAL}" || printError "${ISOLINUXCFG_LOCAL}"
				
			sed -e s/__ISOLINUX_MROWS__/"${ISOLINUX_MROWS}"/g \
				-e s/__ISOLINUX_MWIDTH__/"${ISOLINUX_MWIDTH}"/g \
				-e s/__ISOLINUX_TMSGROW__/"${ISOLINUX_TMSGROW}"/g \
				-e s/__ISOLINUX_MVSHIFT__/"${ISOLINUX_MVSHIFT}"/g \
				-e s/__ISOLINUX_MHSHIFT__/"${ISOLINUX_MHSHIFT}"/g \
				-e s/__ISOLINUX_MTIMEOUTROW__/"${ISOLINUX_MTIMEOUTROW}"/g -i ${ISOLINUXCFG_TOOLS} && \
				printOK "${ISOLINUXCFG_TOOLS}" || printError "${ISOLINUXCFG_TOOLS}"
			;;
	esac 
	
	printMsg " "
	printMsg "Ajustando configuracoes de rede"
	if [ "$NETWORK_MODE" == "static" ]; then
		case ${BOOT_LOADER} in
			"grub")
				sed -i s/__NETMODE__/"${NETWORK_MODE}"/g ${GRUBCFG} && printOK "$NETWORK_MODE :: Menu :: " || printError "$NETWORK_MODE :: Menu :: "
				sed -i s/__NETIP__/"${NETWORK_IP}"/g ${GRUBCFG} && printOK "$NETWORK_IP :: Menu :: " || printError "$NETWORK_IP :: Menu :: "
				sed -i s/__NETMASK__/"${NETWORK_MASK}"/g ${GRUBCFG} && printOK "$NETWORK_MASK :: Menu :: " || printError "$NETWORK_MASK :: Menu :: "
				sed -i s/__NETDNS__/"${NETWORK_DNS}"/g ${GRUBCFG} && printOK "$NETWORK_DNS :: Menu :: " || printError "$NETWORK_DNS :: Menu :: "
				sed -i s/__NETGTWY__/"${NETWORK_GATEWAY}"/g ${GRUBCFG} && printOK "$NETWORK_GATEWAY :: Menu :: " || printError "$NETWORK_GATEWAY :: Menu :: "
			;;
			"isolinux")
				sed -i s/__NETMODE__/"${NETWORK_MODE}"/g ${ISOLINUXCFG} && printOK "$NETWORK_MODE :: Menu :: " || printError "$NETWORK_MODE :: Menu :: "
				sed -i s/__NETIP__/"${NETWORK_IP}"/g ${ISOLINUXCFG} && printOK "$NETWORK_IP :: Menu :: " || printError "$NETWORK_IP :: Menu :: "
				sed -i s/__NETMASK__/"${NETWORK_MASK}"/g ${ISOLINUXCFG} && printOK "$NETWORK_MASK :: Menu :: " || printError "$NETWORK_MASK :: Menu :: "
				sed -i s/__NETDNS__/"${NETWORK_DNS}"/g ${ISOLINUXCFG} && printOK "$NETWORK_DNS :: Menu :: " || printError "$NETWORK_DNS :: Menu :: "
				sed -i s/__NETGTWY__/"${NETWORK_GATEWAY}"/g ${ISOLINUXCFG} && printOK "$NETWORK_GATEWAY :: Menu :: " || printError "$NETWORK_GATEWAY :: Menu :: "
			;;
		esac
	else
		case ${BOOT_LOADER} in
			"grub")
				sed -i s/__NETMODE__/"${NETWORK_MODE}"/g ${GRUBCFG} && printOK "$NETWORK_MODE :: Menu :: " || printError "$NETWORK_MODE :: Menu :: "
				sed -i s/__NETIP__/" "/g ${GRUBCFG} && printOK "IP (null) :: Menu :: " || printError "IP (null) :: Menu :: "
				sed -i s/__NETMASK__/" "/g ${GRUBCFG} && printOK "Mask (null) :: Menu :: " || printError "Mask (null) :: Menu :: "
				sed -i s/__NETDNS__/" "/g ${GRUBCFG} && printOK "DNS (null) :: Menu :: " || printError "DNS (null) :: Menu :: "
				sed -i s/__NETGTWY__/" "/g ${GRUBCFG} && printOK "Gateway (null) :: Menu :: " || printError "Gateway (null) :: Menu :: "
				sed -i s/\ \ */\ /g ${GRUBCFG} && printOK "Ajuste de espacos em branco :: Menu :: " || printError "Ajuste de espacos em branco ::Menu :: "
				;;
			"isolinux")
				sed -i s/__NETMODE__/"${NETWORK_MODE}"/g ${ISOLINUXCFG} && printOK "$NETWORK_MODE :: Menu :: " || printError "$NETWORK_MODE :: Menu :: "
				sed -i s/__NETIP__/" "/g ${ISOLINUXCFG} && printOK "IP (null) :: Menu :: " || printError "IP (null) :: Menu :: "
				sed -i s/__NETMASK__/" "/g ${ISOLINUXCFG} && printOK "Mask (null) :: Menu :: " || printError "Mask (null) :: Menu :: "
				sed -i s/__NETDNS__/" "/g ${ISOLINUXCFG} && printOK "DNS (null) :: Menu :: " || printError "DNS (null) :: Menu :: "
				sed -i s/__NETGTWY__/" "/g ${ISOLINUXCFG} && printOK "Gateway (null) :: Menu :: " || printError "Gateway (null) :: Menu :: "
				sed -i s/\ \ */\ /g ${GRUBCFG} && printOK "Ajuste de espacos em branco :: Menu :: " || printError "Ajuste de espacos em branco ::Menu :: "
				;;
		esac
	fi

    printMsg " "
    printMsg "Ajustando o nome para ${AVISO}$NOMESTR ${TEXTO}no menu do sistema."
    case ${BOOT_LOADER} in
		"grub")
			sed -i s/__NOMESTR__/"${NOMESTR}"/g ${GRUBCFG} && printOK "$NOMESTR :: Menu :: " || printError "$NOMESTR :: Menu :: "
			sed -i s/__NOMESTR__/"${NOMESTR}"/g ${GRUBCFG_LOCAL} && printOK "$NOMESTR :: Local :: " || printError "$NOMESTR :: Local :: "
			sed -i s/__NOMESTR__/"${NOMESTR}"/g ${GRUBCFG_TOOLS} && printOK "$NOMESTR :: Tools :: " || printError "$NOMESTR :: Tools :: "
			sed -i s/__NOMESTR__/"${NOMESTR}"/g ${GRUBCFG_INSTALLDEB} && printOK "$NOMESTR :: Installdeb :: " || printError "$NOMESTR :: Installdeb :: "
		;;
		"isolinux")
			sed -i s/__NOMESTR__/"${NOMESTR}"/g ${ISOLINUXCFG} && printOK "$NOMESTR :: Menu :: " || printError "$NOMESTR :: Menu :: "
			sed -i s/__NOMESTR__/"${NOMESTR}"/g ${ISOLINUXCFG_LOCAL} && printOK "$NOMESTR :: Local :: " || printError "$NOMESTR :: Local :: "
			sed -i s/__NOMESTR__/"${NOMESTR}"/g ${ISOLINUXCFG_TOOLS} && printOK "$NOMESTR :: Tools :: " || printError "$NOMESTR :: Tools :: "
			#sed -i s/__NOMESTR__/"${NOMESTR}"/g ${ISOLINUXCFG_INSTALLDEB} && printOK "$NOMESTR :: Installdeb :: " || printError "$NOMESTR :: Installdeb :: "
		;;		
	esac
	
    printMsg " "
    printMsg "Ajustando resolucao inicial para ${AVISO}$VGASTR ${TEXTO}no menu do sistema."
    case ${BOOT_LOADER} in
		"grub")
			sed -i s/__VGASTR__/"${VGASTR}"/g ${GRUBCFG} && printOK "$VGASTR :: Menu :: " || printError "$VGASTR :: Menu :: "
			sed -i s/__VGASTR__/"${VGASTR}"/g ${GRUBCFG_LOCAL} && printOK "$VGASTR :: Local :: " || printError "$VGASTR :: Local :: "
			sed -i s/__VGASTR__/"${VGASTR}"/g ${GRUBCFG_TOOLS} && printOK "$VGASTR :: Tools :: " || printError "$VGASTR :: Tools :: "
			sed -i s/__VGASTR__/"${VGASTR}"/g ${GRUBCFG_INSTALLDEB} && printOK "$VGASTR :: Installdeb :: "	|| printError "$VGASTR :: Installdeb :: "
		;;
		"isolinux")
			sed -i s/__VGASTR__/"${VGASTR}"/g ${ISOLINUXCFG} && printOK "$VGASTR :: Menu :: " || printError "$VGASTR :: Menu :: "
			sed -i s/__VGASTR__/"${VGASTR}"/g ${ISOLINUXCFG_LOCAL} && printOK "$VGASTR :: Local :: " || printError "$VGASTR :: Local :: "
			sed -i s/__VGASTR__/"${VGASTR}"/g ${ISOLINUXCFG_TOOLS} && printOK "$VGASTR :: Tools :: " || printError "$VGASTR :: Tools :: "
			#sed -i s/__VGASTR__/"${VGASTR}"/g ${ISOLINUXCFG_INSTALLDEB} && printOK "$VGASTR :: Installdeb :: "	|| printError "$VGASTR :: Installdeb :: "
		;;
	esac
	
    printMsg " "
	chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${GABIXROOTDIR}/ && printOK "Posse de ${NOMESTR} BASE : " || printError "Posse de ${NOMESTR} BASE : "
    chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${MINIROOTDIR}/ && printOK "Posse de ${NOMESTR} Miniroot : " || printError "Posse de ${NOMESTR} Miniroot : "
fi

