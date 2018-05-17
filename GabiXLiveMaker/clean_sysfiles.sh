#!/bin/bash
# 
# Script para remover "gorduras" do sistema 
# antes de criar a imagem SquashFS.
# 
# Remove: listas e cache do apt/dpkg e limpa os logs
# Se usado em modo reforcado (-f), tambem remove: 
# documentacao, locales, timezones.
# 
# Esta segunda abordagem deve ser usada com cautela
# porque ha programas que utilizam o diretorio de 
# documentacao para "templates", arquivos de exemplos,
# demonstracoes, etc.
#
# Gabriel Marques
# snortt@gmail.com
# 
# Qua Jun  1 10:52:17 BRT 2011
#

# Carrega as definições globais
. includes.rc

if [ "$(id -u)" -ne "0" ]; then
    printMsg "Voce precisa ser root"
    exit 201
fi

if [ $# -lt 1 ]; then
    printMsg "Uso: ${0##*/} <NFS-root>"
	exit 202
fi

if [ ! -d $ROOTDIR ]; then
    printMsg "${ERRO}Erro!${TEXTO} Nao achei ${DEV}$ROOTDIR"
	exit 203
else
	case $2 in
		# Em modo "full_clean", limpa documentação, idomas e timezone
		"-f") printMsg 1 "Limpando diretorio de documentacao"
			  rm -rf ${ROOTDIR}/usr/share/doc/* 2> /dev/null && printOK "Docs : "
			  rm -rf ${ROOTDIR}/usr/share/gnome/help/* 2> /dev/null && printOK "GNOME Help : "
			  rm -rf ${ROOTDIR}/usr/share/omf/* 2> /dev/null && printOK "OMF : "
			  rm -rf ${ROOTDIR}/var/lib/doc-base/documents/* 2> /dev/null && printOK "VAR DB Docs : "
              AVISO_DOCS_CLEAN=" "
			;;

		*) AVISO_DOCS_CLEAN="\n${AVISO}******* AVISO *******
Para excluir docs e diminuir mais ainda
o tamanho da imagem SquashFS, use:
    ${FORTE}clean_sysfiles.sh <root-NFS> -f${AVISO}
ou, para limpar apenas o diretório,
    ${FORTE}make clean_sysfiles_full${AVISO}
ou, no caso de todas as etapas de construção,
    ${FORTE}make clean_sysfiles_hard \n${AVISO}" ;;
	esac

    printMsg " "
    printMsg "Limpando links quebrados na raiz"
	rm -f "${ROOTDIR}/{vmlinuz,initrd}" 2> /dev/null && printOK "links : "

    printMsg " "
    printMsg "Removendo arquivos do APT/dpkg e logs"
	# Sera que vale a pena machucar tanto assim o sistema de pacotes? ;-)
	###rm "${ROOTDIR}/var/lib/dpkg/info/*" 2> /dev/null && printOK "info : "
	rm -f "${ROOTDIR}/var/lib/apt/lists/mirror.lncc.br_debian*" 2> /dev/null && printOK "listas : "
	rm -f "${ROOTDIR}/var/cache/apt/srcpkgcache.bin" 2> /dev/null && printOK "srcpkgcache : "
	rm -f "${ROOTDIR}/var/cache/apt/pkgcache.bin*" 2> /dev/null && printOK "pkgcache : "
	for file in $(find "${ROOTDIR}/var/log/" -type f)
	do
		> ${file} # && echo "Log $file : vazio : [OK]"
	done && printOK "Logs : vazios : "

    printMsg " "
    printMsg 1 "Limpando diretorio de idiomas"
	#rm -rf "${ROOTDIR}/usr/share/locale/[a-o]* p[al] [r-z]*" 2> /dev/null && echo "idiomas : [OK]"
	(cd ${ROOTDIR}/usr/share/locale/ && rm -rf ${LOCALES_TO_WIPE} 2> /dev/null) && printOK "Locales : "

    printMsg " "
    printMsg 1 "Limpando diretorio de fuso-horarios"
	(cd ${ROOTDIR}/usr/share/zoneinfo/; rm -rf ${ZONES_TO_WIPE} 2> /dev/null) && printOK "Fuso-horarios : "
	(cd ${ROOTDIR}/usr/share/zoneinfo/posix/; rm -rf ${ZONES_TO_WIPE} 2> /dev/null) && printOK "Fuso-horarios posix: "

    printMsg "${AVISO_DOCS_CLEAN}"
	exit 0
fi


