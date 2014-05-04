# DOCKER-VERSION 0.9.1

FROM ubuntu

RUN apt-get -y install nodejs npm libvips-dev
RUN ln -s /usr/bin/nodejs /usr/local/bin/node
RUN npm install -g coffee-script

ADD . /croppit
RUN cd /croppit; npm install
EXPOSE 2450
CMD ["coffee", "/croppit/croppit_server.coffee"]
