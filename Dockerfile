FROM        ubuntu:16.04
MAINTAINER  Brendan LE GLAUNEC <brendan.leglaunec@etixgroup.com>

RUN         apt-get update \
            && apt-get -y dist-upgrade \
	        && apt-get install -y wget

RUN	        echo "deb http://ubuntu.kurento.org/ xenial kms6" | tee /etc/apt/sources.list.d/kurento.list && \
            echo "deb http://ubuntu.kurento.org/ xenial-dev kms6" | tee /etc/apt/sources.list.d/kurento-dev.list \
	        && wget -O - http://ubuntu.kurento.org/kurento.gpg.key | apt-key add - \
	        && apt-get update \
	        && apt-get -y install   kms-jsonrpc-1.0-dev \
	                                kmsjsoncpp-dev \
	                                kurento-module-creator-4.0 \
	                                kms-cmake-utils \
                                    kms-core-6.0-dev \
                                    cmake \
                                    automake \
                                    autopoint \
                                    autoconf \
                                    libglibmm-2.4-dev \
                                    libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev \
                                    libsctp-dev \
                                    libbison-dev \
                                    libtool \
                                    libssl-dev \
                                    libnice-dev \
                                    libusrsctp-dev \
                                    bison \
                                    valgrind \
                                    ffmpeg \
                                    byacc \
                                    flex \
                                    yasm \
                                    gtk-doc-tools \
                                    git \
	        && apt-get clean \
            && rm -rf /var/lib/apt/lists/*

EXPOSE 8888

RUN mkdir -p /kurento/kms-elements

WORKDIR /kurento

RUN git clone https://github.com/Kurento/gstreamer.git
RUN git clone https://github.com/Kurento/gst-libav.git
RUN git clone https://github.com/Kurento/gst-plugins-base.git
RUN git clone https://github.com/Kurento/gst-plugins-good.git
RUN git clone https://github.com/Kurento/gst-plugins-bad.git
RUN git clone https://github.com/Kurento/gst-plugins-ugly.git
RUN git clone https://github.com/Kurento/openwebrtc-gst-plugins.git
RUN git clone https://github.com/Kurento/kurento-media-server.git

# Build

# Dependencies for kms-elements
RUN cd gstreamer && ./autogen.sh && ./configure && make && make install && cd -
RUN cd gst-libav && ./autogen.sh && ./configure && make && make install && cd -
RUN cd gst-plugins-base && ./autogen.sh && ./configure && make && make install && cd -
RUN cd gst-plugins-good && ./autogen.sh && ./configure && make && make install && cd -
RUN cd gst-plugins-bad && ./autogen.sh && ./configure && make && make install && cd -
RUN cd gst-plugins-ugly && ./autogen.sh && ./configure && make && make install && cd -
RUN cd openwebrtc-gst-plugins && ./autogen.sh && ./configure && make && make install && cd -

COPY . /kurento/kms-elements

# Build modified kms-elements
RUN cd kms-elements && \
       mkdir build && \
       cd build && \
       cmake .. && \
       make && \
       make install \
       && cd ../..

# Build kurento-media-server with modified elements installed
RUN cd kurento-media-server && \
       echo "deb http://ubuntu.kurento.org/ xenial kms6" | tee /etc/apt/sources.list.d/kurento.list && \
       echo "deb http://ubuntu.kurento.org/ xenial-dev kms6" | tee /etc/apt/sources.list.d/kurento-dev.list && \
	   wget -O - http://ubuntu.kurento.org/kurento.gpg.key | apt-key add - && \
       apt-get update && \
       apt-get install -y $(cat debian/control | sed -e "s/$/\!\!/g" | tr -d '\n' | sed "s/\!\! / /g" | sed "s/\!\!/\n/g" | grep "Build-Depends" | sed "s/Build-Depends: //g" | sed "s/([^)]*)//g" | sed "s/, */ /g") && \
       mkdir build && \
       cd build && \
       cmake .. && \
       make && \
       make install \
       && cd .. \
       && mkdir -p /etc/kurento \
       && cp kurento.conf.json /etc/kurento/kurento.conf.json


COPY ./entrypoint.sh /entrypoint.sh

ENV GST_DEBUG=Kurento*:5

ENTRYPOINT ["/entrypoint.sh"]