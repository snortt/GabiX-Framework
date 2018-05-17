#!/bin/bash
#
# Script para gravar a ISO usando modo texto
# 
# Gabriel Marques - snortt@gmail.com
# 

# Carrega as definições globais
. includes.rc

if [ ! -x $GRAVADOR ]; then
	printError "Gravador não encontrado."
	printMsg "Experimente ${AVISO}apt-get install wodim"
	exit 200
fi

if [ "$(id -u)" -ne "0" ]; then
    printMsg "Voce precisa ser root"
    exit 201
fi

if [ $# -lt 1 ]; then
    printMsg "Uso: ${0##*/} <gabix.iso> [opt]"
    printMsg "    Caso a midia seja RW, opt pode ser:"
    printMsg "\t1 - apaga a midia antes de gravar"
    printMsg "\t    (default: nao apaga a midia antes de gravar)\n"
	exit 202
fi

if [ -f $1 ]; then
	# Assumindo que a mídia possa estar montada, tentaremos desmontá-la.
	umount /media/cdrom > /dev/null 2>&1 

	if [ "$2" != "" ]; then
		if [ "$2" -eq "1" ]; then
            printMsg "Apagar midia antes de gravar"
			$GRAVADOR $WODIM_OPTS blank=fast $REC_DEV
		fi		
	else
        printMsg "Nao apagar midia antes de gravar"
	fi
	$GRAVADOR $WODIM_OPTS dev=${REC_DEV} speed=${SPEED} $1 && printOK && eject 
else
    printMsg "${ERRO}Erro!${TEXTO} Arquivo ${DEV}$1 ${TEXTO}nao encontrado."
	exit 203
fi

