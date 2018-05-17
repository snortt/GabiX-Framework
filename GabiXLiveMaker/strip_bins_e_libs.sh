#!/bin/bash
# 
# Script para "estripar" binários e bibliotecas
# Isso removerá símbolos, informações de depuração, etc.
# Se algo der errado (crash), você não terá como ver o que aconteceu.
# Se não ligar para isso, você pode "estripar" à vontade para 
# tentar reduzir o tamanho final das imagens
# 
# Gabriel Marques - snortt@gmail.com
# Seg Out 24 12:26:31 BRST 2011
# 

# Carrega as definições globais
. includes.rc

if [ "$(id -u)" -ne "0" ]; then
    printMsg "Voce precisa ser root"
    exit 201
fi

if [ $# -ne 1 ]; then
    printMsg "Uso: ${0##*/} <root-NFS>"
	exit 202
fi

printMsg " "
printMsg "Executando strip em ${DEV}$1${TEXTO}. Isso pode demorar um pouco. Por favor aguarde."
for x in  1 2 3 4 5; do echo -en "$PROGRESSBAR"; sleep 1; done

printMsg " "
printMsg "Stripping de binarios"
for dir in ${STRIP_BIN_DIRS}
do
 find ${1}/${dir} | xargs file | grep "${STRIP_BIN_STR}" | grep "${STRIP_FILE_TYPE}" | cut -d ":" -f 1 | xargs strip ${STRIP_OPTS} &> /dev/null && printOK "Strip :: ${1}/${dir} :: " || printWarn "Strip :: Nada para fazer em ${1}/${dir} :: "
done

printMsg " "
printMsg "Stripping de bibliotecas"
for dir in ${STRIP_LIB_DIRS}
do
 find ${1}/${dir} | xargs file | grep "${STRIP_LIB_STR}" | grep "${STRIP_FILE_TYPE}" | cut -d ":" -f 1 | xargs strip ${STRIP_OPTS} &> /dev/null && printOK "Strip :: ${1}/${dir} :: " || printWarn "Strip :: Nada para fazer em ${1}/${dir} :: "
done

