FROM debian:jessie

RUN apt-get update -y \
    && apt-get upgrade -y
RUN apt-get install -y curl vim

RUN curl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl \
    && curl https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson

RUN chmod +x /usr/local/bin/cfssl*
