; 페이징 초기화 함수
_kernel_init_paging:
	mov ax, DataDescriptor
	mov es, ax

	;mov eax, _protect_entry.end_kernel
	;and eax, 0xFFFFF000
	;add eax, 0x1000
	mov eax, 0x00402000
	; 이부분의 값은 kernel.memory_map.txt 파일의 메모리 맵 참조
	mov dword [PageDirectory], eax
	; 커널의 마지막 부분에 바로
	; 페이지 디렉토리 셋팅

	; 페이징 처리를 하지 않은 경우
	; 기존의 물리 메모리 주소의 범위 안에서 사용 할 수 있으므로
	; 페이징 기능을 통해 가상 메모리를 사용한다.
	;-----------------------------------------------------------
	; Page Directory init
	;-----------------------------------------------------------
	mov edi, dword [PageDirectory]
	; 페이지 디렉토리가 위치할 메모리 주소
	mov eax, 0 | 2
	; 관리레벨, 읽기/쓰기, 존재여부
	mov ecx, 1024
	; 페이지 개수
.page_directory_init:
	mov dword [edi], eax

	add edi, 4
	; 다음 인덱스를 가리키도록 한다.
	loop .page_directory_init

	;-----------------------------------------------------------
	; Page Table init
	;-----------------------------------------------------------
	mov edi, dword [PageDirectory]
	add edi, 0x1000
	; 페이지 디렉토리 바로 뒤에 페이지 테이블이 위치한다.
	mov eax, 0
	mov ecx, 1024
	; 페이지 개수
.page_table_init:
	mov edx, eax
	or edx, 3
	; 속성 부여 : 감시 레벨, 읽기/쓰기, 존재여부
	mov dword [edi], edx

	add edi, 4
	add eax, 0x1000
	; 다음 페이지 영역의 주소를 가리키도록 한다.
	loop .page_table_init

	;-----------------------------------------------------------
	; 페이지 디렉토리에 첫번째 페이지 테이블 넣기
	;-----------------------------------------------------------
	mov eax, 0x1000
	mov ecx, 0
	; ecx 번째 페이지 디렉토리 주소 얻기
	mul ecx
	add eax, dword [PageDirectory]
	add eax, 0x1000
	; 첫번째 페이지 테이블 주소
	or eax, 3
	; 속성값 부여 : 감시레벨, 읽기/쓰기, 존재여부
	mov edi, dword [PageDirectory]
	add edi, 0 * 4
	mov dword [edi], eax
	;-----------------------------------------------------------

	mov eax, dword [PageDirectory]
	mov cr3, eax
	; 페이지 디렉토리 시작 주소를 등록

	;-------------------------------------------
	; 컨트롤 Register Setting
	; PG, CD, NW, AM, WP, NE, ET, TS, EM, MP, PE
	;  1   ?   ?   ?   ?   ?   ?   ?   ?   ?   1
	;-------------------------------------------
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax
	; 페이징을 시작하기 위해 컨트롤 레지스터에서
	; 최상위 비트를 1로 셋팅

	push 3
	push 0x0A
	push Paging32SuccessMessage
	call _print32

	ret

PageDirectory:			dd 0x00000000
; 페이지 디렉토리
