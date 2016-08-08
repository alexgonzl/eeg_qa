% Analytic Signal Analysis Demo Script

%% create a few signals

% tones per channel (in Hz)
f(1) = 10; 
f(2) = 5;
f(3) = 15;
f(4) = 0;
n =numel(f); % number of channels

% phase per channel (in rad)
th = zeros(1,n);

% tone amplitude by channel
A  = [0.5 1:(n-1)]; 

% noise power per channel
sig2 = ones(1,n);

% time
fs = 500; % samps/s
Ttime = 10; % total time
N = Ttime*fs; % total # of samples
t = linspace(0,Ttime-1/fs,N); % time vector

X = zeros(n,N);
for ch = 1:n
    X(ch,:) = A(ch)*sin(2*pi*t*f(ch)+th(ch))+sig2(ch)*randn(1,N);
end

figure()
plot(X')
%% check spectrums per signal

h = spectrum.welch;
h.segmentLength = 2^nextpow2(fs/2);
h.WindowName = 'hann';
for ch = 1:n
    figure(ch);    
    psd(h,X(ch,:),'fs',fs,'Nfft',2048)
    title(sprintf('PSD channel %i',ch));
end

%% filter for alpha

bandLimits = [8 12];
Xf = channelFilt(X,fs,bandLimits(2),bandLimits(1));
for ch = 1:n
    figure(ch+n);
    psd(h,Xf(ch,:),'fs',fs,'Nfft',2048)
    title(sprintf('PSD of filtered channel %i',ch));
end

figure()
plot(Xf')
figure();
plot(Xf'-X')
%% get inst. power
Xa = zeros(n,N);
for ch = 1:n
    Xa(ch,:) = abs(hilbert(Xf(ch,:)));
end

% Theoretically Xa(ch,:) should hover around A(ch)
mean(Xa,2)
figure()
plot(Xa')

%% OR! Get analytic signal for a specific band
band = 'alpha';
data=[];
data.signal = X;
data.SR = fs;
data.nChans = n;
data = dataDecompose(data,band);

