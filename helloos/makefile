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
OS_DETECTING     = $(shell uname -s)
DRIVE_NUMBER     = $(shell mount | grep OSUSB | awk '{split($$0,arr," "); print arr[3];}')
DRIVE_NUMBER_DEV = $(shell mount | grep OSUSB | awk '{split($$0,arr," "); print arr[1];}')
# cygwin 에서 빌드하는 경우 설치를 위한 드라이브 번호 지정
#DRIVE_NAME      = E

EMPTY = 
ifeq ($(DRIVE_NAME), $(EMPTY))
    all: need_parameter

    need_parameter:
		$(Q) echo "Useage : make DRIVE_NAME=input_your_usb_drive_name [compile|run]"
else
    ifeq ($(OS_DETECTING), Darwin)
        # mac osx not supported
        all: not_support

        not_support:
            $(Q) echo "This Operating System is not supported!!"
            $(Q) echo ""
            $(Q) echo "Operating System Type : $(OS_DETECTING)"

    else
        # linux or cygwin
        ifneq ($(OS_DETECTING), Linux)
            # window cygwin
            DRIVE_NUMBER := /cygdrive/$(DRIVE_NAME)
            DRIVE_NUMBER_DEV := $(DRIVE_NAME):
            SUDO := 
        endif

        all: compile clean writer
    endif
endif

INCLUDE_OPTIONS = REMOVE=$(REMOVE) CP=$(CP)

# 부트로더 및 커널 컴파일 수행
compile:
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR)
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR)

# 부트로더 설치 작업 수행 및
# 1 섹터에 loader.img Bootloader Write
bootwriter:
	$(SUDO) dd if=$(IMAGE_DIR)/loader.img of=$(DRIVE_NUMBER_DEV) bs=512

# 커널 파일 설치
writer:
	$(CP) $(IMAGE_DIR)/kernel.sys $(DRIVE_NUMBER)/kernel.sys
	$(CP) $(IMAGE_DIR)/kernel.protectmode.sys $(DRIVE_NUMBER)/kernel.protectmode.sys
	
# 설치 된 내용을 바탕으로 실행
run:
	$(SUDO) qemu-system-x86_64 -m 64 -hda $(DRIVE_NUMBER_DEV) -localtime -M pc

# 기존의 설치 본 전부 제거
clean:
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR) clean
	$(Q)$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR) clean

