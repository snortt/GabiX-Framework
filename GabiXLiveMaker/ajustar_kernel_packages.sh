#!/bin/bash
# 
# Script para converter os pacotes .deb do kernel em tarball para o GabiX
# 
# Este script ajusta os links simbolicos:
# 	/lib/modules/$(uname -r)/build -> /usr/src/linux-headers-$(uname -r)
# 	/lib/modules/$(uname -r)/source -> /usr/src/linux-headers-$(uname -r)
# 	/usr/src/linux -> ./linux-headers-$(uname -r)
# 
# Gabriel Marques - snortt@gmail.com
# Sex Jun  3 17:09:42 BRT 2011
# 

# Carrega as definições globais
. includes.rc

if [ $# -lt 1 ]; then
    # Passe os arquivos que desejar (image, headers, firmware, libc-dev)
    printMsg "Uso: ${0##*/} <linux-image-x.y.z.deb> [<...>]"
	exit 201
elif [ ! -L gabix ]; then
    printError "Não achei diretório de destino."
    printWarn "Por favor, execute make config_32 ou config_64"
    exit 202 
else
	# Note que este procedimento independe da arquitetura selecionada 
	# para o GabiX. Fornecer um kernel para uma arquitetura diferente 
	# da configurada atualmente é normal.
    printMsg "----------------------"
    printMsg "Detectando arquitetura"
    if file $1 | grep -i i386 > /dev/null 2>&1; then
        ARCH="x86"
        printOK "${ARCH} : "
    elif file $1 | grep -i amd64 > /dev/null 2>&1; then
        ARCH="x86_64"
        printOK "${ARCH} : "
    elif file $1 | grep -i armel > /dev/null 2>&1; then
        ARCH="armel"
        printOK "${ARCH} : "
	else
		printError "Arquitetura não suportada (ainda)."
		exit 203
    fi

    printMsg "---------------------------------------------"        
    printMsg "Extraindo conteudo dos pacotes do kernel..."
	for a in "$@"
	do
		if file -b ${a} | grep -Ei 'debian binary package' > /dev/null 2>&1; then
    		dpkg -x ${a} ${KERNEL_TMP_AREA} && printOK "${a##*/} : " || printError "${a##*/} so aceito pacotes Debian : "
		fi
	done

	# Nao confunda esta variavel com KERNELVERSION, do arquivo configs.rc!
    # Esta aqui sera utilizada para realizar a troca de kernel! Aquela aponta para 
    # o kernel que ja esta instalado, para criar o menu do gerenciador de boot! ;-)
   	kernel_version=$(basename $(stat -c %n ${KERNEL_TMP_AREA}/boot/vmlinuz*) | cut -d "-" -f2-3)
    printMsg "--------------------------------------------------------"        
    printMsg "Ajustando links e diretórios do kernel ${AVISO}${kernel_version}."
	(cd ${KERNEL_TMP_AREA}; rm lib/modules/${kernel_version}/build lib/modules/${kernel_version}/source 2> /dev/null) && printOK "Limpo : " || printWarn "Limpo : Alguns arquivos faltando. Sem problemas! : "
	(cd ${KERNEL_TMP_AREA}; ln -s /usr/src/linux-headers-${kernel_version} lib/modules/${kernel_version}/source 2> /dev/null) && printOK "Source : " || printWarn "Source : Arquivo ja existe? Sem problemas! : "
	(cd ${KERNEL_TMP_AREA}; ln -s /usr/src/linux-headers-${kernel_version} lib/modules/${kernel_version}/build 2> /dev/null) && printOK "Build : " || printWarn "Build : Arquivo ja existe? Sem problemas! : "
	(cd ${KERNEL_TMP_AREA}/usr/src/; ln -s linux-headers-${kernel_version} linux 2> /dev/null) && printOK "Linux : " || printWarn "Linux : Arquivo ja existe? Sem problemas! : "
	
    printMsg "------------------------------------------------------------"        
    printMsg "Empacotando novo kernel. Por favor aguarde alguns instantes."
    (
    	cd $KERNEL_TMP_AREA
	    tar cjf ${KERNEL_DIR}/linux-${kernel_version}_${ARCH}.tar.bz2 * && printOK "${kernel_version} : ${ARCH} : " || printError "${kernel_version} : ${ARCH} : "
	    printMsg "${KERNEL_DIR}/linux-${kernel_version}_${ARCH}.tar.bz2" 
	)
    printMsg "Removendo arquivos temporários."
	rm -r ${KERNEL_TMP_AREA}/* && printOK "$(basename ${KERNEL_TMP_AREA}) : "
	
	chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${KERNEL_DIR}/ && printOK "Posse de ${NOMESTR} Kernel : " || printError "Posse de ${NOMESTR} Kernel : "
	chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${GABIXROOTDIR}/ && printOK "Posse de ${NOMESTR} BASE : " || printError "Posse de ${NOMESTR} BASE : "
    chown -R ${FILES_USER_ID}.${FILES_GROUP_ID} ${MINIROOTDIR}/ && printOK "Posse de ${NOMESTR} Miniroot : " || printError "Posse de ${NOMESTR} Miniroot : "
    exit 204
fi

