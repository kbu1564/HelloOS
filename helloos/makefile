####################################################################
# 사용자 환경 설정 부분
####################################################################
# Makefile
# OS소스를 컴파일하여 최종 이미지 파일을 생성하기 위한 Makefile
MAKE_OPTION = .
# 부트로더 소스 경로
BOOTLOADER_DIR = Bootloader
# 커널 소스 경로
KERNEL_DIR = Kernel
# 생성된 이미지 파일이 저장된 경로
IMAGE_DIR = Image
# 설치할 USB 드라이브 Label 이름
#DRIVE_NUMBER = OSUSB
# DISK USB 장치 디바이스 경로 명
#DRIVE_NUMBER_DEV = /dev/disk2
# 가상머신VirtualBox vbox 파일 경로
#VBOX_RUN_PATH = ~/VirtualBox\ VMs/HelloOS/HelloOS.vbox
# 실행할 가상머신 종류 설정
# virtualbox - Virtualbox로 실행
# qemu - qemu로 실행
KIND_OF_VM = qemu
#KIND_OF_VM = virtualbox

# 삭제 명령어
REMOVE = rm
# 복사 명령어
CP = cp
# 관리자 권한
SUDO = sudo
# 컴파일 명령어 출력 관련
Q = @

#####################################################################
# Makefile 을 이용한 환경 셋팅값 적용 부분
#####################################################################
# 운영체제 버전별 명령어 셋팅
OS_DETECTING = $(shell uname -s)
DRIVE_NUMBER     = $(shell mount | grep OSUSB | awk '{split($$0,arr," "); print arr[3];}')
DRIVE_NUMBER_DEV = $(shell mount | grep OSUSB | awk '{split($$0,arr," "); print arr[1];}')
# 실행 전 디바이스 접근을 위한 권한 변경
#DRIVE_PERMISSION_RUN = $(Q)$(SUDO) chmod 777 $(DRIVE_NUMBER_DEV)
# 실행전 언마운트 작업이 필요한 경우의 처리 명령어
#DRIVE_UNBUSY_RUN = $(Q)$(SUDO) diskutil unmountDisk $(DRIVE_NUMBER_DEV)
#DRIVE_BUSY_RUN = $(Q)$(SUDO) diskutil mount $(DRIVE_NUMBER_DEV)
# QEMU를 이용한 가상 운영체제 시뮬레이션 실행
x86_64_RUN = qemu-system-x86_64 -m 64 -gdb tcp:127.0.0.1:1234 -hda $(DRIVE_NUMBER_DEV) -localtime -M pc
# VirtualBox를 이용한 실행
#VBOX_RUN = virtualbox --startvm $(VBOX_RUN_PATH)
# bootloader (mbr area) 설치
BOOTLOADER_INSTALLER = $(SUDO) dd if=$(IMAGE_DIR)/loader.img of=$(DRIVE_NUMBER_DEV) bs=512

# mac darwin
ifeq ($(OS_DETECTING), Darwin)
	# 임시 값
	#DRIVE_NUMBER := /Volumes/$(DRIVE_NUMBER)
else
    # no Cygwin window or Ubuntu or fedora ...
    ifeq ($(OS_DETECTING), Linux)
        #DRIVE_NUMBER := /media/wook/$(DRIVE_NUMBER)
        #DRIVE_NUMBER_DEV := /dev/sdb1
        #DRIVE_BUSY_RUN :=
        #DRIVE_UNBUSY_RUN :=
        #DRIVE_PERMISSION_RUN :=
    else
        # window cygwin
        DRIVE_NUMBER := /cygdrive/g
        DRIVE_NUMBER_DEV := G:
        #DRIVE_BUSY_RUN :=
        #DRIVE_UNBUSY_RUN :=
        #DRIVE_PERMISSION_RUN :=
        SUDO := 
    endif
endif

# virtual machine choice
#ifeq ($(KIND_OF_VM), virtualbox)
#    VM_RUN = $(SUDO) $(VBOX_RUN)
#else
    VM_RUN = $(SUDO) $(x86_64_RUN)
#endif

INCLUDE_OPTIONS = REMOVE=$(REMOVE) CP=$(CP)

all: compile clean writer

# 부트로더 및 커널 컴파일 수행
compile:
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR)
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR)

# 부트로더 설치 작업 수행 및
# 1 섹터에 loader.img Bootloader Write
bootwriter:
	$(BOOTLOADER_INSTALLER)

#bootwriter:
#	$(DRIVE_UNBUSY_RUN)
#	$(BOOTLOADER_INSTALLER)

# 커널 파일 설치
writer:
	$(CP) $(IMAGE_DIR)/kernel.sys $(DRIVE_NUMBER)/kernel.sys
	$(CP) $(IMAGE_DIR)/kernel.protectmode.sys $(DRIVE_NUMBER)/kernel.protectmode.sys
	
# 설치 된 내용을 바탕으로 실행
run:
	$(VM_RUN)

#run:
#	$(DRIVE_PERMISSION_RUN)
#	$(DRIVE_UNBUSY_RUN)
#	$(VM_RUN)
#	$(DRIVE_BUSY_RUN)

# 기존의 설치 본 전부 제거
clean:
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR) clean
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR) clean

