#!/bin/bash
#
# Carregador dos drivers das placas Nvidia.
#
# Gabriel Marques
# gabrielm@lncc.br
#
# Qui Nov 24 15:55:59 BRST 2011
#

# Vamos ajutar a ferramenta a encontrar seus recursos.
export NV_LIVE_DIR="/cdrom/drv/nv_live/"

#
# Carrega o arquivo de configuracoes
. ${NV_LIVE_DIR}/funcoes.rc

# Arquivo que contém o driver.
nvidia_drv_pack="${NV_LIVE_DIR}/Nvidia-304.64_x86_64_3.3.1-gabix.tar.bz2"

printMsg " "
printMsg "----------------------------"
printMsg " Carregador do driver ${AVISO}NVidia${TEXTO}"
printMsg "----------------------------"

procurar_nvidia
unset NV_LIVE_DIR NVID

