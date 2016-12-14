# find-shit-host

Find host in LAN with special IP and/or MAC address.
Tested on Linux.

## Dependency

### nbtscan

Download and install nbtscan.

```
http://ftp.tu-chemnitz.de/nbtscan-1.5.1-1.2.el6.rf.i686.rpm
http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/i386/rpmforge/RPMS/
```

## Get code

```
git clone https://github.com/alexzhangs/find-shit-host
```

## Usage

Find host with IP 192.168.0.100 in subnet 192.168.0.0/24.

```
sh find-shit-host/find-host.sh -c 192.168.0.100/24
```

Find host with MAC address ff:ff:ff:ff:ff:ff in subnet 192.168.0.0/24.

```
sh find-shit-host/find-host.sh -c 192.168.0.0/24 -m ff:ff:ff:ff:ff:ff
```

Find host with IP 192.168.0.100 and MAC address ff:ff:ff:ff:ff:ff in subnet 192.168.0.0/24.

```
sh find-shit-host/find-host.sh -c 192.168.0.100/24 -m ff:ff:ff:ff:ff:ff
```

Find above host, limiting `1 kbps` bandwidth to use for nbtscan, `1 second`
timeout, `max 8 hops` for traceroute.
And send email to `yourname@example.com` if found host.

```
sh find-shit-host/find-host.sh -c 192.168.0.100/24 -m
ff:ff:ff:ff:ff:ff \
    -n '-b 10240' \
    -t '-w 1 -m 8' \
    -e yourname@example.com
```

## Cron Job

Setup a cron job, run every 10 minutes to check host by IP and MAC,
if found alive host, will run traceroute and send email notification.

```
*/10 * * * * /path/to/find-host.sh \
    -c 192.168.0.100/24 \
    -m ff:ff:ff:ff:ff:ff \
    -n '-b 10240' \
    -t '-w 1 -m 8' \
    -e yourname@example.com \
    >> /tmp/find-host.log 2>&1
```
