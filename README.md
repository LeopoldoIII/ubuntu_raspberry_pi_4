# ubuntu_raspberry_pi_4

**Instructions to setup a raspberry pi 4 with Ubuntu Server 20.04.2 LTS**

Burn Ubuntu into micro SD
---


Download Ubuntu Server 20.04.2 LTS

https://ubuntu.com/download/raspberry-pi

Im using balena to install ubuntu into the microSDCard

https://www.balena.io/etcher/

Boot from the microSd
---

User ubuntu 
password ubuntu 
https://wiki.ubuntu.com/ARM/RaspberryPi#First_boot_.28Username.2FPassword.29
you will ask to update your password

![image](https://user-images.githubusercontent.com/26559577/110670508-13f60d00-8193-11eb-9e2c-439e06f8c76b.png)


wifi
---
https://linuxconfig.org/ubuntu-20-04-connect-to-wifi-from-command-line

List your interfaces to identify your wirieless 

```
ls /sys/class/net
```

![image](https://user-images.githubusercontent.com/26559577/110676407-8b2e9f80-8199-11eb-8712-fd630617a0bf.png)


```
sudo vi /etc/netplan/50-cloud-init.yaml
```

![image](https://user-images.githubusercontent.com/26559577/110676610-c4670f80-8199-11eb-93a2-115cf039b166.png)

add your ssdi and password 

![image](https://user-images.githubusercontent.com/26559577/110677033-49eabf80-819a-11eb-85a2-8be097feb685.png)

Replace your SSID-NAME-HERE and PASSWORD-HERE

```
sudo apt install net-tools
```
Then 

```
sudo netplan apply
```

run `ifconfig` and verify the conection with your wifi 

Option 2

List your interface 

```
iw dev 
```

Scan  

```
sudo iw wlp2s0 scan
```

Connet 

```
nmcli dev wifi connect ESSID password WifiPassword
```

Activate device 

```
sudo ip link set wlp1s0 up
```

https://es.linux-console.net/?p=357

Samba 
---
https://ubuntu.com/tutorials/install-and-configure-samba#1-overview

```
sudo apt update
sudo apt install samba
```

Add the following lines into this file  `/etc/samba/smb.conf` replace values as you wish 

```
[sambashare]
    comment = Samba on Ubuntu
    path = /home/username/sambashare
    read only = no
    browsable = yes
```

restart the service 


```
sudo service smbd restart
```

Update the firewall rules to allow Samba traffic

```
sudo ufw allow samba
```


Since Samba doesn’t use the system account password, we need to set up a Samba password for our user account
Username used must belong to a system account, else it won’t save.

```
sudo smbpasswd -a username
```

RVM 
---
https://raspberrypi.stackexchange.com/questions/1010/can-i-install-the-ruby-version-manager

```
curl -L https://get.rvm.io | bash -s stable --ruby
```

If this message appear 

```
Can't check signature: No public key
```

run this command 

````
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BD
````

Android SDK 
---

**android sdk** 

```
sudo apt-get install adb android-sdk-platform-tools-common
sudo apt-get install android-tools-adb android-tools-fastboot
sudo apt install android-sdk
```
libraries are in the path `/usr/lib/android`

https://linoxide.com/ubuntu-how-to/install-android-sdk-manager-linux-ubuntu-16-04/

https://developer.android.com/studio#systemrequirements

http://www.timelesssky.com/blog/building-android-sdk-build-tools-aapt-for-debian-arm

https://github.com/skyleecm/android-build-tools-for-arm/tree/build-21

https://www.reddit.com/r/androiddev/comments/cr79qk/android_sdk_for_arm/


JAVA
---
https://linuxize.com/post/install-java-on-raspberry-pi/



SSH ubuntu-server
---
https://phoenixnap.com/kb/enable-ssh-raspberry-pi
https://pimylifeup.com/ubuntu-server-raspberry-pi/


