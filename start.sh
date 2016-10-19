#! /bin/bash -e

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
        sudo -Hu "$u" vnc4server :$i
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
        sudo -Hu "$u" vnc4server :$i
        ((++i))
    done
    echo "</user-mapping>"
) > /etc/guacamole/user-mapping.xml

CATALINA_HOME=/usr/share/tomcat8 CATALINA_TMPDIR=/tmp CATALINA_BASE=/var/lib/tomcat8 /usr/share/tomcat8/bin/catalina.sh start
guacd -f
