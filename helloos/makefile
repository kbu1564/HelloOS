# Makefile
# OS소스를 컴파일하여 최종 이미지 파일을 생성하기 위한 Makefile
MAKE_OPTION = .
# 자체 제작한 부트로더를 USB 장치에 Write 하는 프로그램
#BOOTLOADER_INSTALLER = .\Tools\BootloaderWriter.exe
# 부트로더 소스 경로
BOOTLOADER_DIR = Bootloader
# 커널 소스 경로
KERNEL_DIR = Kernel
# 생성된 이미지 파일이 저장된 경로
IMAGE_DIR = Image
# 삭제 명령어
REMOVE = 'del'
# 복사 명령어
CP = 'copy'
# 설치할 USB 드라이브 이름
DRIVE_NUMBER = OSUSB
# DISK USB 장치 디바이스 경로 명
DRIVE_NUMBER_DEV = /dev/disk3
# 관리자 권한
SUDO = sudo
# 컴파일 명령어 출력 관련
Q = @

# 운영체제 버전별 명령어 셋팅
OS_DETECTING = $(shell uname -s)
# 실행전 언마운트 작업이 필요한 경우의 처리 명령어
DRIVE_BUSY_RUN = $(Q)$(SUDO) diskutil unmountDisk $(DRIVE_NUMBER_DEV)

# window cygwin
ifeq ($(OS_DETECTING), Cygwin)
	REMOVE := 'rm'
	CP := 'cp'
	DRIVE_NUMBER := /cygdrive/e
	DRIVE_NUMBER_DEV :=
	DRIVE_BUSY_RUN :=
	SUDO := 
else
# mac darwin
ifeq ($(OS_DETECTING), Darwin)
	REMOVE := 'rm'
	CP := 'cp'
	# 임시 값
	DRIVE_NUMBER := /Volumes/$(DRIVE_NUMBER)
	DRIVE_NUMBER_DEV := /dev/rdisk3
else
	# no Cygwin window or Ubuntu or fedora ...
	REMOVE := 'rm'
	CP := 'cp'

	DRIVE_NUMBER := /media/wook/$(DRIVE_NUMBER)
	DRIVE_NUMBER_DEV := /dev/sdb1
	DRIVE_BUSY_RUN :=
endif
endif

INCLUDE_OPTIONS = REMOVE=$(REMOVE) CP=$(CP)
x86_64_RUN = qemu-system-x86_64 -m 64 -hda $(DRIVE_NUMBER_DEV) -net none -localtime -M pc

all: compile clean writer

# 부트로더 및 커널 컴파일 수행
compile:
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR)
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR)

# 부트로더 설치 작업 수행 및
# 1 섹터에 loader.img Bootloader Write
#bootwriter:
#	$(Q)$(BOOTLOADER_INSTALLER) 1 $(IMAGE_DIR)\loader.img

# 커널 파일 설치
writer:
	$(CP) $(IMAGE_DIR)/kernel.sys $(DRIVE_NUMBER)/kernel.sys
	$(CP) $(IMAGE_DIR)/kernel.protectmode.sys $(DRIVE_NUMBER)/kernel.protectmode.sys

# 설치 된 내용을 바탕으로 실행
run:
	$(DRIVE_BUSY_RUN)
	$(SUDO) $(x86_64_RUN)

# 기존의 설치 본 전부 제거
clean:
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR) clean
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR) clean

