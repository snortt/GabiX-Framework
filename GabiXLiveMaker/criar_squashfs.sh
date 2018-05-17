#!/bin/bash
#
# criar_squashfs.sh
#
# Script para criar imagem squashfs do debian bootstrapped
# 
# Gabriel Marques
# snortt@gmail.com
# 
# Sex Mai  1 17:31:09 BRT 2011
#

# Carrega as definições globais
. includes.rc

if [ ! -x "$MAKEIT" ]; then
    printMsg "Voce precisa instalar ${ERRO}squashfs-tools"
    exit 201
fi

if [ "$(id -u)" -ne "0" ]; then
    printMsg "Voce precisa ser root"
    exit 202
fi

if [ $# -lt 1 ]; then
    printMsg "Uso: ${0##*/} <debian_root_dir>"
	exit 203
fi

if [ ! -d $ROOTDIR ]; then
    # Vamos só disparar um aviso, pois o miniroot funciona, mesmo 
    # sem roo-NFS no caso de um make all
    printWarn "Nao achei ${DEV}$ROOTDIR"
	exit 204
else
    printMsg " "
    printMsg "---------------------------------"
    printMsg "Removendo arquivo ${MAGENTA}${SQUASHFILE} ${TEXTO}anterior"
    printMsg "---------------------------------"
    # Caso o arquivo já tenha sido removido, vamos imprimir apenas um aviso.
    if [ -f "${BASEDIR}/${SQUASHFILE}" ]; then 
        rm "${BASEDIR}/${SQUASHFILE}" 2> /dev/null
        printOK
    else
        printWarn "${MAGENTA}${SQUASHFILE} ${RESET}anterior nao encontrado. Sem problemas! : "
    fi

    # Desligamento do /dev da imagem SquashFS. Deixe o kernel e o udev lidarem com isso na hora que 
    # eles carregarem live ;-)
    printMsg " "
    printMsg "-----------------------------------"
    printMsg "Desativando dispositivos em ${DEV}${ROOTDIR}"
    printMsg "-----------------------------------"
	# Busybox usa MDEV, uma versão miniatura de UDEV. Deixe que ele gerencie dispositivos.
	(tar cjf ${CONFS_PKGS_DIR}/dev_stuff.tar.bz2 ${ROOTDIR}/dev/ && rm -rf ${ROOTDIR}/dev/.{udev,initram}*) && printOK || printError

    # Ajustes nos arquivos de ambiente do sistema
    printMsg " "
    printMsg "------------------------------------------"
    printMsg "Ajustando nome do sistema para ${DEV}${NOMESTR_SYS}"
    printMsg "------------------------------------------"
    cat $NOMESTR_SYS_FILE_HOSTNAME_TEMPLATE | sed s/__NOMESTR_SYS__/"${NOMESTR_SYS}"/g > ${ROOTDIR}/${NOMESTR_SYS_FILE_HOSTNAME} && printOK "hostname :: " || printError printOK "hostname :: "
    cat $NOMESTR_SYS_FILE_HOSTS_TEMPLATE | sed s/__NOMESTR_SYS__/"${NOMESTR_SYS}"/g > ${ROOTDIR}/${NOMESTR_SYS_FILE_HOSTS} && printOK "hosts :: " || printError "hosts :: "
    cat $NOMESTR_SYS_FILE_MOTD_TEMPLATE | sed s/__NOMESTR__/"${NOMESTR_SYS}"/g > ${ROOTDIR}/${NOMESTR_SYS_FILE_MOTD} && printOK "motd :: " || printError "motd :: "
    cat $NOMESTR_SYS_FILE_ISSUE_TEMPLATE | sed s/__NOMESTR__/"${NOMESTR_SYS}"/g > ${ROOTDIR}/${NOMESTR_SYS_FILE_ISSUE} && printOK "issue :: " || printError "issue :: "

    # Ajustes no arquivo .bashrc do root.
    cat $NOMESTR_SYS_FILE_ROOTBASHRC_TEMPLATE | sed s/__NOMESTR_SYS__/"${NOMESTR_SYS}"/g > ${ROOTDIR}/${NOMESTR_SYS_FILE_ROOTBASHRC} && printOK "root.bashrc :: " || printError "root.bashrc :: "

    # Ajustes no arquivo .bashrc do usuário gabix.
    cat $NOMESTR_SYS_FILE_GABIXBASHRC_TEMPLATE | sed s/__NOMESTR_SYS__/"${NOMESTR_SYS}"/g > ${ROOTDIR}/${NOMESTR_SYS_FILE_GABIXBASHRC} && printOK "gabix.bashrc :: " || printError "gabix.bashrc :: "

    # Ajustes no .profile do usuário gabix.
    cp $NOMESTR_SYS_FILE_GABIXPROFILE_TEMPLATE ${ROOTDIR}/${NOMESTR_SYS_FILE_GABIXPROFILE} && printOK "gabix.profile :: " || printError "gabix.profile :: "
	if [ "$USE_XORG" -eq "1" ]; then
		printMsg "Carregamento automatico do X.org :: ${ACERTO}Ligado"
		(
		cat >> ${ROOTDIR}/${NOMESTR_SYS_FILE_GABIXPROFILE} <<-"FIM_USE_XORG"
		
		if [[ -z $DISPLAY && $(tty) = /dev/tty1 ]]; then
		#	# prefira a de baixo # exec xinit -- /usr/bin/X -nolisten tcp vt7
			exec startx
		fi
		FIM_USE_XORG
		) && printOK "X.org :: " || printError "X.org :: "
	else
		printMsg "Carregamento automatico do X.org :: ${ERRO}Desigado"
	fi


    # Aqui trataremos os recursos adicionais, controlados via rc.local, pós-boot do Debian.
    printMsg " "
    printMsg "Configurando ${DEV}rc.local${TEXTO}"

    # ---------------------------------------
    # Verificando suporte por drivers Nvidia.
    case "$USENVDRV" in 
	"0")
            printMsg "Removendo o driver ${AVISO}Nvidia ${TEXTO}."
	    rm -r ${GABIXNVDRVDIR}/  > /dev/null 2>&1 && printOK || \
	    printWarn "Existem arquivos la? : "

		cp ${NOMESTR_SYS_FILE_RCLOCAL_TEMPLATE} ${ROOTDIR}/${NOMESTR_SYS_FILE_RCLOCAL} && \
			printOK "rc.local :: ${AVISO}Nvidia ${RESET}:: " || \
			printError "rc.local :: ${AVISO}Nvidia ${RESET} :: "

		printMsg "Ligando carregamento do driver ${AVISO}Nouveau${TEXTO}"
		rm ${ROOTDIR}/${NOMESTR_SYS_FILE_NOUVEAU_OFF} > /dev/null 2>&1 && \
			printOK "nouveau on :: " || \
			printWarn "nouveau on :: Arquivo de bloqueio existe? :: "
		;;

		"1")
			printMsg "Habilitando uso do driver ${AVISO}Nvidia${TEXTO}"
			cat ${NOMESTR_SYS_FILE_RCLOCAL_TEMPLATE} | \
				sed s/"${STR_NVIDIA_OFF}/${STR_NVIDIA_ON}"/g > \
				${ROOTDIR}/${NOMESTR_SYS_FILE_RCLOCAL} && \
				printOK "rc.local :: ${AVISO}Nvidia ${RESET}:: " || \
				printError "rc.local :: ${AVISO}Nvidia ${RESET} :: "

			printMsg "Desligando carregamento do driver ${AVISO}Nouveau${TEXTO}"
			cp $NOMESTR_SYS_FILE_NOUVEAU_OFF_TEMPLATE \
				${ROOTDIR}/${NOMESTR_SYS_FILE_NOUVEAU_OFF} > /dev/null 2>&1 && \
				printOK "nouveau off :: ${AVISO}Nvidia ${RESET}:: " || \
				printError "nouveau off :: ${AVISO}Nvidia ${RESET} :: "

			# Aqui poderíamos usar links absolutos, mas vamos apenas copiar os arquivos,
			# partindo do princípio de que o desenvolvedor poderia zonear algum 
			# arquivo por engano.
			printMsg "Inserindo o driver na raiz da imagem"
			cp -r ${NVIDIAROOTDIR}/ ${GABIXDRVDIR}/ > /dev/null 2>&1 && \
				printOK || printWarn "Faltou copiar algum arquivo? : "
			;;

			*)
			printWarn "Valor desconhecido para USENVDRV : ${USENVDRV}"
			printMsg "Verifique o arquivo configs.rc"
				
			;;
	esac

	# -------------------------------------------------
	# Adicione suporte a qualquer coisa que desejar ...
	

	printMsg " "
	printMsg "-----------------------------------------------"
	printMsg "Desligando interface de rede no arquivo do udev"
	printMsg "-----------------------------------------------"
	printMsg "Importante para evitar confusao na hora de subir a interface de rede."
	(
		head -6 ${UDEV_NET_CFG_FILE} > /tmp/criando_squash_file 2> /dev/null && \
		mv /tmp/criando_squash_file ${UDEV_NET_CFG_FILE}
	) && printOK || printWarn "Arquivo existe? : "

    printMsg " "
    printMsg "-----------------------"   
    printMsg "Criando imagem squashfs"    
    printMsg "-----------------------"   
    printMsg "Aguarde alguns instantes."
    $MAKEIT "${ROOTDIR}/" "${BASEDIR}/${SQUASHFILE}" &> /dev/null && printOK || printError

    printMsg " "
    printMsg "Ajustando a posse do sistema para ${AVISO}UID:${FILES_USER_ID}"
	chown ${FILES_USER_ID}.${FILES_GROUP_ID} ${BASEDIR}/* && printOK || printError

    printMsg " "
    printMsg "-------------------------------------"
    printMsg "Reativando dispositivos em ${DEV}${ROOTDIR}"
    printMsg "-------------------------------------"
	tar xjf ${CONFS_PKGS_DIR}/dev_stuff.tar.bz2 -C . && printOK || printError

    printMsg " "
	chmod 777 ${BASEDIR}/* && printOK "Permissões em imagens SquashFS : " || \
		printError "Permissões em imagens SquashFS : "
	chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${GABIXROOTDIR}/ && printOK "Posse de ${NOMESTR} : " || printError "Posse de ${NOMESTR} : "
fi
