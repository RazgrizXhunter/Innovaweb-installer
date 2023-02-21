#!/bin/bash

RUNNING_USER=$SUDO_USER
USER=$(whoami)
SCRIPT_PATH=$(realpath "$0")

if test -f $(dirname $SCRIPT_PATH)/config.conf; then
	while IFS="=" read -a LINE; do
		case "${LINE[0]}" in
			PREFERRED_EDITOR)
				PREFERRED_EDITOR="${LINE[1]}"
				;;
		esac
	done <<< "$(cat $(dirname ${SCRIPT_PATH})/config.conf)"
else
	PREFERRED_EDITOR=vim
fi

Help() {
	clear
	echo '
                                                                .:.  .7JJ!  ^!!^
                                                               ^YYY? :YYY? .?JJ?. ^!!^
                                                          ~77!..!77^   ..    ..  .?JJ?. ..
                                                          !??7.      ^^  :7~  ..   ..  ?YYY^
                                                     ^???^      ^7~  !!. .!^  7?: .:.  ^7?!.
                                                     :7?7:  .!~ .:.     .   .     !J~      !YYJ^
                                                  :!!^      .!~   . .:  .  .:  ^     .JJ.  ~?J?:
                                                 .YYYY.  ^?7   . ..               ^   .. .    .^^:
J!                                                .::.    ..   :                    ^   ~?!   ?JJJ:
Y7                                                                                    .   ..  .:^:
Y7   7~.^~~~~~!!.   ~7.:~~~~~!!:     :!!~~~~!!^   :?:        :?.  ^!~~~~~~!~          :  .JY:  .~~~.
Y7   JJ^       !Y.  7Y~.      :Y:  .?7.       ~J^  ^Y:      :Y^  ~7        Y!         ..   .   !JJJ!
Y7   J7        .Y^  7J         Y!  ?J          ~Y.  ^Y^    ^Y:     .::::^^^J7         .   ~?~   .:.
Y7   J7        .Y:  7J         J!  ??          ~Y.   :Y^  ^Y:    77:....   ?7         ^.  ..   ^!!~.
Y7   J7        .Y^  7J         Y!  .J7.       ^J^     :Y^^Y:    ^5:       ^Y7        :   ~?~   7???:
?!   7!        .J:  !7         ?~    :!!~^^~!!~.       :??:      ^7~^^^^~~.:?~.          ...   ...
                                                                .:                 :   !Y7   ?YYJ:
                                                                :~              .:  .:. .    ~??7.
                           ..        ::        :    .::::::.    :^ ..:::::.         !J!   ^!~:
                            !.      ~^~:      ^^  ^:       .^:  :!:.      .^:   ^?7      :JJJ7
                             7.    ^^  !.    :~  ~^          7: :!          ^^       ~??!. ..
                              7   :~    7.  .!   7:............ :^          .!  :^:  JYYY:
                              .7 .!     .7 .!    :~          ^  :7          !. !JJJ!  ..
                               .!!       .!!      .^:.    .:^   :~.:..   .:^.   :^:
                                                     ......          ..... 
	'

	echo '=========================================================================================='
	echo '*         INSTALADOR EC2 AWS INNOVAWEB                                                   *'
	echo '=========================================================================================='
	echo '*                                                                                        *'
	echo '*  Parámetros:                                                                           *'
	echo '*      -h           - Muestra este menú.                                                 *'
	echo '*      -d           - Instalar paquetes de entorno de desarrollo.                        *'
	echo '*      -e [vim]     - Comando del editor de texto preferido. Por defecto: vim.           *'
	echo '*                                                                                        *'
	echo '=========================================================================================='
}

Base() {
	echo "Instalando paquetes base"
	sudo dnf -y update
	sudo dnf install -y epel-release
	sudo dnf module enable -y nginx:mainline

	sudo cp $(dirname $SCRIPT_PATH)/nginx.repo /etc/yum.repos.d
	sudo yum-config-manager --enable nginx-mainline

	sudo dnf config-manager --set-enabled powertools
	sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
	sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm

	sudo dnf install -y php71 php71-php-{fpm,intl,cli,common,gd,json,mbstring,mysqlnd,opcache,pdo,soap,zip,xml}
	sudo dnf install -y php73 php73-php-{fpm,intl,cli,common,gd,json,mbstring,mysqlnd,opcache,pdo,soap,zip,xml}
	sudo dnf install -y php74 php74-php-{fpm,intl,cli,common,gd,json,mbstring,mysqlnd,opcache,pdo,soap,zip,xml}
	sudo dnf install -y php81 php81-php-{fpm,intl,cli,common,gd,json,mbstring,mysqlnd,opcache,pdo,soap,zip,xml}

	sudo dnf install -y git htop vim nano mariadb-server python39 nginx cronie wget certbot python3-certbot python3-certbot-nginx unzip net-tools lsof curl

	sudo systemctl enable nginx
	sudo systemctl start nginx

	sudo systemctl enable mariadb
	sudo systemctl start mariadb

	sudo systemctl start php71-php-fpm
	sudo systemctl enable php71-php-fpm
	FPMConfig php71
	sudo systemctl restart php71-php-fpm

	sudo systemctl start php73-php-fpm
	sudo systemctl enable php73-php-fpm
	FPMConfig php73
	sudo systemctl restart php73-php-fpm

	sudo systemctl start php74-php-fpm
	sudo systemctl enable php74-php-fpm
	FPMConfig php74
	sudo systemctl restart php74-php-fpm

	sudo systemctl start php81-php-fpm
	sudo systemctl enable php81-php-fpm
	FPMConfig php81
	sudo systemctl restart php81-php-fpm

	sudo mysql_secure_installation

	# Install NVM
	echo "¿Desea instalar Node (Node version manager)? [s/N]"
	read ANSWER_NVM
	if [[ $ANSWER_NVM == 's' ]] ; then
		cd
		echo "Instalando NVM"

		git clone https://github.com/nvm-sh/nvm.git ~/.nvm
		
		cd ~/.nvm
		. ./nvm.sh
		
		RC_FILE=~/.bashrc
		
		echo 'export NVM_DIR="$HOME/.nvm"' >> $RC_FILE
		echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> $RC_FILE
		echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> $RC_FILE

		source ~/.bashrc
	fi

	echo "¿Desea instalar Docker? [s/N]"
	read ANSWER_DOCKER
	if [[ $ANSWER_DOCKER == 's' ]] ; then
		sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
		sudo dnf install -y docker-ce

		sudo systemctl start docker
		sudo systemctl enable docker

		sudo usermod -aG docker $USER

		sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
		sudo chmod +x /usr/local/bin/docker-compose

		newgrp docker
	fi

	# Install AWS CLI 2
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install

	cd
	mkdir Scripts
	cd Scripts

	git clone https://github.com/RazgrizXhunter/keysync
	git clone https://github.com/RazgrizXhunter/DB-Backup

	cd

	echo "Recuerda configurar Keysync."
	echo "./Scripts/keysync/keysync.sh -I"
}

FPMConfig() {
	PHPInstall=$1

	sed -i 's/^(listen\.acl_groups = apache)$/&,nginx/' /etc/opt/remi/$PHPInstall/php-fpm.d/www.conf
}

Dev() {
	# PHPMyAdmin
	echo "Instalando paquetes del entorno de desarrollo..."
	
	echo "Instalando PHPMyAdmin..."
	
	wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
	sudo mkdir -p /usr/share/nginx/phpmyadmin
	sudo tar xzf phpMyAdmin-latest-all-languages.tar.gz -C /usr/share/nginx/phpmyadmin --strip-components=1
	sudo cp $(dirname $SCRIPT_PATH)/phpmyadmin.conf /etc/nginx/conf.d
	sudo chown nginx:nginx /etc/nginx/nginx.conf

	echo "Ingresa la contraseña de PHPMyAdmin:"
	read PHPMYADMIN_PASSWORD
	sed -i "s/P@ssw0rd/$PHPMYADMIN_PASSWORD/" phpmyadmin.sql

	mysql -u root -p < phpmyadmin.sql

	echo "Se abrirá el archivo de configuración de Ngninx para PHPMyAdmin, presiona enter para continuar..."
	read
	sudoedit /etc/nginx/conf.d/phpmyadmin.conf

	sudo nginx -t && sudo service nginx reload
	
	echo "PHPMyAdmin listo..."
}

SetPreferredEditor() {
	echo -e "PREFERRED_EDITOR=${1}" > config.conf
}

if [[ $1 == "" ]]; then
	Base
fi

while getopts "hde:" OPTION; do
	case $OPTION in
		h)
			Help
			exit;;
		d)
			Dev
			;;
		e)
			SetPreferredEditor $OPTARG
			echo $OPTARG
			;;
		?)
			Help
			exit;;
	esac
done
