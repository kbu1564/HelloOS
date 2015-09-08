; void open(char* filepath);
_open:
    retn

; void* read(int size);
_read:
    retn

; void* read_entry(char* dirpath);
; push 디렉토리 경로
; call _read_entry
_read_entry:
    retn

; void close();
_close:
    retn

