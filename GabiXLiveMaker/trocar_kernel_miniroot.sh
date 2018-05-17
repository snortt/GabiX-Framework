#!/bin/bash
#
# Este script troca o kernel do miniroot (initrd)
#
# Gabriel Marques - snortt@gmail.com
# Qui Mai  5 15:21:00 BRT 2011
#
# Este script precisa executar em uma maquina com a mesma versao do kernel
# que ele for instalar no miniroot e no gabix
#
# Lembre-se de usar a linha de comando 
# "make-kpkg --initrd kernel_image kernel_headers" 
# para gerar pacotes.deb com os arquivos do kernel.
#

# Carrega as definições globais
. includes.rc

#depscript="deps"

if [ "$(id -u)" -ne "0" ]; then
    printMsg "Voce precisa ser root"
    exit 201
fi

if [ $# -ne 1 ]; then
    printMsg "Uso: ${0##*/} <kernel_ajustado_para_gabix>"
	exit 202
fi

if [ ! -L miniroot ]; then
    printError "Não achei diretório do miniroot."
    printWarn "Por favor, execute make config_32 ou config_64"
    exit 203
fi

if [ ! -f "$1" -o ! -d ${KERNEL_TMP_AREA} ]; then
    printMsg "${ERRO}Erro${TEXTO}. Nao achei ${DEV}$1 ${TEXTO}ou ${DEV}${KERNEL_TMP_AREA}"
	exit 204
else
    printMsg " "
    printMsg "----------------------"
    printMsg "Removendo kernel atual"
    printMsg "----------------------"
    # Caso algum arquivo esteja faltando, vamos imprimir apenas um aviso. Isso não significa uma falha!
    rm ${GABIXROOTDIR}/boot/{vmlinuz,initrd,config,System}* 2> /dev/null && printOK "${NOMESTR} BOOT : " || printWarn "BOOT : Nao achei alguns arquivos. Sem problemas! : "
    rm ${GABIXROOTDIR}/base/{modulos,headers,firmware,includes} 2> /dev/null && printOK "${NOMESTR} BASE : " || printWarn "BASE : Nao achei alguns arquivos. Sem problemas! : "
    rm -r ${MINIROOTDIR}/lib/modules/* 2> /dev/null && printOK "${NOMESTR} : Miniroot : modulos : " || printWarn "Miniroot : modulos : Nao achei alguns arquivos. Sem problemas! : "

    printMsg " "
    printMsg "-------------------------------------------"        
    printMsg "Extraindo conteudo do pacote do novo kernel"
    printMsg "-------------------------------------------"        
    # Aqui é importante verificar se o tar falhou! Isso sim pode atrapalhar tudo!
    tar xjf ${1} -C ${KERNEL_TMP_AREA} && printOK "${1##*/} : " || printError "${1##*/} : "

    printMsg " "
    # Nao confunda esta variavel com KERNELVERSION, do arquivo configs_env.sh!
    # Esta aqui sera utilizada para realizar a troca de kernel! Aquela aponta para 
    # o kernel que ja esta instalado, para criar o menu do gerenciador de boot! ;-)
   	kernel_version=$(basename $(stat -c %n ${KERNEL_TMP_AREA}/boot/vmlinuz*) | cut -d "-" -f2-3)

    printMsg "---------------------------------------"
    printMsg "Instalando novo kernel: ${DEV}$kernel_version"
    printMsg "---------------------------------------"
    cp ${KERNEL_TMP_AREA}/boot/{vmlinuz,config,System}* "${GABIXROOTDIR}/boot" 2> /dev/null && printOK "${NOMESTR} BOOT : " || printError "${NOMESTR} BOOT : "
    (
        (cd ${KERNEL_TMP_AREA}/lib/ && mksquashfs modules ${GABIXROOTDIR}/base/modulos > /dev/null 2>&1) && \
            printOK "${NOMESTR} BASE : modulos : " || \
            printError "${NOMESTR} BASE : modulos : "
    )
    (
        (cd ${KERNEL_TMP_AREA}/lib/ && mksquashfs firmware ${GABIXROOTDIR}/base/firmware > /dev/null 2>&1) && \
            printOK "${NOMESTR} BASE : firmware : " || \
            printError "${NOMESTR} BASE : firmware : " 
    )
    (
        (cd ${KERNEL_TMP_AREA}/usr/ && mksquashfs src ${GABIXROOTDIR}/base/headers > /dev/null 2>&1 ) && \
            printOK "${NOMESTR} BASE : headers : " || \
            printError "${NOMESTR} BASE : headers : "

 		if [ -d ${KERNEL_TMP_AREA}/usr/include ]; then
			(cd ${KERNEL_TMP_AREA}/usr/ && mksquashfs include ${GABIXROOTDIR}/base/includes > /dev/null 2>&1 ) && \
            printOK "${NOMESTR} BASE : includes : " || \
            printError "${NOMESTR} BASE : includes : "
		  else
			  printWarn "Este kernel nao possui diretorio include"
		  fi
    )

    printMsg " "
    printMsg "Criando diretorio de modulos do miniroot para a versao ${DEV}$kernel_version"
	mkdir -p ${MINIROOTDIR}/lib/modules/${kernel_version} 2> /dev/null && printOK || printError

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
			MODULOS="${MODULOS_ARM}"
			;;
		"x86"|"x86_64")
			MODULOS="${MODULOS_PC}"
			;;
		*) printMsg "Problema ao detectar arquitetura para construir miniroot"
		   printError "Isso é um erro sério! Abortado."
		   exit 203
		   ;;
	esac

    printMsg " "
    printMsg "Copiando modulos para o miniroot"
    (
	    for modulo in $MODULOS
	    do
			find ${KERNEL_TMP_AREA} -name "$modulo" \
                -exec cp -f {} \
                ${MINIROOTDIR}/lib/modules/${kernel_version} \; 2> /dev/null && \
                echo -en "${APONTADOR}${PROGRESSBAR}"
    	done
    ) && printOK || printError

	if [ "$NVIDIA_DRV" ]; then
		printMsg "Solicitado driver ${AVISO}Nvidia${TEXTO}. Copiando..."
		cp $NVIDIA_DRV ${MINIROOTDIR}/lib/modules/${kernel_version} && printOK || printWarn "Arquivo existe? : "
	fi

    printMsg " "
	# O init do miniroot ja faz isso
	# Se for utilizar este bloco, descomente a variavel `depscript`
    #printMsg "Gerando dependencias no miniroot"
    #(
	#    echo "mount /proc" > ${MINIROOTDIR}/${depscript}
	#    echo "depmod 2> /dev/null" >> ${MINIROOTDIR}/${depscript}
	#    echo "umount /proc" >> ${MINIROOTDIR}/${depscript}
	#    
	#    chmod +x ${MINIROOTDIR}/${depscript}
	#    chroot ${MINIROOTDIR} /${depscript}
	#    rm ${MINIROOTDIR}/${depscript}
    #) && printOK || printError

    printMsg "------------------------------"
    printMsg "Removendo arquivos temporarios"
    printMsg "------------------------------"
    rm -r ${KERNEL_TMP_AREA}/* && printOK || printError "Remova manualmente : "

    printMsg " "
    printMsg "--------------------------------"
    printMsg "Gerando miniroot com novo kernel"
    printMsg "--------------------------------"
	make criar_miniroot

    echo ""
	chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${GABIXROOTDIR}/ && printOK "Posse de ${NOMESTR} BASE : " || printError "Posse de ${NOMESTR} BASE : "
    chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${MINIROOTDIR}/ && printOK "Posse de ${NOMESTR} Miniroot : " || printError "Posse de ${NOMESTR} Miniroot : "
fi

