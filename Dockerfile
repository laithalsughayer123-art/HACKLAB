FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# 0) Use stable Kali mirror
RUN printf "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware\n" \
    > /etc/apt/sources.list

# 1) Enable 32-bit support
RUN dpkg --add-architecture i386

# 2) Create the HackLab user
RUN useradd -m -s /bin/bash HackLab \
 && echo "HackLab:Admin123" | chpasswd \
 && usermod -aG sudo HackLab

# 3) Install pentest tools + runtimes + Kali goodies + wordlists
RUN apt-get update -o Acquire::Retries=5 && \
    apt-get install -y --no-install-recommends --fix-missing \
      libcap2-bin \
      wget \
      unzip \
      ca-certificates \
      default-jre-headless \
      wine32 \
      wine64 \
      nmap \
      netcat-traditional \
      hydra \
      curl \
      whois \
      recon-ng \
      theharvester \
      dnsenum \
      spiderfoot \
      fierce \
      dnsutils \
      whatweb \
      nikto \
      masscan \
      hping3 \
      zmap \
      tcptraceroute \
      skipfish \
      wapiti \
      dirb \
      amap \
      metasploit-framework \
      john \
      hashcat \
      beef-xss \
      medusa \
      sqlmap \
      crackmapexec \
      responder \
      ncrack \
      ettercap-text-only \
      routersploit \
      aircrack-ng \
      socat \
      secure-delete \
      bleachbit \
      git \
      python3-pip \
      python3-requests \
      python3-brotli \
      ruby \
      armitage \
      empire \
      openvas \
      powershell \
      maltego \
      sublist3r \
      amass \
      seclists \
      nano \
      logrotate \
      auditd \
      net-tools \
      bash-completion \
      wordlists \
      wireshark \
 && setcap cap_net_raw+ep /usr/bin/nmap \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# 4) Windows helpers: WCE + user-supplied EXEs
RUN mkdir -p /opt/windows-tools \
 && wget -qO /opt/windows-tools/wce.exe \
      https://github.com/returnvar/wce/raw/master/wce.exe || true \
 && chmod +x /opt/windows-tools/wce.exe || true

# Copy only auditpol.exe & wevtutil.exe
COPY auditpol.exe wevtutil.exe /opt/windows-tools/
RUN chmod +x /opt/windows-tools/*.exe || true

# 5) Wordlists & blank files for your cracking practice
RUN gunzip -c /usr/share/wordlists/rockyou.txt.gz \
     > /home/HackLab/rockyou.txt \
 && touch /home/HackLab/passwords.txt /home/HackLab/hashes.txt \
 && chown HackLab:HackLab /home/HackLab/*.txt

# 6) (Optional) Nessus installer
RUN wget -O /tmp/nessus.deb \
      "https://www.tenable.com/downloads/api/v1/public/pages/nessus/downloads/16870/download?i_agree_to_tenable_license_agreement=true" \
 && dpkg -i /tmp/nessus.deb 2>/dev/null || apt-get -f install -y \
 && rm -f /tmp/nessus.deb

# 7) Drop to unprivileged user
USER HackLab
WORKDIR /home/HackLab

CMD ["/bin/bash"]