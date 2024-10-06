FROM ubuntu:latest
LABEL "Author"="Ayobami"
LABEL "Project"="AY_Health"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install git -y
RUN apt install apache2 -y
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
EXPOSE 80
WORKDIR /var/www/html
VOLUME /var/log/apache2
ADD health.tar.gz /var/www/html
#COPY health.tar.gz /var/www/html
