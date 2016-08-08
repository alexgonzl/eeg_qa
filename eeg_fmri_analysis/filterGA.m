% EEG-fMRI eeg gradient cleaning and alpha power
% 1) Export EEG data to Raw EGI binary
% 2) Import the data to EEG lab
% 3) set subject number, run, savepath
%%
subjNum     = 6;
run         = 2;
cleanGAFlag = 1;
savepath    = ['~/Google Drive/Research/EEG_Testing/data/s' num2str(subjNum)];

% get TR events
S = [];
% signal
S.signal = ALLEEG.data;
% Sampling Rate
S.SR = ALLEEG.srate;

% Default Parameters:
% how many epochs to for template
S.NPulseEpochs = 10;

% how much should the sliding window move
S.sldwin_epochs = 5;%floor(S.NPulseEpochs/2);

% how many slices per volume
S.slicespervolume = 37;

% Volume acquisition length (TR length in seconds)
S.TR_length = 2;

% MR_Markers
MR_PulsesIDs = find(strcmp({ALLEEG.event.type},'TREV'));
S.MR_Pulses = [ALLEEG.event(MR_PulsesIDs).latency];
S.allEvents = ALLEEG.event;

%do not include the first 10
S.ignore_firstpulses = 5;
S.ignore_lastpulses = 0;

% filter Gradient artifact.
if cleanGAFlag == 1
   S = ST_GA_Clean(S);   
   fileName = [savepath '/EEG_GAclean_r' num2str(run) '.mat'];   
else    
   fileName = [savepath '/EEG_r' num2str(run) '.mat'];   
end

% compute alpha power
S.nChans =256;
S = dataDecompose(S,'alpha');
save(fileName,'S')

%%
EO=find(strcmp({S.allEvents.type},'EOB '));
EC=find(strcmp({S.allEvents.type},'ECB '));
AB=find(strcmp({S.allEvents.type},'AB  '));

latencies=[ALLEEG.event.latency];

EOlats = latencies(EO);
EClats = latencies(EC);
ABlats = latencies(AB);

epcRange = [1 9];
sampRange = epcRange*S.SR;
epcSamps = sampRange(1):sampRange(2);
EOtr = zeros(256,numel(EOlats),numel(epcSamps));
ECtr = zeros(256,numel(EClats),numel(epcSamps));
ABtr = zeros(256,numel(ABlats),numel(epcSamps));
for ii =1:256;    
    for jj = 1:numel(EOlats) 
        EOtr(ii,jj,:) = S.amp(ii,EOlats(jj)+epcSamps);
    end
    for jj = 1:numel(EClats) 
        ECtr(ii,jj,:) = S.amp(ii,EClats(jj)+epcSamps);
    end
    for jj = 1:numel(ABlats) 
        ABtr(ii,jj,:) = S.amp(ii,ABlats(jj)+epcSamps);
    end
end

%%%
X = mean(EOtr,3);% mean across time for EO
Y = mean(ECtr,3);% mean across time for EC
Z = mean(ABtr,3);% mean across time for AB

% choose from 2 to 11, discarding 1 and 12.
%keepTrials = 2:8;
mX = mean(X,2);  % mean across trials for EO
mY = mean(Y,2);  % mean across trials for EC
mZ = mean(Z,2);  % mean across trials for AB

fileName = [savepath '/EEG_alpha_EC_EO' num2str(run) '.mat'];
save(fileName,'EOtr','ECtr','ABtr','mX','mY','mZ')
%% mean channel amplitude
OzChans = [107 108 115:117 123:126 137 138 139 149:151 158:160];
nChans = 256;
% Oz = 137, O1 = 124, O2=149;
figure(3); clf; hold on;
set(gcf,'position',[200 300 800 400])
plot(1:nChans, [mX mY],'linewidth',2)

axis tight
set(gca,'fontsize',18,'box','on')
grid on
xlabel(' Channel ID ')
ylabel(' AvgAmp (\muV) ')
legend(' EO ', ' EC ','location','best')
print('-dpdf', [savepath '/meanChDiffEC-EO_s' num2str(subjNum) 'r' num2str(run)])
%% histogram of mean differences between EC-EO
figure(4); clf; hold on;
set(gcf,'position',[200 300 800 400],'paperPositionMode','auto')
set(gcf,'paperunits','normalized','paperPosition',[0.1 0.3 0.8 0.4])
h=histogram(mY-mX);
set(h,'FaceColor',[0 0 0],'edgeColor','none')
xlabel(' Amplitude EC-EO (\muV)')
ylabel(' channel counts ')
set(gca, 'fontsize',16)
print('-dpdf', [savepath 'hist_meanChDiffEC-EO_s' num2str(subjNum) 'r' num2str(run)])
%% histogram of mean power differences between EC-EO
figure(4); clf; hold on;
set(gcf,'position',[200 300 800 400],'paperPositionMode','auto')
set(gcf,'paperunits','normalized','paperPosition',[0.1 0.3 0.8 0.4])
h=histogram(mY.^2-mX.^2);
set(h,'FaceColor',[0 0 0],'edgeColor','none')
xlabel(' Power EC-EO (\muV ^2)')
ylabel(' channel counts ')
set(gca, 'fontsize',16)
print('-dpdf', [savepath 'meanChPowerDiffEC-EO_s' num2str(subjNum) 'r' num2str(run)])

%% histogram of t statistics of amplitude EC-EO
figure(5); clf; hold on;
set(gcf,'position',[200 300 800 400],'paperPositionMode','auto')
set(gcf,'paperunits','normalized','paperPosition',[0.1 0.3 0.8 0.4])
[~,p,~,t]=ttest2(Y',X');
h=histogram(t.tstat);
set(h,'FaceColor',[0 0 0],'edgeColor','none')
xlabel(' EC-EO  (T-Stat) ')
ylabel(' channel counts ')
set(gca, 'fontsize',16)
print('-dpdf', [savepath 'TStatEC-EO_s' num2str(subjNum) 'r' num2str(run)])

%% histogram of t statistics of power EC-EO
[~,p,~,t]=ttest2(Y.^2',X.^2');
figure(6); clf; hold on;
set(gcf,'position',[200 300 800 600],'paperPositionMode','auto')
set(gcf,'paperunits','normalized','paperPosition',[0.1 0.3 0.8 0.6])
topoplot(t.tstat,EEG.urchanlocs,'style','both','maplimits',[-5 5],'plotrad',0.6);
colormap hot
set(gca, 'fontsize',16)
c=colorbar;
c.Label.String=' T Val ';
print('-dpdf', [savepath 'TStatEC-EO_Topo_s' num2str(subjNum) 'r' num2str(run)])

%% topoplot of mean differences: EC-EO
figure(7); clf; hold on;
set(gcf,'position',[200 300 800 600],'paperPositionMode','auto')
set(gcf,'paperunits','normalized','paperPosition',[0.1 0.3 0.8 0.6])
topoplot(mY-mX,EEG.urchanlocs,'style','both','maplimits',[-5 5],'plotrad',0.6);
colormap hot
set(gca, 'fontsize',16)
c=colorbar;
c.Label.String=' \mu V ';
print('-dpdf', [savepath 'meanChDiff_EC-EO_Topo_s' num2str(subjNum) 'r' num2str(run)])

%% topoplot of mean power differences: EC-EO
figure(7); clf; hold on;
set(gcf,'position',[200 300 800 600],'paperPositionMode','auto')
set(gcf,'paperunits','normalized','paperPosition',[0.1 0.3 0.8 0.6])
topoplot(mY.^2-mX.^2,EEG.urchanlocs,'style','both','maplimits',[-50 50],'plotrad',0.6);
colormap hot
set(gca, 'fontsize',16)
c=colorbar;
c.Label.String=' \mu V ^2 ';
print('-dpdf', [savepath 'meanChPowerDiff_EC-EO_Topo_s' num2str(subjNum) 'r' num2str(run)])
