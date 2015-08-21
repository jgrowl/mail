# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.17
MAINTAINER Jonathan Rowlands <jonrowlands83@gmail.com>

EXPOSE 25 587 80 110 143

VOLUME ["/var/mail/"]

RUN echo mail > /etc/hostname;

RUN apt-get update

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND noninteractive

RUN echo postfix postfix/main_mailer_type string Internet site | debconf-set-selections;\
  echo postfix postfix/mailname string mail.example.com | debconf-set-selections

RUN echo "mysql-server mysql-server/root_password password rootpassword" | debconf-set-selections;\
  echo "mysql-server mysql-server/root_password_again password rootpassword" | debconf-set-selections

RUN apt-get install -y postfix mysql-server mysql-client postfix-mysql courier-authdaemon courier-pop courier-pop-ssl \
    courier-imap courier-imap-ssl libsasl2-2 sasl2-bin libsasl2-modules libsasl2-2 libsasl2-modules libpam-mysql \
    rsyslog supervisor dbconfig-common wwwconfig-common apache2 php5 php5-cli php5-imap php5-mysql opendkim \
    opendkim-tools spamassassin spamc postgrey php5-curl ansible python-mysqldb

RUN service courier-authdaemon start && apt-get install -y courier-authlib-mysql

RUN groupadd -g 5000 vmail
#RUN useradd -m -g vmail -u 5000 -d /home/vmail -s /bin/bash vmail
RUN useradd -m -g vmail -u 5000 -d /var/mail/ -s /bin/bash vmail

RUN chown -R vmail:vmail /var/mail

RUN usermod -G sasl postfix

RUN php5enmod imap

RUN echo "postfixadmin postfixadmin/mysql/admin-pass password rootpassword" | debconf-set-selections

ADD http://iweb.dl.sourceforge.net/project/postfixadmin/postfixadmin/postfixadmin-2.92/postfixadmin_2.92-1_all.deb /tmp/postfixadmin.deb
RUN service mysql start && sleep 5 && dpkg -i /tmp/postfixadmin.deb
RUN apt-get install -f

ADD etc/ansible/roles/jgrowl.configure_mail /etc/ansible/roles/jgrowl.configure_mail

# rainloop
WORKDIR "/var/www/html"
RUN rm /var/www/html/index.html
RUN curl -s http://repository.rainloop.net/installer.php | php
WORKDIR "/"

# spamassassin
RUN groupadd spamd
RUN useradd -g spamd -s /bin/false -d /var/log/spamassassin spamd
RUN mkdir /var/log/spamassassin
RUN chown spamd:spamd /var/log/spamassassin

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Remove the certs so they can be generated
RUN rm -f /etc/courier/pop3d.pem
RUN rm -f /etc/courier/imapd.pem

ADD entry.sh /usr/local/bin/entry.sh
ADD run-service.sh /usr/local/bin/run-service.sh
ADD main.yml /usr/local/bin/main.yml

ENTRYPOINT ["/usr/local/bin/entry.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
