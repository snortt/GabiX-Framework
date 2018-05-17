# Makefile para gerar o sistema GabiX 
#
# Gabriel Marques
# snortt@gmail.com
#
# Qui Dez  8 15:38:47 BRST 2011
#

# Ajuda 
help:
	@-echo  "\
	config_32       - Ajusta o GabiX para 32 bits.\n\
	config_64       - Ajusta o GabiX para 64 bits.\n\
	config_armel    - Ajusta o GabiX para ARM (armel).\n\
	all             - Passa por todas as etapas.\n\
	clean           - Apaga os arquivos criados. ISO e SquashFS (mantém ajustes).\n\
	clean_links 	- Apaga apenas os links simbólicos criados (reset arquitetura).\n\
	all_clean_soft  - Passa por todas as etapas.\n\
                      Remove arquivos de zonas não usadas e idiomas não usados.\n\
	all_clean_hard  - Passa por todas as etapas.\n\
                      Remove arquivos de zonas não usadas, idiomas não usados e documentação.\n\
	criar_miniroot  - Cria o initrd do GabiX.\n\
	criar_iso_file  - Cria apenas o arquivo ISO.\n\
	criar_squash_fs - Cria a imagem SquashFS do sistema." 


# Regras para escolher entre 32 ou 64 bits
config_32:
	@make --silent clean_links
	@echo  "Ajustando sistema para 32 bits"
	@echo  "------------------------------"
	@-ln -s kernel/nvidia_drv/nv_live_x86 nv_live && echo  "nv_live -> nv_live_x86 : [OK]"
	@-ln -s gabix_x86 gabix && echo  "gabix -> gabix_x86 : [OK]"
	@-ln -s miniroot_x86 miniroot && echo  "miniroot -> miniroot_x86 : [OK]"
	@echo  "Não esqueça de criar o link simbólico root-NFS para o seu sistema\n"

config_64:
	@make --silent clean_links
	@echo  "Ajustando sistema para 64 bits"
	@echo  "------------------------------"
	@-ln -s kernel/nvidia_drv/nv_live_x86_64 nv_live && echo  "nv_live -> nv_live_x86_64 : [OK]"
	@-ln -s gabix_x86_64 gabix && echo  "gabix -> gabix_x86_64 : [OK]"
	@-ln -s miniroot_x86_64 miniroot && echo  "miniroot -> miniroot_x86_64 : [OK]"
	@echo  "Não esqueça de criar o link simbólico root-NFS para o seu sistema\n"

config_armel:
	@make --silent clean_links
	@echo  "Ajustando sistema para ARM (armel)"
	@echo  "------------------------------------"
	@-ln -s gabix_armel gabix && echo  "gabix -> gabix_armel : [OK]"
	@-ln -s miniroot_armel miniroot && echo  "miniroot -> miniroot_armel : [OK]"
	@echo  "Não esqueça de criar o link simbólico root-NFS para o seu sistema\n"

# Regra para criar o miniroot 
#criar_miniroot: criar_miniroot.sh
criar_miniroot: criar_miniroot.sh
	@./criar_miniroot.sh miniroot

# Regra para criar a imagem squashfs
criar_squashfs: criar_squashfs.sh
	@-./criar_squashfs.sh root-NFS/
	
# Regra para gerar a imagem ISO
criar_iso_file: make-iso.sh
	@./make-iso.sh gabix

# Regra que remove os arquivos antes de criar os novos
clean: 
	@echo  "Limpando arquivos existentes"
	@echo  "----------------------------"
	@-rm *.iso 2> /dev/null && echo  "ISO : [OK]"  || echo  "ISO : [Existe?]"
	@-rm gabix_*/base/sistema 2> /dev/null && echo  "base/sistema : [OK]" || echo  "base/sistema : [Existe?]"

# Regra que remove o driver da Nvidia
clean_nvidia_drv:  
	@echo  "Limpando drivers existentes"
	@echo  "----------------------------"
	@-rm -rf gabix_*/drv/nv_live 2> /dev/null && echo  "Nvidia : [OK]"  || echo  "Nvidia : [Existe?]"

# Regra que remove o arquivo de controle de arquiteturas
clean_arch:
	@echo  "Limpando configuração de arquitetura"
	@echo  "--------------------------------------"
	@-echo  "" > .arch_control && echo  "Arquivo de controle : [OK]"  || echo "Arquivo de controle : [Existe?]"

# Regra que remove apenas os links simbólicos
clean_links: 
	@echo  "Limpando links existentes"
	@echo  "-------------------------"
	@-rm gabix 2> /dev/null && echo  "gabix : [OK]" || echo  "gabix : [Existe?]"
	@-rm miniroot 2> /dev/null && echo  "miniroot : [OK]" || echo  "miniroot : [Existe?]"
	@-rm nv_live 2> /dev/null && echo  "nv_live : [OK]" || echo  "nv_live : [Existe?]"
	@-rm root-NFS 2> /dev/null && echo  "root-NFS : [OK]" || echo  "root-NFS : [Existe?]"
	@make --silent clean_arch

# Regra para limpar arquivos do sistema para poupar espaco	
clean_sysfiles: clean_sysfiles.sh
	@echo  "Limpando arquivos temporarios ..."
	@-find root-NFS/ -name "*~" -exec rm -fv {} \;
	@./clean_sysfiles.sh root-NFS/

# Regra para limpar arquivos do sistema (+ /usr/share/doc/*) para poupar mais espaco
clean_sysfiles_full: clean_sysfiles.sh
	@echo  "Limpando arquivos temporarios ..."
	@-find root-NFS/ -name "*~" -exec rm -fv {} \;
	@./clean_sysfiles.sh root-NFS/ -f

# Regra para executar todas as etapas de criação do GabiX e gerar a ISO final.
#all: clean criar_miniroot criar_squashfs criar_iso_file
all:
	@make --silent clean
	@make --silent clean_nvidia_drv
	@make --silent criar_miniroot
	@make --silent criar_squashfs
	@make --silent criar_iso_file

# Esta remove os arquivos locales e timezones da raiz da imagem squashfs, deixando documentação.
#all_clean_soft: clean clean_sysfiles criar_miniroot criar_squashfs criar_iso_file
all_clean_soft: clean_sysfiles all 

# Esta remove os arquivos de documentação, locales e timezones da raiz da imagem squashfs.
#all_clean_hard: clean clean_sysfiles_full criar_miniroot criar_squashfs criar_iso_file
all_clean_hard: clean_sysfiles_full all 


