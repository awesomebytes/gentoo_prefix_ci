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
RUN usermod -aG sudo user
# Give the user a password
RUN echo user:user | chpasswd

# Instal basic stuff
RUN apt-get install build-essential -y

# Nice tools to have
RUN apt-get install bash-completion nano net-tools less iputils-ping vim emacs -y
RUN apt-get install python-pip python-dev  -y
RUN apt-get install wget -y
# To enable ssh
RUN apt-get install openssh-server -y
# To enable adding to the clipboard from the shell
RUN apt-get install xclip -y

WORKDIR /home/user
USER user

RUN wget https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh
RUN chmod +x bootstrap-prefix.sh
ENV EPREFIX /tmp/gentoo

# Patch bug #668940
COPY circular_dependencies.patch circular_dependencies.patch
RUN patch < circular_dependencies.patch

# Bootstrap Gentoo Prefix
# This stops on emerge of gcc-8.2.0-r4, bug #672042
RUN echo "Y\n\
\n\
${EPREFIX}\n\
luck\n" | ./bootstrap-prefix.sh || true
# Was asked to do dmesg to check if its out of memory error
RUN dmesg
# So we just do it again to get thru
# hopefully avoiding the circular dependencies error too, thanks to the patch
RUN echo "Y\n\
\n\
${EPREFIX}\n\
luck\n" | ./bootstrap-prefix.sh || true
# To workaround bug #670836
# perl error about errno
RUN cp ${EPREFIX}/usr/include/errno.h ${EPREFIX}/tmp/usr/include/errno.h
# To workaround "no python-exec wrapped executable"
# When trying to resume the bootstrap
RUN mkdir ${EPREFIX}/tmp/usr/lib/python-exec/python2.7 && cd ${EPREFIX}/tmp/usr/lib/python-exec/python2.7 && ln -s ../../../bin/python2.7 python2 && ln -s python2 python

# Let's go again
RUN echo "Y\n\
\n\
${EPREFIX}\n\
luck\n" | ./bootstrap-prefix.sh

ENTRYPOINT ["/bin/bash"]