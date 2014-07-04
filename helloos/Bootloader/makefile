# Makefile
# 부트로더 컴파일 전용 Makefile
REMOVE := rm -rf
CP := cp

all: install
    
install: loader.bin
	@$(CP) "loader.bin" "../Image/loader.img"
    
# Assembly Code Compile
%.bin : %.asm
	nasm -f bin -o $@ $<

clean:
	@$(REMOVE) *.bin
