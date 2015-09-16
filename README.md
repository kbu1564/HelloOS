[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/kbu1564/HelloOS?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

Development Environment
=======
```nasm
TargetOS : 'Linux', 'Windows', 'MAC OSX'
ProgramLanguage : Assembly(NASM)
Develop Env tools : nasm, vim, qemu 2.3.x
```
- The HelloOS project is not made to the C/C++ language, and it has made to only the Netwide Assembler and Makefile.
- The Source of this project is possible to compile in linux and windows.

Install to MAC OSX
======
1. Install ```Git```
2. git clone git://github.com/kbu1564/HelloOS.git
3. insert to USB in your PC<br />
![2015-08-31 11 38 24](https://cloud.githubusercontent.com/assets/7445459/9581908/1c4d6cec-503d-11e5-9b03-41b6a60af28e.png)
4. Install ```NASM```
5. Move to helloos in your project directory: ```cd ~/Github/HelloOS/hello```
6. Install HelloOS in your USB: ```make DRIVE_NAME=YOUR_USB_NAME```<br />
![2015-08-31 11 46 39](https://cloud.githubusercontent.com/assets/7445459/9581910/226ec6de-503d-11e5-9632-7a2656788c56.png)
7. Execute HelloOS: ```make DRIVE_NAME=YOUR_USB_NAME run```<br />
![2015-08-31 11 46 57](https://cloud.githubusercontent.com/assets/7445459/9581913/26c993c6-503d-11e5-8894-70c0220c1679.png)

Install to Windows
======
Preparing... :)

Install to Linux
======
Preparing... :)

Introduce
=======
- The License of this project is MIT.
- This is the GUI Operating System of a way of install to direct on a usb.
- The HelloOS project that can be give for help to people to understand for difficult to knowledge on the operating system has been processing in comments in korean and english.
- This operating system is possible to install in limitative in usb of 8 Gigabyte and 16 Gigabyte, so this page would be write a way to install.
- The USB that have been saved this operating system is possible to use like generic usb on other operating system.

This project's meaning to me
=====
- Maybe it would be foolish process developing the operating system only use x86 Intel assembly language.
- Now this project would be result for project which is made by a man who is different, especially thinking about all of things and is crazy about coding.
- This project will be able to give a help on knowledge to other people, who develop for the operating system and system structure.
- I hope that source that i made affectionately can be helped to other people without any restrictive licens limitation. Therefore, I contribute this source to MIT.

HelloOS's Program Executer FlowChart
====
![2015-03-29 11 07 28](https://cloud.githubusercontent.com/assets/7445459/6885961/6f7c2862-d668-11e4-8f29-b7f88015426a.png)

