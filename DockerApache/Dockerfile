FROM ubuntu
# TODO: Replace value of CI_PROJECT_NAME with team name. Keep prefix "svs"!
ENV CI_PROJECT_NAME='svs24'
ENV CI_PROJECT_NAMESPACE='ful'
ENV DEBIAN_FRONTEND='noninteractive'
ENV TZ=Europe/Berlin
LABEL authors='Michael.Deichen@haw-hamburg.de'

RUN apt-get update && apt-get install -y \
	tzdata \
        apache2 \
        curl \
        gettext \
        less \
        libintl-perl \
        lynx \
        nano \
        net-tools \
        openssh-server \
        tcpdump \
        telnet \
        wget \
    && rm -rf /var/lib/apt/lists/*

# locale
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Setup ssh
RUN mkdir /var/run/sshd
# allow root login with key pair
RUN sed -i 's/#Port 22/Port 222/' /etc/ssh/sshd_config
# allow root login with key pair
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin\ prohibit-password/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd
ENV NOTVISIBLE='in users profile'
RUN echo 'export VISIBLE=now' >> /etc/profile

COPY authorized_keys /root/.ssh/authorized_keys
RUN chmod 0400 /root/.ssh/authorized_keys
COPY userdata /userdata

# certificates
COPY certs /certs
# for revocation list, make crls publicly available
COPY certs/crl/* /userdata/webportal/

# basic Authentication
COPY basicAuth/.htpasswd /etc/apache2/.htpasswd


# Add welcome message
RUN echo 'Welcome to your web portal.' > /etc/motd

# to be able to run ProxyPass
RUN a2enmod proxy_http
# to be able to run RequestHeader
RUN a2enmod headers

# Apache
COPY apache2-user-config.conf /etc/apache2/sites-available/webportal.conf
RUN /bin/bash -c 'envsubst < /etc/apache2/sites-available/webportal.conf | tee /etc/apache2/sites-available/webportal.conf'
RUN /bin/bash -c 'envsubst < /userdata/webportal/index.html | tee /userdata/webportal/index.html'

# enable ssl
RUN a2enmod ssl

RUN a2dissite 000-default.conf
RUN a2dissite default-ssl.conf
RUN a2ensite webportal.conf
RUN apache2ctl start

# autorun
RUN /bin/bash /userdata/autorun.sh

EXPOSE 222
EXPOSE 80
EXPOSE 443

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh
CMD ["./entrypoint.sh"]
