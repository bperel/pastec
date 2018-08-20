FROM petronetto/opencv-alpine

MAINTAINER Bruno Perel <brunoperel@gmail.com>

RUN apk update && apk add libmicrohttpd-dev jsoncpp-dev curl-dev

RUN git clone --single-branch alpine --depth 1 https://github.com/bperel/pastec.git /pastec
RUN mkdir -p /pastec/build && mkdir /pastec/data
WORKDIR /pastec/build
RUN cmake ../ && make -j$(nproc)
RUN cd /pastec/data \
  && wget -q http://pastec.io/files/visualWordsORB.tar.gz \
  && tar zxf visualWordsORB.tar.gz

EXPOSE 4212
VOLUME /pastec/
CMD ./pastec -p 4212 /pastec/data/visualWordsORB.dat
