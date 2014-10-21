# Makefile
# OS소스를 컴파일하여 최종 이미지 파일을 생성하기 위한 Makefile
MAKE_OPTION := .
# 자체 제작한 부트로더를 USB 장치에 Write 하는 프로그램
BOOTLOADER_INSTALLER = .\Tools\BootloaderWriter.exe
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
DRIVE_NUMBER = E

# 운영체제 버전별 명령어 셋팅
OS_DETECTING = $(shell uname -s)

ifeq ($(OS_DETECTING),MINGW32_NT-6.1)
	REMOVE := 'rm'
	CP := 'cp'
endif

INCLUDE_OPTIONS = REMOVE=$(REMOVE) CP=$(CP)
x86_64_RUN = qemu-system-x86_64 -m 512 -hdb $(DRIVE_NUMBER): -localtime -M pc

all: compile clean

# 부트로더 및 커널 컴파일 수행
compile:
	$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR)
	$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR)

# 부트로더 설치 작업 수행 및
# 1 섹터에 loader.img Bootloader Write
bootwriter:
	@$(BOOTLOADER_INSTALLER) 1 $(IMAGE_DIR)\loader.img

# 커널 파일 설치
writer:
	@$(REMOVE) $(DRIVE_NUMBER):\kernel.sys
	$(CP) $(IMAGE_DIR)\kernel.sys $(DRIVE_NUMBER):\kernel.sys

# 설치 된 내용을 바탕으로 실행
run:
	@$(x86_64_RUN)

# 기존의 설치 본 전부 제거
clean:
	$(MAKE) $(INCLUDE_OPTIONS) -C $(BOOTLOADER_DIR) clean
	$(MAKE) $(INCLUDE_OPTIONS) -C $(KERNEL_DIR) clean
