FROM ubuntu:14.04
MAINTAINER Piotrek Sobieszczański <piotr.sobieszczanski [AT] gmail.com>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Update
RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  curl \
  python-setuptools \
  curl \
  git \
  unzip \
  nano \
  mysql-server \
  mysql-client \
  apache2 \
  libapache2-mod-php5 \
  php5 \
  php5-cli \
  php5-mysql \
  php-apc

# Drupal Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
  php5-curl \
  php5-gd \
  php5-intl \
  php-pear \
  php5-imagick \
  php5-imap \
  php5-mcrypt \
  php5-memcache \
  php5-ming \
  php5-ps \
  php5-pspell \
  php5-recode \
  php5-sqlite \
  php5-tidy \
  php5-xmlrpc \
  php5-xsl

# mysql config
ADD my.cnf /etc/mysql/conf.d/my.cnf
RUN chmod 664 /etc/mysql/conf.d/my.cnf

# apache config
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
#RUN chown -R www-data:www-data /var/www/

# php config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/apache2/php.ini
RUN sed -i -e "s/short_open_tag\s*=\s*Off/short_open_tag = On/g" /etc/php5/apache2/php.ini

# fix for php5-mcrypt
RUN /usr/sbin/php5enmod mcrypt

# Supervisor Config
RUN mkdir /var/log/supervisor/
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

# Initialization Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

# Home dir and terminal
ENV HOME /root
ENV TERM xterm

# Installing Composer
ENV COMPOSER_ROOT /root/.composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Installing drush
RUN sed -i '1i export PATH="$HOME/.composer/vendor/bin:$PATH"' $HOME/.bashrc
RUN ["/bin/bash", "-c", "source $HOME/.bashrc"]
RUN composer global require drush/drush:6.*


# Expose ports
EXPOSE 3306
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
