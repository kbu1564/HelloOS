[ 추후 영어로 번역이 필요 ]

Development Environment
HelloOS 개발 환경
=======
```nasm
TargetOS : db 'Linux', 'Windows'
ProgramLanguage : db 'NASM'
```
- The HelloOS project is not made to the C/C++ language, and it has made to only the Netwide Assembler and Makefile.
- C/C++은 일체 사용되지 않으며 오직 NASM과 Makefile 만을 이용하여 제작 됩니다.

- The Source of this project is possible to compile in linux and windows.
- 소스는 윈도우와 리눅스 버전 둘다 컴파일이 가능하도록 제공됩니다.

Introduce
HelloOS 소개
=======
- The License of this project is MIT.
- 해당 프로젝트의 라이선스는 MIT로 합니다.

- This is the GUI Operating System of a way of install to direct on a usb.
- HelloOS는 USB에 직접 설치되는 방식의 GUI OS 입니다.

- This project is 
- 이 프로젝트는 다소 접근하기 힘든 운영체제라는 지식을 좀 더 많은 사람들이 보고 느낄 수 있도록, 영어와 한국어로 동시에 주석처리가 진행되게 됩니다.

- 해당 운영체제는 USB에 설치되는 구조이며 부팅이 가능하도록 되어있습니다.
- 운영체제는 현재 8GB, 16GB USB에 한정적으로 설치가 가능하도록 되어있으며 설치 과정은 추후 작성하여 본 페이지에 올려지게 됩니다.
- 운영체제를 USB에 담은 상태로 타 운영체제에서 일반 USB처럼 사용이 가능합니다.

나에게 HelloOS 프로젝트의 의미
=======
- 어쩌면 x86 Intel Assembly로만 운영체제를 개발하는 것은 바보같은 짓 일지도 모릅니다.
- 지금 이 프로젝트는 다른사람들과 같기를 싫어하는 좋아하는 것을 향해 달려가는 어떤 한 코딩에 몰두하는 사람이 만든 프로젝트에 대한 결과물이 될 것 입니다.
- 이 프로젝트가 운영체제나 시스템의 구조적인것을 공부하는 사람에게 도움이 되고, 리버싱이나 시스템적인 것을 공부하는 사람들에게 운영체제에 대한 매력을 조금이나마 이 프로젝트를 통해 알려줄 수 있었으면 합니다.
- 제가 애정을 담아 만들어낸 소스 한줄 한줄의 그 깊숙히 운영체제의 전부는 아니겠지만 조금이나마 담겨 있었으면 하며, 제 소스가 타인에게 조금이라도 라이선스적인 제약사항없이 도움이 되었으면 하는 바람에서 본 라이선스를 MIT로 부여합니다.

- 저는 이러한 저와 동일한 생각을 가지신 분들과 함께 하기를 원합니다.
- 처음에는 이러한 저의 생각이 제 주변이였으면 했지만 이제는 그 꿈을 크게 가져서 제 주변이 아닌 세계곳곳으로 향하게 해 볼까 합니다.
- 이 프로젝트는 이러한 저의 생각을 담은 첫 시작 프로젝트가 될 것 입니다.


```nasm
HelloOS_Introduce:
	db '어쩌면 x86 Intel Assembly로만 운영체제를 개발하는 것은 바보같은 짓 일지도 모릅니다.', 0x0A, 0
; 이와 같은 형태로 적으면 더 좋을 듯 싶다.
```