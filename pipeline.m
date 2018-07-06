%% Branch 1. basic config - PEDRO
AddPaths('Pedro_iMAC')
parpool(16) % initialize number of cores

%% Initialize Directories
%project_name = 'Calculia_production';
project_name = 'MMR';
%project_name = 'Memoria';
project_name = 'MFA';
project_name = '7Heaven';
project_name = 'Scrambled';

dirs = InitializeDirs('Pedro_iMAC', project_name);

%% Create folders
%sbj_name = 'S18_124';
%sbj_name = 'S14_69b_RT';
%sbj_name = 'S14_64_SP';
%sbj_name = 'S13_57_TVD';
sbj_name = 'S18_125';

%% Get block names
block_names = BlockBySubj(sbj_name,project_name);
% Manually edit this function to include the name of the blocks:

%% Create subject folders
CreateFolders(sbj_name, project_name, block_names, dirs)
% this creates the fist instance of globalVar which is going to be
% updated at each step of the preprocessing accordingly

%% Get iEEG and Pdio sampling rate and data format
[fs_iEEG, fs_Pdio, data_format] = GetFSdataFormat(sbj_name);

%% Get marked channels
[refChan, badChan, epiChan, emptyChan] = GetMarkedChans(sbj_name);
ref_chan = [];
epi_chan = [];
empty_chan = []; % INCLUDE THAT in SaveDataNihonKohden SaveDataDecimate

%% Copy the iEEG and behavioral files from server to local folders
% Login to the server first?
% Should we rename the channels at this stage to match the new naming?
% This would require a table with chan names retrieved from the PPT

dirs_server_root = '/Volumes/neurology_jparvizi$/SHICEP_S11_31_DZ/S11_31a_DZa(Data ECoG)/TDT Data'; % manually retrieved
parfor i = 1:length(block_names)
    CopyFilesServer(sbj_name,project_name,block_names{i},data_format,dirs, [dirs_server_root block_names{i}])
end


%% Branch 2 - data conversion - PEDRO
if strcmp(data_format, 'edf')
    SaveDataNihonKohden(sbj_name, project_name, block_names, dirs, ref_chan, epi_chan, empty_chan) %
elseif strcmp(data_format, 'TDT')
    SaveDataDecimate(sbj_name, project_name, block_names, fs_iEEG, fs_Pdio, dirs, ref_chan, epi_chan, empty_chan) %% DZa 3051.76
else
    error('Data format has to be either edf or TDT format')
end

%% Convert berhavioral data to trialinfo
OrganizeTrialInfoMMR(sbj_name, project_name, block_names, dirs) %%% FIX TIMING OF REST AND CHECK ACTUAL TIMING WITH PHOTODIODE!!! %%%
OrganizeTrialInfoMemoria(sbj_name, project_name, block_names, dirs)
%Plug into OrganizeTrialInfoCalculiaProduction
%OrganizeTrialInfoNumberConcatActive
%OrganizeTrialInfoCalculiaEBS
% %% Segment audio from mic
% % adapt: segment_audio_mic
% switch project_name
%     case 'Calculia_EBS'
%     case 'Calculia_production'
%         load(sprintf('%s/%s_%s_slist.mat',globalVar.psych_dir,sbj_name,bn))
%         K.slist = slist;
% end
% %%%%%%%%%%%%%%%%%%%%%%%

%% Branch 3 - event identifier
EventIdentifier(sbj_name, project_name, block_names, dirs, 1) % old ones, photo = 2


%% Branch 4 - bad channel rejection
BadChanReject(sbj_name, project_name, block_names, dirs)
% 1. Continuous data
%      Step 0. epileptic channels based on clinical evaluation (manually inputed in the SaveDataNihonKohden)
%      Step 1. based on the raw power
%      Step 2. based on the spikes in the raw signal
%      Step 3. based on the power spectrum deviation
% Creates the first instance of data structure inside car() function
% Creat a diagnostic panel unifying all the figures

%% Branch 5 - Time-frequency analyses - AMY
parfor i = 1:length(block_names)
    WaveletFilterAll(sbj_name, project_name, block_names{i}, dirs, [], 'HFB', [], [], [], []) % only for HFB
%     WaveletFilterAll(sbj_name, project_name, block_names{i}, dirs, [], 'Spec', [], [], true, []) % across frequencies of interest
end

%% Branch 6 - Epoching, identification of bad epochs and baseline correction
blc_params.run = true; % or false
blc_params.locktype = 'stim';
blc_params.win = [-.2 0];

parfor i = 1:length(block_names)
    EpochDataAll(sbj_name, project_name, block_names{i}, dirs,[],'stim', [], 5, 'HFB', [],[], blc_params)
%     EpochDataAll(sbj_name, project_name, block_names{i}, dirs,[],'stim', [], 5, 'Spec', [],[], blc_params)
end

parfor i = 1:length(block_names)
    EpochDataAll(sbj_name, project_name, block_names{i}, dirs,[],'resp', -5, 1, 'HFB', [],[], blc_params)
    EpochDataAll(sbj_name, project_name, block_names{i}, dirs,[],'resp', -5, 1, 'Spec', [],[], blc_params)
end
% Bad epochs identification
%      Step 1. based on the raw signal
%      Step 2. based on the spikes in the raw signal
%      Step 3. based on the spikes in the HFB signal


%% DONE PREPROCESSING. 
% Eventually replace globalVar to update dirs in case of working from an
% with an external hard drive
%UpdateGlobalVarDirs(sbj_name, project_name, block_name, dirs)

%% Branch 7 - plotting OY AND YO
x_lim = [-.2 .7];

PlotTrialAvgAll(sbj_name,project_name,block_names,dirs,[],'HFB','stim','conds_addsub',[],[],'trials',[],x_lim)
PlotTrialAvgAll(sbj_name,project_name,block_names,dirs,[],'HFB','resp','conds_addsub',[],[],'none',[],x_lim)
PlotTrialAvgAll(sbj_name,project_name,block_names,dirs,[],'HFB','stim','conds_math_memory',[],[],'trials',[],x_lim)

col = [cdcol.carmine;
    cdcol.ultramarine;
    cdcol.grassgreen;
    cdcol.lilac;
    cdcol.yellow;
    cdcol.turquoiseblue];

PlotTrialAvgAll(sbj_name,project_name,block_names,dirs,[],'HFB','stim','conds_math_memory',[],col,'trials',[],x_lim)

% Allow conds to be any kind of class, logical, str, cell, double, etc.
% Input baseline correction flag to have the option.
% Include the lines option

PlotERSPAll(sbj_name,project_name,block_names,dirs,[],'stim','conds_math_memory',[],'trials',[])
% cbrewer 2. FIX


%% Branch 8 - integrate brain and electrodes location MNI and native and other info
% Lin's help
% Save to globalVar

% demographics
% date of implantation
% birth data
% age
% gender
% handedness
% IQ full
% IQ verbal
% ressection?


%% Medium-long term projects
% 1. Creat subfunctions of the EventIdentifier specific to each project


% 2. Stimuli identity to TTL


%% Behavioral analysis
% Load behavioral data
load()

datatype = 'HFB'
plot_params.blc = true
locktype = 'stim'
data_all.trialinfo = [];
for i = 1:length(block_names)
    bn = block_names {i};
    dir_in = [dirs.data_root,'/','HFB','Data/',sbj_name,'/',bn,'/EpochData/'];
    
    if plot_params.blc
        load(sprintf('%s/%siEEG_%slock_bl_corr_%s_%.2d.mat',dir_in,datatype,locktype,bn,1));
    else
        load(sprintf('%s/%siEEG_%slock_%s_%.2d.mat',dir_in,datatype,locktype,bn,1));
    end
    % concatenate trial info
    data_all.trialinfo = [data_all.trialinfo; data.trialinfo]; 
end

data_calc = data_all.trialinfo(data_all.trialinfo.isCalc == 1,:)
acc = sum(data_calc.Accuracy)/length(data_calc.Accuracy);
mean_rt = mean(data_calc.RT(data_calc.Accuracy == 1));
sd_rt = std(data_calc.RT(data_calc.Accuracy == 1));

boxplot(data_calc.RT(data_calc.Accuracy == 1), data_calc.CorrectResult(data_calc.Accuracy == 1))




