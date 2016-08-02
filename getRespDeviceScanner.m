function [activeKeyID, localKeyID, pauseKey, resumeKey] = getRespDeviceScanner
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
% Curtis/Aris laptop productID = 594;
% Mock Scanner 5 button box productID = 6;
% Scanner 4x2 button boxes productID =8;
% Mock Scanner Belkin button box productID=38960;
% Wagner 10 key= 41002

d = PsychHID('Devices');
lapkey = 0;
devkey = 0;
% x=strfind({d.usageName},'Keyboard');
% find(~cellfun(@isempty,x))
for n = 1:length(d)
    if strcmp(d(n).usageName,'Keyboard')&&(d(n).productID==594)
        lapkey = n;
    elseif strcmp(d(n).usageName,'Keyboard')&&(d(n).productID==38960)
        devkey = n;
    elseif strcmp(d(n).usageName,'Keyboard')&&(d(n).productID==41002)
        devkey = n;
    elseif strcmp(d(n).usageName,'Keyboard')&&(d(n).productID==8)
        devkey = n;
        resumeKey = '9';
    end
end

if lapkey==0
    fprintf('Laptop keyboard not found! Try restarting MATLAB.\n');
end
if devkey==0
    fprintf('10-key not found! Try restarting MATLAB.\n');
end

activeKeyID = devkey;
localKeyID = lapkey;
pauseKey = '/';

% if in scanner with 2x4 button box; resume key is right index finger
% if devkey == 8
%     resumeKey = '9';
% else
%     resumeKey = '*';
% end

end
