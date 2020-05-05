# ARM

## Build

* Enable multiarch for docker:
```
sudo apt-get install qemu binfmt-support qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```
* Build:
```
docker build -f Dockerfile.arm -t rcmorano/cardano-node:arm .
```
* Extract binaries:
```
CID=$(docker create rcmorano/cardano-node:arm)
docker cp ${CID}:/output /tmp
mv /tmp/output/* /usr/local/bin
```

## Run on Android phone

* Setup an ubuntu-focal chroot in e.g., using [termux-ubuntu-baids]
* Spawn a shell inside the chroot:
```
termux-ubuntu-shell focal
```
* Install depends inside the chroot:
```
apt update -qq && apt install -y libatomic1 curl
```
* Copy precompiled binaries from this project's releases (or build your own, tho it will take a while!) into /usr/local/bin:
```
RELEASE=master-at-5720f42
curl -sL https://github.com/rcmorano/docker-cardano-node/releases/download/${RELEASE}/cardano-node -o /usr/local/bin/cardano-node
curl -sL https://github.com/rcmorano/docker-cardano-node/releases/download/${RELEASE}/cardano-cli -o /usr/local/bin/cardano-cli
chmod +x /usr/local/bin/cardano*
```
* Enjoy!


```
cardano-cli genesis --genesis-output-dir /tmp/tmp.jcXsn2IeFK.d --start-time 1588693293 --protocol-parameters-file /opt/cardano/cnode/scripts/cardano-node/scripts/protocol-params.json --k 2160 --protocol-magic 459045235 --n-poor-addresses 128 --n-delegate-addresses 7 --total-balance 8000000000000000 --avvm-entry-count 128 --avvm-entry-balance 10000000000000 --delegate-share 0.9 --real-pbft --secret-seed 2718281828
```

[termux-ubuntu-baids]: https://github.com/rcmorano/termux-ubuntu-baids#instructions
