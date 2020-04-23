FROM ubuntu:xenial 

# version can be stable, latest, or beta; arch can be x64 or x86
ARG version=latest
ARG arch=x64

# configure a dedicated user
ARG RUN_USER=ib-tws
ARG RUN_USER_UID=1012
ARG RUN_USER_GID=1012

# Accept license for Microsoft fonts
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

# Get the container up to date
RUN apt-get -yq update && \
    apt-get -yq dist-upgrade

# Install JRE 1.8 dependencies
RUN apt-get -yq install --no-install-recommends libglib2.0-0 libxrandr2 libxinerama1 \
    libgl1-mesa-glx libgl1 libgtk2.0-0 libasound2 libc6 libgif7 libjpeg8 libpng12-0 libpulse0 libx11-6 libxext6 \
    libxtst6 libxslt1.1 libopenjfx-jni libcanberra-gtk-module

# Include libopenjfx libraries directory in ld.so configuration
# This ensures they are available to the i4j-installed JRE
RUN echo " \n\
# JavaFX/OpenJFX 8 \n\
/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64 \n\
" > /etc/ld.so.conf.d/amd64-libopenjfx.conf
RUN ldconfig

# Install avcodec and avformat for multimedia support
RUN apt-get -yq install --no-install-recommends libavformat-ffmpeg56 libavcodec-ffmpeg56

# Install a browser and launcher
RUN apt-get -yq install --no-install-recommends firefox xdg-utils

# Install curl and additional fonts
RUN apt-get -yq install curl unzip ttf-mscorefonts-installer

# Create a dedicated user (ib-tws) for the IB TWS application
RUN useradd -u ${RUN_USER_UID} -ms /bin/bash ${RUN_USER}
RUN adduser ${RUN_USER} audio
RUN adduser ${RUN_USER} video
USER ${RUN_USER_UID}
WORKDIR /home/${RUN_USER}

# Bundle the Google Noto Sans Mono Medium font
# https://www.google.com/get/noto/
# SIL Open Font License, Version 1.1
COPY fonts/* /home/${RUN_USER}/.fonts/
RUN fc-cache

# Fetch and deploy the install4j package IB makes available
RUN curl -s -O https://download2.interactivebrokers.com/installers/tws/$version/tws-$version-linux-$arch.sh && \ 
    chmod +x tws-$version-linux-$arch.sh && \ 
    ./tws-$version-linux-$arch.sh -q && \
    rm tws-$version-linux-$arch.sh

# Add a few variables to ensure memory management in a container works
# correctly and raise memory limit to 1.5GB.
# Force anti-aliasing to LCD as JRE relies on xsettings, which are
# not present inside the container.
RUN echo " \n\
# Force LCD anti-aliasing \n\
-Dawt.useSystemAAFontSettings=lcd \n\
# Respect container memory limits \n\
-XX:+UnlockExperimentalVMOptions \n\
-XX:+UseCGroupMemoryLimitForHeap \n\
# Increase heap allocations \n\
-Xmx1536m \n\
" >> Jts/tws.vmoptions

# Copy over the TWS config so that user-supplied defaults are available at first run
USER root
COPY jts.ini Jts/
RUN chown ib-tws:ib-tws Jts/jts.ini
USER ib-tws

# IB TWS 954 and later can listen on port 7496 (live API) and 7497 (paper API)
# This functionality is disabled by default in TWS configuration
EXPOSE 7496
EXPOSE 7497

# Start TWS
CMD ["Jts/tws"]
