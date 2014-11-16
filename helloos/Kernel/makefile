# Makefile
# 부트로더 컴파일 전용 Makefile
all: install
    
install: kernel.sys kernel.protectmode.sys
	@$(CP) "kernel.sys" "../Image/kernel.sys"
	@$(CP) "kernel.protectmode.sys" "../Image/kernel.protectmode.sys"
    
# Assembly Code Compile
%.sys : %.asm
	nasm -f bin -o $@ $<

clean:
	@$(REMOVE) kernel.sys
	@$(REMOVE) kernel.protectmode.sys
