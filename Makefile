export PWD = $(shell pwd)

#source config.mk

#device ?= i1545
device ?= m11xr1
search = NUVOTON

make: $(device)

readout:
	docker run -i --rm -v $(PWD)/.config:/home/coreboot/coreboot/.config \
		--name coreboot-readout \
		-t "eyedeekay/coreboot-dockerfile" 'cat .config'

clobber:
	docker rm -f coreboot-build; \
	docker rmi -f eyedeekay/tlhab; true

clean:
	rm *log *err

debug: assureconfig
	docker rm -f coreboot-build; \
	docker run -i -v $(PWD)/.config:/home/coreboot/coreboot/.config \
		--name coreboot-build \
		-t "eyedeekay/tlhab" 'make --debug=v' | tee build.log 2> build.err
	make logtail

compile: assureconfig
	docker rm -f coreboot-build; \
	docker run -i -v $(PWD)/.config:/home/coreboot/coreboot/.config \
		--name coreboot-build \
		-t "eyedeekay/tlhab" 'make' | tee build.log 2> build.err
	make logtail

build:
	docker build --force-rm -f Dockerfile -t "eyedeekay/coreboot-dockerfile" .

better-build:
	docker build --force-rm -f Dockerfiles/Dockerfile.deps -t "eyedeekay/coreboot-dockerfile:deps" .
	docker build --force-rm -f Dockerfiles/Dockerfile.i386 -t "eyedeekay/coreboot-dockerfile:i386" .
	docker build --force-rm -f Dockerfiles/Dockerfile.x64 -t "eyedeekay/coreboot-dockerfile:x64" .
	docker build --force-rm -f Dockerfiles/Dockerfile.arm -t "eyedeekay/coreboot-dockerfile:arm" .
	docker build --force-rm -f Dockerfiles/Dockerfile.aarch64 -t "eyedeekay/coreboot-dockerfile:aarch64" .
	docker build --force-rm -f Dockerfiles/Dockerfile.mips -t "eyedeekay/coreboot-dockerfile:mips" .
	docker build --force-rm -f Dockerfiles/Dockerfile.riscv -t "eyedeekay/coreboot-dockerfile:riscv" .
	docker build --force-rm -f Dockerfiles/Dockerfile.power8 -t "eyedeekay/coreboot-dockerfile:power8" .
	docker build --force-rm -f Dockerfiles/Dockerfile.nds32le -t "eyedeekay/coreboot-dockerfile:nds32le" .
	docker build --force-rm -f Dockerfiles/Dockerfile -t "eyedeekay/coreboot-dockerfile" .

run: assureconfig
	docker rm -f coreboot; \
	docker run -i -v $(PWD)/.config:/home/coreboot/coreboot/.config \
		--name coreboot -t "eyedeekay/tlhab" bash

assureconfig:
	cp config-$(device) .config

archiveconfig:
	cp .config config-$(device)

menuconfig: assureconfig
	docker run -i --name coreboot-config -t "eyedeekay/tlhab" 'make distclean; make menuconfig'
	docker cp coreboot-config:/home/coreboot/coreboot/.config .; \
	docker rm -f coreboot-config
	make archiveconfig

confbuild: assureconfig
	docker run -i --name coreboot-config -t "eyedeekay/tlhab" 'make distclean; make menuconfig && make'
	docker cp coreboot-config:/home/coreboot/coreboot/.config .; \
	docker rm -f coreboot-config
	make archiveconfig

nconfig: assureconfig
	docker run -i --name coreboot-config -t "eyedeekay/tlhab" 'make distclean; make nconfig'
	docker cp coreboot-config:/home/coreboot/coreboot/.config .; \
	docker rm -f coreboot-config
	make archiveconfig

child: assureconfig
	docker build --force-rm -f Dockerfile.tlhab -t "eyedeekay/tlhab" .

kconflist:
	docker rm -f coreboot-kconfig-readout; \
	docker run -i --name coreboot-kconfig-readout -t eyedeekay/tlhab "find /home/coreboot/coreboot -iname Kconfig -exec grep -i -H -A 3 -B 3 select '{}' \; -exec echo \; | sed 's|.*:||g' | sed 's|.*-||g' | less"

kconfopts:
	docker rm -f coreboot-kconfig-readout; \
	docker run -i --name coreboot-kconfig-readout -t eyedeekay/tlhab "find /home/coreboot/coreboot -iname Kconfig -exec grep -i -H -A 3 -B 3 select '{}' \; -exec echo \;" | sed 's|.*:||g' | sed 's|.*-||g' | tee Kconfig_options

copy:
	rm -rf build
	docker cp coreboot-build:/home/coreboot/coreboot/build .

copy-utils:
	docker cp coreboot-build:/home/coreboot/coreboot/util .

pciinfo:
	sudo lspci -nnvvvxxx | tee vendor/docs/hwdumps/$(device)/lspci.log 2> vendor/docs/hwdumps/$(device)/lspci.err

hwinfo:
	sudo lshw -sanitize | tee vendor/docs/hwdumps/$(device)/lshw.log 2> vendor/docs/hwdumps/$(device)/lshw.err

usbinfo:
	sudo lsusb -vvv | tee vendor/docs/hwdumps/$(device)/lsusb.log 2> vendor/docs/hwdumps/$(device)/lsusb.err

superioinfo:
	sudo superiotool -deV | tee vendor/docs/hwdumps/$(device)/superiotool.log 2> vendor/docs/hwdumps/$(device)/superiotool.err

intelinfo:
	sudo inteltool -a | tee vendor/docs/hwdumps/$(device)/inteltool.log 2> vendor/docs/hwdumps/$(device)/inteltool.err

ecinfo:
	sudo ./util/ectool/ectool -i | tee vendor/docs/hwdumps/$(device)/ectool.log 2> vendor/docs/hwdumps/$(device)/ectool.err

msrinfo:
	sudo msrtool | tee vendor/docs/hwdumps/$(device)/msrtool.log 2> vendor/docs/hwdumps/$(device)/msrtool.err

dmiinfo:
	sudo dmidecode | tee vendor/docs/hwdumps/$(device)/dmidecode.log 2> vendor/docs/hwdumps/$(device)/dmidecode.err

biosinfo:
	sudo biosdecode | tee vendor/docs/hwdumps/$(device)/biosdecode.log 2> vendor/docs/hwdumps/$(device)/biosdecode.err

nvraminfo:
	sudo nvramtool -x | tee vendor/docs/hwdumps/$(device)/nvramtool.log 2> vendor/docs/hwdumps/$(device)/nvramtool.err

acpiinfo:
	sudo acpidump | tee vendor/docs/hwdumps/$(device)/acpidump.log 2> vendor/docs/hwdumps/$(device)/acpisump.err
	cd vendor/docs/hwdumps/$(device)/ && acpixtract -a acpidump.log

infolder:
	mkdir -p vendor/docs/hwdumps/$(device)/

cpuinfo:
	cat /proc/cpuinfo | tee vendor/docs/hwdumps/$(device)/cpuinfo.log 2> vendor/docs/hwdumps/$(device)/cpuinfo.err

ioinfo:
	cat /proc/ioports | tee vendor/docs/hwdumps/$(device)/ioports.log 2> vendor/docs/hwdumps/$(device)/ioports.err

info: infolder cpuinfo ioinfo pciinfo hwinfo usbinfo superioinfo intelinfo ecinfo msrinfo dmiinfo biosinfo nvraminfo acpiinfo

hwdiff:
	diff -y --expand-tabs --tabsize=8 --width=240 vendor/docs/libreboot_hwdumps/x200/lspci.log.trim vendor/docs/hwdumps/$(device)/lspci.log.trim | tee vendor/docs/differences-overview-x200-$(device).diff

diff:
	diff -y --color=always --expand-tabs --tabsize=8 --width=240 vendor/docs/libreboot_hwdumps/x200/lspci.log.trim vendor/docs/hwdumps/$(device)/lspci.log.trim | less -R

find:
	grep $(search) $(shell find . -name Kconfig)

#scinfo:
#	for x in $(/sys/class/sound/card0/hw*); do cat "$x/init_pin_configs" | tee vendor/docs/hwdumps/$(device)/pin_"$(basename "$x")"; done

#for x in /proc/asound/card0/codec#*; do cat "$x" > "$(basename "$x")"; done

#tee soundcard.log 2> vendor/docs/hwdumps/$(device)/soundcard.err

businfo:
	cat /sys/class/input/input*/id/bustype | tee vendor/docs/hwdumps/$(device)/input_bustypes.log 2> vendor/docs/hwdumps/$(device)/input_bustypes.err


dfind:
	docker run --rm -t eyedeekay/tlhab "grep $(search) \$$(find . -name Kconfig)"

sfind:
	docker run --rm -t eyedeekay/tlhab "grep SIZE \$$(grep $(search) \$$(find . -name Kconfig) | sed 's|:.*||g')"

rebuild: clobber assureconfig child compile copy

prebuilts:
	cd util/ectool; make; cp ectool ../../prebuilt/
	cd util/msrtool; ./configure; make; cp msrtool ../../prebuilt
	cd util/nvramtool; make; cp nvramtool ../../prebuilt
	cd util/superiotool; make; cp superiotool ../../prebuilt
	cd util/inteltool; make; cp inteltool ../../prebuilt

run-prebuilts:
	./prebuilt/ectool -i | tee vendor/docs/hwdumps/$(device)/ectool.log 2> vendor/docs/hwdumps/$(device)/ectool.err
	./prebuilt/msrtool | tee vendor/docs/hwdumps/$(device)/msrtool.log 2> vendor/docs/hwdumps/$(device)/msrtool.err
	./prebuilt/nvramtool -x | tee vendor/docs/hwdumps/$(device)/nvramtool.log 2> vendor/docs/hwdumps/$(device)/nvramtool.err
	./prebuilt/superiotool -deV | tee vendor/docs/hwdumps/$(device)/superiotool.log 2> vendor/docs/hwdumps/$(device)/superiotool.err
	./prebuilt/inteltool -a | tee vendor/docs/hwdumps/$(device)/inteltool.log 2> vendor/docs/hwdumps/$(device)/inteltool.err
	./prebuilt/lspci -nnvvvxxx | tee vendor/docs/hwdumps/$(device)/lspci.log 2> vendor/docs/hwdumps/$(device)/lspci.err
	./prebuilt/dmidecode | tee vendor/docs/hwdumps/$(device)/dmidecode.log 2> vendor/docs/hwdumps/$(device)/dmidecode.err

reduce:
	dd if=build/coreboot.rom bs=1M of=build/top.rom skip=6

ifdtool:
	docker rm -f coreboot-util-ifdtool; \
	docker run -i -v $(PWD)/.config:/home/coreboot/coreboot/.config \
		--name coreboot-util-ifdtool -t "eyedeekay/tlhab" 'cd util/ifdtool && make'
	docker cp coreboot-util-ifdtool:/home/coreboot/coreboot/util/ifdtool/ifdtool ./prebuilt/ifdtool

othertool:
	docker rm -f coreboot-util-; \
	docker run -i -v $(PWD)/.config:/home/coreboot/coreboot/.config \
		--name coreboot-util- -t "eyedeekay/tlhab" bash

logtail:
	tail -n 20 build.log | tee vendor/docs/hwdumps/$(device)/build.result

m11xr1: target-m11xr1

i1545: target-i1545

target-m11xr1:
	docker build --force-rm -f Dockerfiles.targets/Dockerfile.m11xr1 eyedeekay/coreboot-m11xr1 .

target-i1545:
	docker build --force-rm -f Dockerfiles.targets/Dockerfile.i1545 -t eyedeekay/coreboot-i1545 .
