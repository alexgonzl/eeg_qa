function [out,msg]=eeg_qa_task(thePath)
%
% [out,msg]=eeg_qa_task(thePath)
% this stimulus presentation script is for quality assurance testing in eeg
% there are three prolong conditions:
%
% 1) eyes open
% 2) eyes closed
% 3) arrows task
%
% the three form a mini block, there are 20 mini-blocks
% thePath contains all relevant information about the paths
%
%------------------------------------------------------------------------%
% Author:       Alex Gonzalez
% Created:      Aug 24th, 2015
% LastUpdate:   July 5, 2016
%------------------------------------------------------------------------%

%% Set-up

% clear all the screens
close all;
sca;

% Define colors
FixCrossTask1  = [0.1 0.1 0.1];
FixCrossTask2  = [0.77 0.05 0.2];
%PsychDebugWindowConfiguration;

% Presentation Parameters
PresParams = [];
PresParams.Conditions            = {'eyesOpen','eyesClosed','arrows'};
PresParams.TimeDur              = 10; % time duration per conditions
PresParams.nMiniBlocks          = 10;
PresParams.lineWidthPix         = 5;  % Set the line width for our fixation cross
PresParams.arrowsITI            = 0.3;
PresParams.arrowsMaxRespTime    = 3;
PresParams.NetStationFlag       = 0;
PresParams.NetStationIP         = '10.0.0.42';
PresParams.Scanned              = 1;
nMiniBlocks             = PresParams.nMiniBlocks;
nConds                  = numel(PresParams.Conditions);

if PresParams.Scanned 
    PresParams.PostInstBuffer = 10;
else
    PresParams.PostInstBuffer = 0;
end

% set stimulus order, no back-to-back conds.
PresParams.CondOrder            = zeros(nMiniBlocks,nConds);
PresParams.CondOrder(1,:)       = randperm(nConds);
for ii = 2:nMiniBlocks
    x = PresParams.CondOrder(ii-1,:);
    y = randperm(nConds);
    while y(1)==x(end)
        y = randperm(nConds);
    end
    PresParams.CondOrder(ii,:)=y;
end

% determine cue response mapping depending on subject number and active
% Keyboard. this is for the arrows task.
laptopResponseKeys = ['k','l'];
keypadResponseKeys = ['1','2'];
scannerResponseKeys  = ['9','8'];
scannerResponseInst  = {'Index Finger','Middle Finger'};

if mod(thePath.subjNum,2)
    responseMap = [1,2];
else
    responseMap = [2,1];
end
laptopResponseKeys = laptopResponseKeys(responseMap);
keypadResponseKeys = keypadResponseKeys(responseMap);
scannerResponseKeys = scannerResponseKeys(responseMap);
scannerResponseInst = scannerResponseInst(responseMap);

PresParams.keypadResponseKeys=keypadResponseKeys;
PresParams.laptopResponseKeys=laptopResponseKeys;

% output structure
out=[];
out.PresParams = PresParams;
%%

% Initialize trial timing structure
TimingInfo = [];
TimingInfo.eyesOpenCondFlip = cell(PresParams.nMiniBlocks,1);
TimingInfo.eyesClosedCondFlip= cell(PresParams.nMiniBlocks,1);
TimingInfo.arrowsCondFlip   = cell(PresParams.nMiniBlocks,1);
TimingInfo.arrowsPresFlip   = cell(PresParams.nMiniBlocks,1);
TimingInfo.arrowsRTs        = cell(PresParams.nMiniBlocks,1);
TimingInfo.arrowsCond       = cell(PresParams.nMiniBlocks,1);
TimingInfo.arrowsResp       = cell(PresParams.nMiniBlocks,1);

try
    
    %---------------------------------------------------------------------%
    % Screen and additional presentation parameters
    %---------------------------------------------------------------------%
    % Get keyboard number
    if PresParams.Scanned
        [activeKeyboardID, laptopKeyboardID, pauseKey, resumeKey] = getRespDeviceScanner;
        disp(activeKeyboardID);
        disp(laptopKeyboardID);
        disp(resumeKey);
    else
        [activeKeyboardID, laptopKeyboardID, pauseKey, resumeKey] = getRespDevice;        
    end
    
    % initialize Keyboard Queue
    KbQueueCreate(activeKeyboardID);
    % Start keyboard queue
    KbQueueStart(activeKeyboardID);
    
    if laptopKeyboardID==activeKeyboardID
        PresParams.RespToCue = laptopResponseKeys;        
        InstructionKeys      = PresParams.RespToCue;
    elseif PresParams.Scanned
        PresParams.RespToCue = scannerResponseKeys;
        InstructionKeys      = scannerResponseInst;
    else
        PresParams.RespToCue = keypadResponseKeys;
        InstructionKeys      = PresParams.RespToCue;
    end
    
    if PresParams.NetStationFlag
        [status, er]= NetStation('Connect',PresParams.NetStationIP);
        if status~=0
            error(er)
        end
        NetStation('Synchronize');
        NetStation('StartRecording')
        NetStation('FlushReadbuffer');
    end
   
    
    % initialize window
    [window, windowRect] = initializeScreen;
    screenXpixels = windowRect(3);
    screenYpixels = windowRect(4);
    
    % Get the centre coordinate of the window
    [xCenter, yCenter] = RectCenter(windowRect);
    
    % Get coordinates for fixation cross
    fixCrossCoords = fixCross(xCenter, yCenter,screenXpixels,screenYpixels);
    
    % Query the frame duration
    ifi = Screen('GetFlipInterval', window);
    
    % Flashing textures matrices
    flashTM{1} = Screen('MakeTexture', window, 0.8*ones(300));
    flashTM{2} = Screen('MakeTexture', window, 0.2*ones(300));
    
    %---------------------------------------------------------------------%
    % Participant Instructions
    %---------------------------------------------------------------------%
    
    if PresParams.Scanned
        resumeIntr = 'Index Finger';
    else
        resumeIntr = resumeKey;
    end
    % Task(a) instructions
    cond1_instr = ['Task(a): Fixation \n\n\n\n'...
        'Please focus to the fixation cross and try not to close your eyes.\n'...
        'Press ''' resumeIntr ''' to begin.'];
    
    % Task(b) instructions
    cond2i_instr = ['Task(b): Eyes Closed \n\n\n\n'...
        'Please close your eyes until the screen flashes.\n'...
        'Press ''' resumeIntr ''' to begin.'];
    
    cond2ii_instr = ['Please open your eyes. \n'...
        'Press ''' resumeIntr ''' to continue.'];
    
    % Task(c) instructions
    cond3_instr = ['Task(c)\n\n\n\n'...
        'Please respond with '  InstructionKeys(1) ' for left arrows, '...
        'and ' InstructionKeys(2) ' for right arrows.\n'...
        'Press ''' resumeIntr ''' to begin.'];
      % Task(c) instructions
    cond3_instr = ['Task(c)\n\n\n\n'...
        'Please respond with '  InstructionKeys{1} ' for left arrows, '...
        'and ' InstructionKeys{2} ' for right arrows.\n'...
        'Press ''' resumeIntr ''' to begin.'];
    
    if PresParams.Scanned ==1
        tstring = ['Instructions\n\n' ...
        'There are three tasks that will be presented at random. \n'...
        'Task A: you will be presented a fixation cross in which you will '...
        'be asked to maintain fixation. \n' ...
        'Task B: you will be closing your eyes until the screen flashes, ' ...
        'you will need to press the button to continue. \n'...
        'Task C: if a left arrow appears respond with the ' InstructionKeys{1} ...
        ' key, if a right arrow appears respond with the ' InstructionKeys{2} ' key. \n\n'...
        'Get Ready!!!'];
    else
        tstring = ['Instructions\n\n' ...
        'There are three tasks that will be presented at random. \n'...
        'Task A: you will be presented a fixation cross in which you will '...
        'be asked to maintain fixation. \n' ...
        'Task B: you will be closing your eyes until the screen flashes, ' ...
        'you will need to press the button to continue. \n'...
        'Task C: if a left arrow appears respond with the ' InstructionKeys(1) ...
        ' key, if a right arrow appears respond with the ' InstructionKeys(2) ' key. \n\n'...
        'Press ''' resumeKey ''' to begin the experiment.'];
    end
       
    DrawFormattedText(window,tstring, 'wrapat', 'center', 255, 75, [],[],[],[],[xCenter*0.1,0,screenXpixels*0.8,screenYpixels]);
    Screen('Flip',window);
    
    % resume if Resume Key is pressed
    WaitTillResumeKey(resumeKey,activeKeyboardID)
    
     
    if PresParams.Scanned == 1
        cnt = 1;
        while 1
            [errorFlag , scannerStartTime] = startScan_eprime;
            if errorFlag==0
                PresParams.scannerStartTime = scannerStartTime;
                break                
            end
            cnt = cnt +1;
            if cnt>=10
                error('Could not trigger the scanner after 10 tries')
            end            
        end        
    end
    
    WaitSecs(PresParams.PostInstBuffer)
    
    
    %%
    %---------------------------------------------------------------------%
    % Mini-Blocks
    %---------------------------------------------------------------------%
    
    % Maximum priority level
    topPriorityLevel = MaxPriority(window);
    Priority(topPriorityLevel);
    
    % iterate through mini-blocks
    for bb = 1:nMiniBlocks
        % iterate through conditions
        for jj = 1:nConds
            currentCond = PresParams.CondOrder(bb,jj);
            switch currentCond
                % Task(a)
                case 1
                    DrawFormattedText(window,cond1_instr, 'center', 'center', ...
                        255, 75, [],[],[],[]);
                    Screen('Flip',window);
                    WaitTillResumeKey(resumeKey,activeKeyboardID)
                    
                    Screen('DrawLines', window, fixCrossCoords,PresParams.lineWidthPix, FixCrossTask1, [0 0], 2);
                    [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, flip.Beampos,] ...
                        = Screen('Flip', window);
                    TimingInfo.eyesOpenCondFlip{bb} = flip;
                    
                    if PresParams.NetStationFlag
                        NetStation('Event','EOB',TimingInfo.eyesOpenCondFlip{bb}.VBLTimestamp);
                    end                    
                    WaitSecs(PresParams.TimeDur)
                    
                    % Task(b)
                case 2
                    DrawFormattedText(window,cond2i_instr, 'center', 'center', 255, 75, ...
                        [],[],[],[]);
                    Screen('Flip',window);
                    WaitTillResumeKey(resumeKey,activeKeyboardID)
                    
                    Screen('DrawLines', window, fixCrossCoords,PresParams.lineWidthPix, FixCrossTask2, [0 0], 2);
                    [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, flip.Beampos,] ...
                        = Screen('Flip', window);
                    TimingInfo.eyesClosedCondFlip{bb} = flip;
                    
                    if PresParams.NetStationFlag
                        NetStation('Event','ECB',TimingInfo.eyesClosedCondFlip{bb}.VBLTimestamp);
                    end
                    WaitSecs(PresParams.TimeDur)
                    
                    % flip screens until response is made
                    cnt=0;
                    while 1
                        [pressed,~] = KbQueueCheck(activeKeyboardID);
                        if pressed
                            break
                        end
                        Screen('DrawTexture', window,flashTM{mod(cnt,2)+1});
                        DrawFormattedText(window,cond2ii_instr, 'center', 0.75*screenYpixels);
                        Screen('Flip', window);
                        cnt = cnt+1;
                    end
                    
                    % Task(c)
                case 3
                    DrawFormattedText(window,cond3_instr, 'center', 'center', 255, 75, ...
                        [],[],[],[]);
                    Screen('Flip',window);
                    WaitTillResumeKey(resumeKey,activeKeyboardID)
                    
                    Screen('DrawLines', window, fixCrossCoords,PresParams.lineWidthPix, FixCrossTask1, [0 0], 2);
                    [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, flip.Beampos,] ...
                        = Screen('Flip', window);
                    TimingInfo.arrowsCondFlip{bb} = flip;
                    if PresParams.NetStationFlag
                        NetStation('Event','AB',flip.VBLTimestamp);
                    end
                    
                    TimeLimit = GetSecs + PresParams.TimeDur;
                    tt = 1;
                    while GetSecs < TimeLimit
                        x = randi(2);
                        if mod(x,2)
                            TimingInfo.arrowsCond{bb}(tt) = 1;
                            arrow = '<';
                        else
                            TimingInfo.arrowsCond{bb}(tt) = 2;
                            arrow = '>';
                        end
                        
                        % display arrow
                        DrawFormattedText(window, arrow,'center','center',255);
                        [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, ...
                            flip.Beampos] = Screen('Flip',window);
                        TimingInfo.arrowsPresFlip{bb}(tt) = flip.VBLTimestamp;
                        trialTime = GetSecs;
                        
                        if PresParams.NetStationFlag
                            NetStation('Event','A',TimingInfo.arrowsPresFlip{bb}(tt));
                        end
                        
                        % display until response
                        [secs,key]=KbQueueWait2(activeKeyboardID,PresParams.arrowsMaxRespTime);
                        if secs<inf
                            TimingInfo.arrowsRTs{bb}(tt) = secs-trialTime;
                            TimingInfo.arrowsResp{bb}{tt} = key;
                        else
                            TimingInfo.arrowsRTs{bb}(tt) = nan;
                            TimingInfo.arrowsResp{bb}{tt} = 'noanswer';
                        end
                        tt = tt+1;
                        
                        % empty the screen
                        Screen('Flip',window);
                        %ITI
                        WaitSecs(PresParams.arrowsITI)
                        
                    end
                otherwise
                    error('unrecognized condition')
            end
        end
        
        % save every mini-block
        tempName = sprintf('/eeg_qa.s%i.block%i.%s.mat;', thePath.subjNum,bb,datestr(now,'dd.mm.yyyy.HH.MM'));
        save([thePath.subjectPath,tempName],'TimingInfo');
        
        if PresParams.NetStationFlag            
            NetStation('Synchronize');
            NetStation('FlushReadbuffer');
        end
    end
    
    %---------------------------------------------------------------------%
    % End of Experiment. Store data, and Close.
    %---------------------------------------------------------------------%
    
    % store additional outputs
    out.TimingInfo = TimingInfo;
    
    % save
    fileName = 'eeg_qa.mat';
    cnt = 0;
    while 1
        savePath = strcat(thePath.subjectPath,'/',fileName);
        if ~exist(savePath,'file')
            save(savePath,'out')
            break
        else
            cnt = cnt+1;
            warning(strcat(fileName,' already existed.'))
            fileName = strcat('eeq_qa','-',num2str(cnt),'.mat');
            warning(strcat('saving as ', fileName))
        end
    end
    
    % End of Experiment string
    tstring = ['End of Experiment.\n \n' ...
        'Press ''' resumeKey ''' to exit.'];
    
    DrawFormattedText(window,tstring, 'center', 'center', 255, 40);
    Screen('Flip',window);
    WaitTillResumeKey(resumeKey,activeKeyboardID)
    
    if PresParams.NetStationFlag            
        NetStation('StopRecording');            
    end
    msg='allGood';
catch msg
    sca
    keyboard
end

% Clear the screen
Priority(0);
sca;
KbQueueStop(activeKeyboardID);
Screen('CloseAll');
ShowCursor;
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% auxiliary functions and definitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %-------------------------------------------------------------------------%
% fixCrossCoords
% Set Fixation Cross Coordinates
%-------------------------------------------------------------------------%
function fixCrossCoords = fixCross(xCenter, yCenter,screenXpixels,screenYpixels)

fixCrossXlength = max(0.02*screenXpixels,0.02*screenYpixels); % max of 2% screen dims
fixCrossYlength = fixCrossXlength;

LeftExtent  = xCenter-fixCrossXlength/2;
RightExtent = xCenter+fixCrossXlength/2 ;
BottomExtent = yCenter+fixCrossYlength/2 ;
TopExtent   =  yCenter- fixCrossYlength/2 ;

fixCrossXCoords   = [LeftExtent RightExtent; yCenter yCenter];
fixCrossYCoords   = [xCenter xCenter; BottomExtent TopExtent];

fixCrossCoords       = [fixCrossXCoords fixCrossYCoords];

end

%-------------------------------------------------------------------------%
% WaitTillResumeKey
% Wait until Resume Key is pressed on the keyboard
%-------------------------------------------------------------------------%
function WaitTillResumeKey(resumeKey,activeKeyboardID)

KbQueueFlush(activeKeyboardID);
while 1
    [pressed,firstPress] = KbQueueCheck(activeKeyboardID);
    if pressed
        key = KbName(firstPress);
        if strcmp(num2str(resumeKey),key(1));
            break
        end
    end
    WaitSecs(0.1);
end
KbQueueFlush(activeKeyboardID);
end

%-------------------------------------------------------------------------%
% CheckForPauseKey
% Check if the resume key has been pressed, and pause exection until resume
% key is pressed.
%-------------------------------------------------------------------------%
function CheckForPauseKey(pauseKey,resumeKey,activeKeyboardID)

[pressed,firstPress] = KbQueueCheck(activeKeyboardID);
if pressed
    if strcmp(pauseKey,KbName(firstPress));
        WaitTillResumeKey(resumeKey,activeKeyboardID)
    end
end
end
