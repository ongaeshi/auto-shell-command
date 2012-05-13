ascmd-c
=====================

Configuration example of C.

Basic: When touching '.c' or '.h', build & run
```
(ascmd:add '("ascmd-c/.*\.[ch]" "make all run"))
```

Advanced: When touching '.c' compilation file. When touching 'Makefile', build & run.
```
(ascmd:add '("ascmd-c/.*\.c" "gcc -c $FILE"))
(ascmd:add '("ascmd-c/Makefile" "make all run"))
```

Advanced2: Empty file command use ascmd:exec.
```
(ascmd:add '("ascmd-c/run" "make run"))           
(ascmd:add '("ascmd-c/clean" "make clean"))
```
