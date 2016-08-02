function [errorFlag, time0] = startScan_eprime()
% Sample:
% [status, time0] = StartScan_eprime()

errorFlag = 0; % unless we have problems

try 
% setup trigger
s = serial('/dev/tty.usbmodem12341','BaudRate', 57600); 
% type 'ls -lh /dev/tty.usbmodem*' in terminal to determine correct port
% name
fopen(s);

% get time0
time0 = GetSecs;

% trigger
fprintf(s,'[t]');
fclose(s);
catch
    errorFlag =1 ;
end

return;
