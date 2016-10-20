#! /bin/bash -e

if test -n "$PACKAGES"; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C apt-get install -y $PACKAGES
fi

(
    i=1
    echo "<user-mapping>"
    for user in $USERS; do
        u="${user%%:*}"
        p="${user#*:}"
        cat <<EOF
    <authorize username="${u}"
               password="${p}">
        <protocol>vnc</protocol>
        <param name="hostname">localhost</param>
        <param name="port">$((5900+i))</param>
        <param name="password">${p}</param>
    </authorize>
EOF
        if ! id "$u" >/dev/null 2>&1; then
            adduser --disabled-password --gecos "" "$u"
        fi
        echo "$user" | chpasswd
        mkdir -p /home/"$u"/.vnc
        echo "$p" | tightvncpasswd -f > /home/"$u"/.vnc/passwd
        chown -R "$u:$u" /home/"$u"/.vnc
        chmod 0600 /home/"$u"/.vnc/passwd
        sudo -u "$u" cp /etc/vnc/xstartup /home/"$u"/.vnc/xstartup
        sudo -Hu "$u" vnc4server -kill :$i || true
        sudo -Hu "$u" vnc4server :$i $VNC_OPTIONS
        ((++i))
    done
    for user in $MD5_USERS; do
        cat <<EOF
        u="${user%%:*}"
        p="${user#*:}"
        cat <<EOF
    <authorize username="${u}"
               password="${p}"
               encoding="md5">
        <protocol>vnc</protocol>
        <param name="hostname">localhost</param>
        <param name="port">$((5900+i))</param>
        <param name="password">${p}</param>
    </authorize>
EOF
        if ! id "$u" >/dev/null 2>&1; then
            adduser --disabled-password --gecos "" "$u"
        fi
        echo "$user" | chpasswd
        mkdir -p /home/"$u"/.vnc
        echo "$p" | tightvncpasswd -f > /home/"$u"/.vnc/passwd
        chown -R "$u:$u" /home/"$u"/.vnc
        chmod 0600 /home/"$u"/.vnc/passwd
        sudo -u "$u" cp /etc/vnc/xstartup /home/"$u"/.vnc/xstartup
        sudo -Hu "$u" vnc4server -kill :$i || true
        sudo -Hu "$u" vnc4server :$i $VNC_OPTIONS
        ((++i))
    done
    echo "</user-mapping>"
) > /etc/guacamole/user-mapping.xml

CATALINA_HOME=/usr/share/tomcat8 CATALINA_TMPDIR=/tmp CATALINA_BASE=/var/lib/tomcat8 /usr/share/tomcat8/bin/catalina.sh stop || true
CATALINA_HOME=/usr/share/tomcat8 CATALINA_TMPDIR=/tmp CATALINA_BASE=/var/lib/tomcat8 /usr/share/tomcat8/bin/catalina.sh start
guacd -f
