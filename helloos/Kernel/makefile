# Makefile
# 부트로더 컴파일 전용 Makefile
REMOVE := rm -rf
CP := cp

all: install
	
install: kernel.sys
	@$(CP) "kernel.sys" "../Image/kernel.sys"
	
# Assembly Code Compile
%.sys : %.asm
	nasm -f bin -o $@ $<

clean:
	@$(REMOVE) *.sys
