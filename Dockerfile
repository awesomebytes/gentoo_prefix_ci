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

# Let's get some specs of the machine that is running this job
RUN cat /proc/cpuinfo
RUN cat /proc/meminfo
RUN df -h

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
# perl error about errno.h and error_t.h
RUN cp ${EPREFIX}/usr/include/errno.h ${EPREFIX}/tmp/usr/include/errno.h && mkdir -p ${EPREFIX}/tmp/usr/include/bits/types && cp ${EPREFIX}/usr/include/bits/types/error_t.h ${EPREFIX}/tmp/usr/include/bits/types

# Apply the patch i made and
# /tmp/gentoo/tmp/usr/bin/ebuild perl-5.26.2.ebuild manifest

# To workaround Can't figure out your cwd!
RUN cp ${EPREFIX}/bin/pwd ${EPREFIX}/tmp/bin/pwd
# # To workaround
# # perl: error while loading shared libraries: libperl.so.5.26: cannot open shared object file: No such file or directory
# RUN echo "${EPREFIX}/tmp/usr/lib/perl5/5.26.2/x86_64-linux/CORE/" >> "${EPREFIX}"/tmp/etc/ld.so.conf && echo "${EPREFIX}/tmp/usr/lib/perl5/5.26.2/x86_64-linux/CORE/" >> "${EPREFIX}"/tmp/etc/env.d/05perl
# Use system perl to go thru... only works here cause this Ubuntu has a working perl, this looks very ugly
RUN rm -f ${EPREFIX}/tmp/usr/bin/perl && ln -s /usr/bin/perl ${EPREFIX}/tmp/usr/bin/perl
# To workaround "no python-exec wrapped executable"
# When trying to resume the bootstrap
RUN mkdir ${EPREFIX}/tmp/usr/lib/python-exec/python2.7 && cd ${EPREFIX}/tmp/usr/lib/python-exec/python2.7 && ln -s ../../../bin/python2.7 python2 && ln -s python2 python

# Let's go again
RUN echo "Y\n\
\n\
${EPREFIX}\n\
luck\n" | ./bootstrap-prefix.sh

# Here perl went thru, so we need to go back to use the system one to avoid
# libperl.so.5.26: cannot open shared object file: No such file or directory
RUN rm -f ${EPREFIX}/tmp/usr/bin/perl && ln -s /usr/bin/perl ${EPREFIX}/tmp/usr/bin/perl

RUN echo "Y\n\
\n\
${EPREFIX}\n\
luck\n" | ./bootstrap-prefix.sh

ENTRYPOINT ["/bin/bash"]