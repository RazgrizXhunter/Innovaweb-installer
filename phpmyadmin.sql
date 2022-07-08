CREATE DATABASE phpmyadmin CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER "phpmyadmin"@"%" IDENTIFIED BY "P@ssw0rd";
GRANT ALL PRIVILEGES ON *.* TO "phpmyadmin"@"%";
FLUSH PRIVILEGES;
exit