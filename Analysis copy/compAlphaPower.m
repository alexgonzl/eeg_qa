

data = [];
data.signal = ALLEEG.data;
data.nChans = ALLEEG.nbchan;
data.SR     = ALLEEG.srate; SR = ALLEEG.srate;
%%
data = dataDecompose(data,'alpha');

%%
EO=find(strcmp({ALLEEG.event.type},'EO  '));
EC=find(strcmp({ALLEEG.event.type},'EC  '));

latencies=[ALLEEG.event.latency];

EOlats = latencies(EO);
EClats = latencies(EC);


%%
epcRange = [1 13];
sampRange = epcRange*SR;
epcSamps = sampRange(1):sampRange(2);
EOtr = zeros(256,numel(EOlats),numel(epcSamps));
ECtr = zeros(256,numel(EClats),numel(epcSamps));
for ii =1:256;    
    for jj = 1:numel(EOlats) 
        EOtr(ii,jj,:) = data.amp(ii,EOlats(jj)+epcSamps);
    end
    for jj = 1:numel(EClats) 
        ECtr(ii,jj,:) = data.amp(ii,EClats(jj)+epcSamps);
    end
end

%%
X = mean(EOtr,3);% mean across time for EO
Y = mean(ECtr,3);% mean across time for EC

keepTrials = 2:11;
mX = mean(X(:,keepTrials),2);  % mean across trials for EO
mY = mean(Y(:,keepTrials),2);  % mean across trials for EC
%%
OzChans = [107 108 115:117 123:126 137 138 139 149:151 158:160];
nChans = 256;
% Oz = 137, O1 = 124, O2=149;
figure(3); clf; hold on;
set(gcf,'position',[200 300 800 400])
plot(1:nChans, [mX(1:nChans) mY(1:nChans)],'linewidth',2)

axis tight
set(gca,'fontsize',18,'box','on')
grid on
xlabel(' Channel ID ')
ylabel(' AvgAmp (\muV) ')
legend(' EO ', ' EC ','location','best')

%%
figure(4); clf; hold on;
set(gcf,'position',[200 300 800 400])
[~,p,~,t]=ttest2(Y',X');
plot(1:nChans, t.tstat,'linewidth',2)

%% 
fileName = '~/Google Drive/Research/EEG_Testing/data/s3/alphaPowerEO-EC.mat';
save(fileName, 'EOtr','ECtr')