
function [out,msg]=tACS_EncodingMain_CueResponse(tacs_er)
% core script for stimulus presentation on tACS Encoding.

% clear all the screens
close all;
sca;

% Define colors
WHITE   = [1 1 1];
BLACK   = [0 0 0];
GREY    = WHITE/2;
RED     = [0.77 0.05 0.2];
BLUE    = [0.2 0.1385 1];
PURPLE  = [.5 0.1 0.5];

%PsychDebugWindowConfiguration;

% output structure
out = [];

% Presentation Parameters
PresParams = [];
PresParams.stimFrequency        = 6;
PresParams.stimDurationInCycles = 0.5;
PresParams.stimDurationInSecs   = 1/PresParams.stimFrequency*PresParams.stimDurationInCycles;
PresParams.cueDurationInSecs    = PresParams.stimDurationInSecs;
%PresParams.noiseFrameInterval   = 1; % define
%PresParams.waitFrameInterval    = 1; % define
PresParams.ITI_Range            = [1.5 2]; % variable ITI in secs
PresParams.MaxResponseTime      = 1;       % maximum to make perceptual decision

% noise mask size -> should be the size of all the stimuli
PresParams.nsMaskSize = [255 255];

% determine cue response mapping depending on subject number and active
% Keyboard.
laptopResponseKeys = ['k','l'];
keypadResponseKeys = ['1','2'];
if mod(tacs_er.subjNum,2)
    responseMap = [1,2];
else
    responseMap = [2,1];
end
laptopResponseKeys = laptopResponseKeys(responseMap);
keypadResponseKeys = keypadResponseKeys(responseMap);

PresParams.CueColorsID{1} = RED;
PresParams.CueColorsID{2} = BLUE;


out.PresParams  = PresParams;
out.expInfo     = tacs_er;

stimNames = tacs_er.EncStimNames;
nTrials   = numel(stimNames);

%%

% Initialize trial timing structure
TimingInfo = [];
TimingInfo.preStimMaskFlip = cell(nTrials,1);
TimingInfo.stimPresFlip = cell(nTrials,1);
TimingInfo.postStimMaskFlip = cell(nTrials,1);
TimingInfo.trialRT          = zeros(nTrials,1);
TimingInfo.trialKeyPress    = cell(nTrials,1);

try
    
    %---------------------------------------------------------------------%
    % Screen and additional presentation parameters
    %---------------------------------------------------------------------%
    % Get keyboard number
    [activeKeyboardID, laptopKeyboardID, pauseKey, resumeKey] = getKeyboardOr10key;    
    % initialize Keyboard Queue
    KbQueueCreate(activeKeyboardID);
    % Start keyboard queue
    KbQueueStart(activeKeyboardID);
    
    if laptopKeyboardID==activeKeyboardID          
          PresParams.RespToCue1 = laptopResponseKeys(1);
          PresParams.RespToCue2 = laptopResponseKeys(2);
    else
        PresParams.RespToCue1 = keypadResponseKeys(1);
        PresParams.RespToCue2 = keypadResponseKeys(2);
    end
    
    % initialie window
    [window, windowRect] = initializeScreen;
    screenXpixels = windowRect(3);
    screenYpixels = windowRect(4);
    
    % Get the centre coordinate of the window
    [xCenter, yCenter] = RectCenter(windowRect);
    
    % Get coordinates for fixation cross
    fixCrossCoords = fixCross(xCenter, yCenter,screenXpixels,screenYpixels);
    
    % Query the frame duration
    ifi = Screen('GetFlipInterval', window);
    
    % Get the durations in frames
    % variable pre-stimulus noise mask duration
    ITIsFrames         = randi(round(PresParams.ITI_Range/ifi),nTrials,1);
    
    % fixed stimulus duration
    stimDurFrames      = round(PresParams.stimDurationInSecs/ifi);
    % post-stim max response period duration
    MaxRespFrames       = round(PresParams.MaxResponseTime /ifi);
    
    % Set the line width for our fixation cross
    lineWidthPix = 4;
    %pre-make noise masks
    Nmasks = 50;
    noiseTextures = cell(Nmasks,1);
    for ii = 1:Nmasks
        noiseTextures{ii} = Screen('MakeTexture', window, rand(PresParams.nsMaskSize(1),PresParams.nsMaskSize(2)));
        tstring = sprintf('Loading Noise Masks %g %%', floor(ii/Nmasks*100));
        DrawFormattedText(window,tstring,'center','center',255,50);
        Screen('Flip',window);
    end
    
    % pre-make image textures
    imgTextures = cell(nTrials,1);
    for ii = 1:10%nTrials
        imgTextures{ii}=Screen('MakeTexture', window, tacs_er.Stimuli(stimNames{ii}));
        tstring = sprintf('Loading Stimuli  %g %%',floor(ii/nTrials*100));
        DrawFormattedText(window,tstring,'center','center',255,50);
        Screen('Flip',window);
    end
    
    % Set encoding cue color
    cueColors = zeros(nTrials,3);
    for ii = 1:nTrials
        if tacs_er.EncStimCue(ii)==1
            cueColors(ii,:) = PresParams.CueColorsID{1};
        else
            cueColors(ii,:) = PresParams.CueColorsID{2};
        end
    end    
    
    %---------------------------------------------------------------------%
    % Participant Instructions
    %---------------------------------------------------------------------%
%     tstring = ['Instructions\n\n' ...
%         'You will be presented with a PURPLE Fixation Cross. '...
%         'The Fixation cross will then turn either RED or BLUE, with a background image of faces and landmarks. '...
%         'Your task is to respond with ' PresParams.RespToCue1 ' for the RED Fixation and '...
%         'with ' PresParams.RespToCue2 ' for BLUE Fixations. ' ...
%         'You will have ' num2str(PresParams.MaxResponseTime ) ' second to respond, and please do so '...
%         'as quickly and as accurately as possible. \n'...
%         'Press ''' resumeKey ''' to begin the experiment.'];
     tstring = ['Instructions\n\n' ...
        'You will be presented with a PURPLE Fixation Cross. '...        
        'Your task is to respond with ' PresParams.RespToCue1 ' for the RED Fixation and '...
        'with ' PresParams.RespToCue2 ' for BLUE Fixations. ' ...
        'You will have ' num2str(PresParams.MaxResponseTime ) ' second to respond '...
        'as quickly and as accurately as possible. \n'...
        'Press ''' resumeKey ''' to begin the experiment.'];

    
    DrawFormattedText(window,tstring, 'wrapat', 'center', 255, 40, [],[],[],[],[xCenter*0.1,0,screenXpixels*0.8,screenYpixels]);
    Screen('Flip',window);
    
    % resume if Resume Key is pressed
    
    WaitTillResumeKey(resumeKey,activeKeyboardID)
    %%
    %---------------------------------------------------------------------%
    % Trials
    %---------------------------------------------------------------------%
    % Set timing for each flip in a trial
    stimFlipDurSecs = (stimDurFrames - 0.5) * ifi;
    
    % Maximum priority level
    topPriorityLevel = MaxPriority(window);
    Priority(topPriorityLevel);
        
    % iterate through trials
    for tt = 1:nTrials
        
        % empty flip var
        flip     = [];
        
        % Pre-stimulus noise mask (variable ITI); store the first one
        Screen('DrawTexture', window, noiseTextures{randi(Nmasks)}, [], [], 0);
        Screen('DrawLines', window, fixCrossCoords,lineWidthPix, PURPLE, [0 0], 2);
        [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, flip.Beampos,] ...
            = Screen('Flip', window);
        TimingInfo.preStimMaskFlip{tt}=flip;
        vbl = flip.VBLTimestamp;
        
        for ii=1:(ITIsFrames(tt)-1)
            Screen('DrawTexture', window, noiseTextures{randi(Nmasks)}, [], [], 0);
            Screen('DrawLines', window, fixCrossCoords,lineWidthPix, PURPLE, [0 0], 2);
            vbl = Screen('Flip', window, vbl + 0.5*ifi);            
        end
        
        % Checks if the Pause Key has been pressed.
        CheckForPauseKey(pauseKey,resumeKey,activeKeyboardID)
        KbQueueFlush(activeKeyboardID);
        
        % Draw Stimulus for stimFlipDurSecs
        Screen('DrawTexture', window, imgTextures{tt}, [], [], 0);
        Screen('DrawLines', window, fixCrossCoords,lineWidthPix, cueColors(tt,:), [0 0], 2);
        [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, flip.Beampos,] ...
            = Screen('Flip', window, vbl + 0.5*ifi);
        TimingInfo.stimPresFlip{tt}=flip;
        trialTime = GetSecs;
        vbl = flip.VBLTimestamp;
        
        % Draw Post-Stim Noise
        Screen('DrawTexture', window, noiseTextures{randi(Nmasks)}, [], [], 0);
        [flip.VBLTimestamp, flip.StimulusOnsetTime, flip.FlipTimestamp, flip.Missed, flip.Beampos,] ...
            = Screen('Flip', window, vbl + stimFlipDurSecs);
        
        TimingInfo.postStimMaskFlip{tt}=flip;
        vbl = flip.VBLTimestamp;
        
        % Re-draw noise mask until response or until max resp time
        for ii = 1:(MaxRespFrames-1)
            [pressed,firstPress] = KbQueueCheck(activeKeyboardID);
            
            if pressed
                TimingInfo.trialKeyPress{tt} = KbName(firstPress);
                TimingInfo.trialRT(tt) = firstPress(find(firstPress,1))-trialTime;
                break
            end
            Screen('DrawTexture', window, noiseTextures{randi(Nmasks)}, [], [], 0);
            vbl  = Screen('Flip', window,vbl + 0.5*ifi);
        end
        
        % if no response.
        if ~pressed
            TimingInfo.trialRT(tt) = nan;
        end
        KbQueueFlush(activeKeyboardID);
        
    end
    
    %---------------------------------------------------------------------%
    % End of Experiment
    %---------------------------------------------------------------------%
    KbQueueStop(activeKeyboardID);
    
    tstring = ['End of Experiment.\n \n' ...
        'Press ''' resumeKey ''' to exit.'];
    
    DrawFormattedText(window,tstring, 'center', 'center', 255, 40);
    Screen('Flip',window);
    getKey(resumeKey,activeKeyboardID);
    
    msg='allGood';
catch msg
    sca
    keyboard
end

% store additional outputs
out.TimingInfo = TimingInfo;


% Clear the screen
Priority(0);
sca;
Screen('CloseAll');

save;
ShowCursor;

end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% auxiliary functions and definitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set Fixation Cross Coordinates
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

% Wait until Resume Key is pressed on the keyboard
function WaitTillResumeKey(resumeKey,activeKeyboardID)

KbQueueFlush(activeKeyboardID);
while 1
    [pressed,firstPress] = KbQueueCheck(activeKeyboardID);
    if pressed
        if strcmp(resumeKey,KbName(firstPress));
            break
        end
    end
    WaitSecs(0.1);
end
KbQueueFlush(activeKeyboardID);
end

% Check if the resume key has been pressed, and pause exection until resume
% key is pressed.
function CheckForPauseKey(pauseKey,resumeKey,activeKeyboardID)

[pressed,firstPress] = KbQueueCheck(activeKeyboardID);
if pressed
    if strcmp(pauseKey,KbName(firstPress));
        WaitTillResumeKey(resumeKey,activeKeyboardID)
    end
end
end