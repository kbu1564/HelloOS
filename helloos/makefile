# Makefile
# OS소스를 컴파일하여 최종 이미지 파일을 생성하기 위한 Makefile
MAKE_OPTION := C:\Users\pro_hacker\Desktop\HelloOS
# 자체 제작한 부트로더를 USB 장치에 Write 하는 프로그램
BOOTLOADER_INSTALLER := .\Tools\BootloaderWriter.exe
# 부트로더 소스 경로
BOOTLOADER_DIR := .\Bootloader
# 커널 소스 경로
KERNEL_DIR := .\Kernel
# 생성된 이미지 파일이 저장된 경로
IMAGE_DIR := .\Image
# 삭제 명령어
REMOVE := rm -rf
# 복사 명령어
CP := cp

#x86_64_RUN := qemu-system-x86_64 -m 64 -fda .\loader.img -localtime -M pc
x86_64_RUN := HelloOS.lnk

all: compile writer

# 부트로더 및 커널 컴파일 수행
compile:
    $(MAKE) -C $(BOOTLOADER_DIR)
    $(MAKE) -C $(KERNEL_DIR)

# 부트로더 설치 작업 수행 및
# 1 섹터에 loader.img Bootloader Write
bootwriter:
    @$(BOOTLOADER_INSTALLER) 1 $(IMAGE_DIR)\loader.img

# 커널 파일 설치
writer:
    @$(REMOVE) F:\kernel.sys
    $(CP) $(IMAGE_DIR)\kernel.sys F:\kernel.sys

# 설치 된 내용을 바탕으로 실행
run:
    @cmd /c $(MAKE_OPTION)\$(x86_64_RUN)

# 기존의 설치 본 전부 제거
clean:
    $(MAKE) -C $(BOOTLOADER_DIR) clean
    $(MAKE) -C $(KERNEL_DIR) clean
