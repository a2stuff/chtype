# chtype - change file type command for ProDOS

Build with [ca65](https://cc65.github.io/doc/ca65.html)

Installation:
* Copy target to ProDOS disk
* From BASIC.SYSTEM prompt, run: `-CHTYPE` from STARTUP (or by hand)

Usage:
```
CHTYPE pathname,Ttype[,Aauxtype][,S#][,D#]
```

Examples:
* `CHTYPE pic,T$08`
* `CHTYPE /root/was_bin,TSYS`
* `CHTYPE now_basic,TBAS,A$801`
* `CHTYPE as_text,TTXT,S6,D1`

Notes:
* Allocates a 1 page buffer to store the code
* Relative or absolute paths can be used
* Can be invoked as lower case (e.g. `chtype ...`)
