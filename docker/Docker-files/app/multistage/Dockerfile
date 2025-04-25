FROM amazonlinux:2023 AS build_image

ARG version=17.0.15.6-1
ARG package_version=1

RUN set -eux \
    && rpm --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2023 \
    && echo "localpkg_gpgcheck=1" >> /etc/dnf/dnf.conf \
    && CORRETO_TEMP=$(mktemp -d) \
    && pushd ${CORRETO_TEMP} \
    && RPM_LIST=("java-17-amazon-corretto-headless-$version.amzn2023.${package_version}.$(uname -m).rpm" "java-17-amazon-corretto-$version.amzn2023.${package_version}.$(uname -m).rpm" "java-17-amazon-corretto-devel-$version.amzn2023.${package_version}.$(uname -m).rpm" "java-17-amazon-corretto-jmods-$version.amzn2023.${package_version}.$(uname -m).rpm") \
    && for rpm in ${RPM_LIST[@]}; do \
    curl --fail -O https://corretto.aws/downloads/resources/$(echo $version | tr '-' '.')/${rpm} \
    && rpm -K "${CORRETO_TEMP}/${rpm}" | grep -F "${CORRETO_TEMP}/${rpm}: digests signatures OK" || exit 1; \
    done \
    && dnf install -y ${CORRETO_TEMP}/*.rpm \
    && popd \
    && rm -rf /usr/lib/jvm/java-17-amazon-corretto.$(uname -m)/lib/src.zip \
    && rm -rf ${CORRETO_TEMP} \
    && dnf clean all \
    && sed -i '/localpkg_gpgcheck=1/d' /etc/dnf/dnf.conf

ENV LANG=C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
#FROM openjdk:11 AS build_image
RUN dnf update && dnf install wget git unzip -y
RUN wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip
RUN unzip apache-maven-3.9.9-bin.zip && cp -r apache-maven-3.9.9 /usr/local/maven3.9
ENV MAVEN_OPTS="-Xmx512m"
RUN rm -rf apache-maven-3.9.9-bin.zip
RUN git clone -b main https://github.com/yobami12/Aprofile-Project.git
RUN cd Aprofile-Project && /usr/local/maven3.9/bin/mvn install

FROM tomcat:10-jre17

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=build_image Aprofile-Project/target/Aprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
