@ECHO OFF

REM What is this you ask? Someone put a "sleep 30" in the ECS cluster module, which doesn't work on Windows. 
REM Having this in the same folder makes it Terraform run it transparently on Windows "fixing" the issue.
REM Full credit goes to Fæster@JPPOL for the hack to fix the hack.

REM Waits %1 -1 seconds ...
ping 127.0.0.1 -n %1