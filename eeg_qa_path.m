function thePath = eeg_qa_path(subjNum)
% eeg_qa path
% Quality assurance presentation scripts for eeg
% returns path information
% subjNum   -> subject number (integer)
%
% subject 0 reserved for debugging/testing
%------------------------------------------------------------------------%
% Author:       Alex Gonzalez (from similar lab copies)
% Created:      Aug 24, 2015
% LastUpdate:   Aug 24, 2015
%------------------------------------------------------------------------%

basepath = pwd;
cd(basepath);
addpath(basepath);

thePath = [];
thePath.subjNum = subjNum;
thePath.main    = basepath;
thePath.stim    = fullfile(pwd,'stim');
if ~exist(thePath.stim,'dir')
    error('At the wrong directory, necessary files not found.')
end
thePath.scripts = fullfile(pwd,'scripts');
thePath.data    = fullfile(pwd,'data');

subjectPath = strcat(thePath.data,'/s',num2str(subjNum),'/');

if exist(subjectPath,'dir')
    if ~(subjNum==0)
        warning('Subject directory already present.')
    end
else
    mkdir(subjectPath);
end
thePath.subjectPath = subjectPath;

addpath(genpath(thePath.stim));
addpath(genpath(thePath.scripts));
addpath(genpath(thePath.subjectPath));

return


