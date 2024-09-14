FROM ubuntu:20.04 as ubuntu-base

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
        sudo \
        supervisor \
        xvfb x11vnc novnc websockify \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html

COPY scripts/* /opt/bin/

# Add Supervisor configuration file
COPY supervisord.conf /etc/supervisor/

# Relaxing permissions for other non-sudo environments
RUN mkdir -p /var/run/supervisor /var/log/supervisor \
    && chmod -R 777 /opt/bin/ /var/run/supervisor /var/log/supervisor /etc/passwd \
    && chgrp -R 0 /opt/bin/ /var/run/supervisor /var/log/supervisor \
    && chmod -R g=u /opt/bin/ /var/run/supervisor /var/log/supervisor

# Creating base directory for Xvfb
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

CMD ["/opt/bin/entry_point.sh"]

#============================
# Utilities
#============================
FROM ubuntu-base as ubuntu-utilities

# Install utilities and Docker
RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
        firefox htop terminator gnupg2 software-properties-common sudo xterm \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt install -qqy --no-install-recommends ./google-chrome-stable_current_amd64.deb \
    && adduser --disabled-password --gecos "" account \
    && echo "account:12345678" | chpasswd \
    && usermod -aG sudo account \
    && apt-add-repository ppa:remmina-ppa-team/remmina-next \
    && apt update \
    && apt install -qqy --no-install-recommends remmina remmina-plugin-rdp remmina-plugin-secret \
    && apt-add-repository ppa:obsproject/obs-studio \
    && apt update \
    && apt install -qqy --no-install-recommends obs-studio \
    && apt install -qqy --no-install-recommends unzip vim nano neovim openjdk-11-jdk python3 python3-pip npm neofetch hollywood \
    # Install Docker
    && apt-get -qqy --no-install-recommends install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get -qqy --no-install-recommends install docker-ce docker-ce-cli containerd.io \
    && usermod -aG docker account \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#============================
# GUI
#============================
FROM ubuntu-utilities as ubuntu-ui

ENV SCREEN_WIDTH=1280 \
    SCREEN_HEIGHT=720 \
    SCREEN_DEPTH=24 \
    SCREEN_DPI=96 \
    DISPLAY=:99 \
    DISPLAY_NUM=99 \
    UI_COMMAND=/usr/bin/startxfce4

RUN apt-get update -qqy \
    && apt-get -qqy install --no-install-recommends \
        dbus-x11 xfce4 \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Set the default user to 'account'
USER account
