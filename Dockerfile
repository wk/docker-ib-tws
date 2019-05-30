FROM openjdk:8-jre-stretch

# version can be stable, latest, or beta; arch can be x64 or x86
ARG version=latest
ARG arch=x64

# Add contrib to known sources so we can install optional packages
RUN echo "deb http://httpredir.debian.org/debian stretch main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://httpredir.debian.org/debian stretch-backports main contrib non-free" >> /etc/apt/sources.list

# Accept license for Microsoft fonts
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

# Get the container up to date and install additional dependencies
RUN apt-get -yq update && \
    apt-get -yq dist-upgrade && \ 
    apt-get -yq install --no-install-recommends libopenjfx-jni firefox-esr -y && \
    apt-get -yq install --no-install-recommends libcanberra-gtk-module -y

# Create a dedicated user (ib-tws) for the IB TWS application
RUN useradd -ms /bin/bash ib-tws
USER ib-tws
WORKDIR /home/ib-tws

# Fetch and install the Droid Sans Mono (w/slashed zero) and 
# Droid Sans Mono (w/ dotted zero) fonts
# http://www.cosmix.org/software/
# Apache License 2.0
RUN wget https://www.cosmix.org/software/files/DroidSansMonoSlashed.zip && \
    wget https://www.cosmix.org/software/files/DroidSansMonoDotted.zip && \
    mkdir -p .fonts && \
    unzip DroidSansMonoSlashed.zip -d .fonts/ && \
    unzip DroidSansMonoDotted.zip -d .fonts/ && \
    fc-cache && \
    rm DroidSansMonoSlashed.zip DroidSansMonoDotted.zip

# Fetch and deploy the install4j package IB makes available
RUN wget https://download2.interactivebrokers.com/installers/tws/$version/tws-$version-linux-$arch.sh && \ 
    chmod +x tws-$version-linux-$arch.sh && \ 
    ./tws-$version-linux-$arch.sh -q && \
    rm tws-$version-linux-$arch.sh

# Add a few variables to ensure memory management in a container works right
RUN echo " \n\
# Increase heap allocation and respect container limits \n\
-XX:+UnlockExperimentalVMOptions \n\
-XX:+UseCGroupMemoryLimitForHeap \n\
# -Xmx1536m \n\
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
