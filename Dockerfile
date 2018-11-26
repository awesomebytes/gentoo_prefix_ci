# Just Ubuntu 16.04 with a user called user and some basic tools
FROM ubuntu:16.04

RUN apt-get update
# Add sudo
RUN apt-get install apt-utils sudo -y

# Create user
RUN useradd --create-home --shell=/bin/bash user
RUN chown -R user /home/user/
# Add the user to sudoers
RUN chmod -R o-w /etc/sudoers.d/
# Give the user a password
RUN echo user:user | chpasswd

# Instal basic stuff
RUN apt-get install build-essential -y

# Nice tools to have
RUN apt-get install bash-completion nano net-tools less iputils-ping vim emacs -y
RUN apt-get install python-pip python-dev  -y
RUN apt-get install wget -y

WORKDIR /home/user
USER user

RUN wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh
RUN chmod +x bootstrap-prefix.sh

# Bootstrap Gentoo Prefix
RUN date > start_bootstrap_date.txt && \
echo "Y\n\
\n\
/tmp/gentoo\n\
luck\n" | ./bootstrap-prefix.sh && \
date > end_bootstrap_date.txt

ENTRYPOINT ["/bin/bash"]