FROM awesomebytes/gentoo_prefix_latest_image_stage_3_2

# Add helpful scripts to use Gentoo Prefix on /tmp/gentoo
# startprefix just makes sure the softlink to /tmp/gentoo is done
COPY startprefix startprefix
# executeonprefix is to be used from a non-prefixed shell to
# execute commands in the prefix environment (on boot, for example)
COPY executeonprefix executeonprefix
RUN mv /tmp/gentoo/startprefix /tmp/gentoo/startprefix_original
RUN cp startprefix /tmp/gentoo
RUN cp executeonprefix /tmp/gentoo

# Create the .tar.gz
RUN cd /tmp; tar cvzf /tmp/gentoo_on_tmp.tar.gz gentoo

ENTRYPOINT ["/bin/bash"]