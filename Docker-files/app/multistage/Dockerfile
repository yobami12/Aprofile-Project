FROM openjdk:11 AS build_image
RUN apt update && apt install maven -y
RUN git clone -b main https://github.com/yobami12/Aprofile-Project.git
RUN cd Aprofile-Project && mvn install

FROM tomcat:9-jre11

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=build_image Aprofile-Project/target/Aprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
