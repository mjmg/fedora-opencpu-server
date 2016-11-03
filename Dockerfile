FROM mjmgaro/fedora-rstudio-server:latest

RUN \ 
  dnf install -y 'dnf-command(builddep)' rpmdevtools make R-devel httpd-devel libapreq2-devel libcurl-devel protobuf-devel openssl-devel && \
  wget http://download.opensuse.org/repositories/home:/jeroenooms:/opencpu-1.6/Fedora_23/src/rapache-1.2.7-2.1.src.rpm && \ 
  wget http://download.opensuse.org/repositories/home:/jeroenooms:/opencpu-1.6/Fedora_23/src/opencpu-1.6.2-7.1.src.rpm && \ 
  dnf builddep -y --nogpgcheck rapache-1.2.7-2.1.src.rpm && \
  dnf builddep -y --nogpgcheck opencpu-1.6.2-7.1.src.rpm 

RUN \
  useradd -ms /bin/bash builder && \
  chmod o+r rapache-1.2.7-2.1.src.rpm && \
  chmod o+r opencpu-1.6.2-7.1.src.rpm && \
  mv rapache-1.2.7-2.1.src.rpm /home/builder/ && \
  mv opencpu-1.6.2-7.1.src.rpm /home/builder/ 

USER builder

RUN \
  rpmdev-setuptree

RUN \
  cd ~ && \
  rpm -ivh rapache-1.2.7-2.1.src.rpm && \
  rpmbuild -ba ~/rpmbuild/SPECS/rapache.spec

RUN \
  cd ~ && \
  rpm -ivh opencpu-1.6.2-7.1.src.rpm && \
  rpmbuild -ba ~/rpmbuild/SPECS/opencpu.spec

USER root

RUN \
  dnf install -y MTA mod_ssl /usr/sbin/semanage && \
  cd /home/builder/rpmbuild/RPMS/x86_64/ && \
  rpm -ivh rapache-*.rpm && \
  rpm -ivh opencpu-lib-*.rpm && \
  rpm -ivh opencpu-server-*.rpm

# Cleanup
RUN \
  rm -f /home/builder/rapache-1.2.7-2.1.src.rpm && \
  rm -f /home/builder/opencpu-1.6.2-7.1.src.rpm && \
  rm -rf /home/builder/rpmbuild/* && \
  dnf autoremove -y
  
# Apache ports
EXPOSE 80
EXPOSE 443
EXPOSE 8004

COPY \
  opencpu.conf /etc/supervisor/conf.d/opencpu.conf
  
# default command
CMD ["supervisord", "-c", "/etc/supervisor.conf"]

