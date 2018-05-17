#!/bin/bash
# 
# Script para compilar o kernel
# e gerar pacotes.deb
# 
# Gabriel Marques - gabrielm@lncc.br
# 
# Seg Mai 23 10:15:59 BRT 2011
#

if [ "$(id -u)" -ne "0" ]; then
	echo "Voce precisa ser root para usarmos prioridade alta ;-)"
    exit 200
fi

if [ $# -lt 1 ]; then
	echo -e "Uso: ${0##*/} <jobs>"
	echo -e "  jobs : numero de tarefas concorrentes (2x num CPUs)"
	exit 201
fi

echo -e "Iniciando construcao do kernel em $(date)"
nice --10 make-kpkg --initrd --jobs $1 --initrd kernel_image && echo -e "Construcao do kernel finalizada em $(date)"

echo -e "Iniciando construcao do kernel headers em $(date)"
nice --10 make-kpkg --jobs $1 kernel_headers && echo -e "Construcao do kernel headers finalizada em $(date)"

echo -e "Iniciando construcao do kernel modules em $(date)"
nice --10 make-kpkg --jobs $1 modules_image && echo -e "Construcao do kernel modules finalizada em $(date)"

