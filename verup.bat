@echo off

echo "%1"

if "" == "%1" goto END

rem svn ls http://localhost:9000/repos-inside/kozuchi/tags/%1

svn copy http://localhost:9000/repos-inside/kozuchi/trunk http://localhost:9000/repos-inside/kozuchi/tags/%1 -m "version up %1"

:END

echo done

rem test update
