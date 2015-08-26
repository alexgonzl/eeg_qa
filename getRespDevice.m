function [activeKeyID, localKeyID, pauseKey, resumeKey] = getRespDevice
%
% script to set response keyboard.
% activeKeyID   -> active keyboard
% localKeyID    -> local keyboard
%
% Recca: productID=560
% Karen's laptop: productID=566
% Wendyo: productID=566
% Karen's desktop: productID=544
% Recursion: productID=5
% Alex's laptop productID = 601;
% Mock Scanner 5 button box productID = 6;
% Mock Scanner Belkin button box productID=38960;

d = PsychHID('Devices');
lapkey = 0;
devkey = 0;
% x=strfind({d.usageName},'Keyboard');
% find(~cellfun(@isempty,x))
for n = 1:length(d)
    if strcmp(d(n).usageName,'Keyboard')&&(d(n).productID==601)
        lapkey = n;
    elseif strcmp(d(n).usageName,'Keyboard')&&(d(n).productID==38960)
        devkey = n;    
    end
end

if lapkey==0
    fprintf('Laptop keyboard not found! Try restarting MATLAB.\n');
end
if devkey==0
    fprintf('10-key not found! Try restarting MATLAB.\n');
end
while 1
    choice = input('Do you want to use [1] laptop keyboard, or [2] 10-key input? ');
    if choice==1
        activeKeyID = lapkey; 
        localKeyID = lapkey;
        pauseKey = 'p';
        resumeKey = 'r';
        break
    elseif choice==2
        activeKeyID = devkey; 
        localKeyID = lapkey;
        pauseKey = '/';
        resumeKey = '*';
%        pauseKey = 'p';
%        resumeKey = 'r';
        break
    end
end
