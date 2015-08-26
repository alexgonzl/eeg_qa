function [Window, Rect] = initializeScreen
% function initialize screen to defaults in experiment.
% returns the window ptr, and the dimensions

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 0);

screenNumber = max(Screen('Screens')); % 0 = main display
white = WhiteIndex(screenNumber);
grey  = white/2;

% Open an on screen window
[Window, Rect] = PsychImaging('OpenWindow', screenNumber, grey);

% Enable alpha blending for anti-aliasing
Screen('BlendFunction', Window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% Set fonts
Screen('TextFont',Window,'Arial');
Screen('TextSize',Window,36);

HideCursor; % Remember to type ShowCursor later

