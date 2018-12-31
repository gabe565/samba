FROM alpine
MAINTAINER David Personette <dperson@gmail.com>

# Install samba
RUN set -x \
    && apk --no-cache upgrade \
    && apk --no-cache add \
        bash \
        samba \
        shadow \
        tini \
    && adduser -D -G users -H -S -g 'Samba User' -h /tmp smbuser \
    && sed -i \
        -e 's|^;* *\(log file =\).*|   \1 /dev/stdout|' \
        -e 's|^;* *\(load printers = \).*|   \1 no|' \
        -e 's|^;* *\(printcap name = \).*|   \1 /dev/null|' \
        -e 's|^;* *\(printing = \).*|   \1 bsd|' \
        -e 's|^;* *\(unix password sync = \).*|   \1 no|' \
        -e 's|^;* *\(preserve case = \).*|   \1 yes|' \
        -e 's|^;* *\(short preserve case = \).*|   \1 yes|' \
        -e 's|^;* *\(default case = \).*|   \1 lower|' \
        -e '/Share Definitions/,$d' \
        /etc/samba/smb.conf \
    && { \
        echo '   pam password change = yes'; \
        echo '   map to guest = bad user'; \
        echo '   usershare allow guests = yes'; \
        echo '   create mask = 0664'; \
        echo '   force create mode = 0664'; \
        echo '   directory mask = 0775'; \
        echo '   force directory mode = 0775'; \
        echo '   force user = smbuser'; \
        echo '   force group = users'; \
        echo '   follow symlinks = yes'; \
        echo '   load printers = no'; \
        echo '   printing = bsd'; \
        echo '   printcap name = /dev/null'; \
        echo '   disable spoolss = yes'; \
        echo '   socket options = TCP_NODELAY'; \
        echo '   strict locking = no'; \
        echo '   vfs objects = acl_xattr catia fruit recycle streams_xattr'; \
        echo '   recycle:keeptree = yes'; \
        echo '   recycle:versions = yes'; \
        echo; \
        echo '   # Security'; \
        echo '   client ipc max protocol = default'; \
        echo '   client max protocol = default'; \
        echo '   server max protocol = SMB3'; \
        echo '   client ipc min protocol = default'; \
        echo '   client min protocol = CORE'; \
        echo '   server min protocol = SMB2'; \
        echo; \
        echo '   # Time Machine'; \
        echo '   durable handles = yes'; \
        echo '   kernel oplocks = no'; \
        echo '   kernel share modes = no'; \
        echo '   posix locking = no'; \
        echo '   fruit:aapl = yes'; \
        echo '   fruit:advertise_fullsync = true'; \
        echo '   fruit:time machine = yes'; \
        echo '   smb2 leases = yes'; \
        echo; \
    } >> /etc/samba/smb.conf \
    && rm -rf /tmp/*

COPY samba.sh /usr/bin/

EXPOSE 137/udp 138/udp 139 445

HEALTHCHECK --interval=60s --timeout=15s \
            CMD smbclient -L '\\localhost' -U '%' -m SMB3

VOLUME ["/etc", "/var/cache/samba", "/var/lib/samba", "/var/log/samba", \
            "/run/samba"]

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/samba.sh"]
