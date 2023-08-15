function [X,t_classes] = beapp_to_spectral_events(data_path,beapp_tag,chans,time_win)
%% beapp_to_spectral_events: convert BEAPP segmented data to [time x trial]
%   matrices for each participant in given directory
% 
% Inputs:
%   data_path - path to task directory containing BEAPP outputs
%   beapp_tag - beapp processing tag
%   chans     - array of channel numbers to average for output data
%   time_win  - time window to use relative to stim onset (ms)
%
% Outputs:
%   X{a}         - matrix (of the a^th subject in cell array X) 
%                  representing the time-series trials of the given subject
%   t_classes{a} - numeric classification (of the a^th subject) of trials
%
%%
% get task segmentation window from batch beapp output file
load( [data_path filesep 'out' beapp_tag filesep                        ...
      'Run_Report_Variables_and_Settings' beapp_tag                     ...
      '.mat'], 'grp_proc_info' )
seg_win = [ grp_proc_info.evt_seg_win_start                        ...
            grp_proc_info.evt_seg_win_end ] * 1000;
srate = grp_proc_info.beapp_rsamp_srate;
clear grp_proc_info

% get indeces of time_win, relative to seg_win
time_win_idxs = get_time_win_idxs(time_win,seg_win,srate);
n_samps = length(time_win_idxs);  % get number of samples kept per trial

% get data directory struct
data_dir  = dir([data_path filesep 'segment' beapp_tag filesep '*.mat']);
if isempty(data_dir)
    data_dir = dir([data_path filesep 'HAPPE_V3' beapp_tag filesep '*.mat']);
end

% create empty output vars and iterate through files
n_files   = size(data_dir,1);
for a = 1:n_files
    file = data_dir(a);
    %KS addition to run different participant IDs 10/27/22
    id = strrep(file.name,'-','_');
    id = strrep(id,' ','_');
    id = erase(id,'.mat');
    %
    id   = ['s' id]; %alllows for a number only participant name to be used 
    load([file.folder filesep file.name],'eeg_w','file_proc_info')
    n_conds = size(eeg_w,1);
    if isempty(chans)
        chans = file_proc_info.net_10_20_elecs;
    end
    
    % get total number of trials to create empty matrices for all data
    n_trials = zeros(1,n_conds);
    for c = 1:n_conds
        n_trials(c) = size(eeg_w{c,1},3);  % get # trials in each cond
    end
    total_n_trials = sum(n_trials);  % sum trials in each cond for total
    X.(id) = zeros(n_samps,total_n_trials);
    t_classes.(id) = zeros(1,total_n_trials);
    n_trials = [1 n_trials];
    
    % add trials to new matrix by condition
    for c = 1:n_conds
        trl_idx_strt = sum(n_trials(1:c));
        trl_idx_end  = trl_idx_strt + n_trials(c+1) - 1;
        trl_idxs = trl_idx_strt:trl_idx_end; 
        if size(eeg_w{c,1},1) == 32
            chans = [8 23];
        end
        % average out channels across time_win, add trials to output matrix
        X.(id)(:,trl_idxs) = squeeze(nanmean(                        ...
                                    eeg_w{c,1}(chans,time_win_idxs,:),  ...
                                1));
        t_classes.(id)(trl_idxs) = c;
    end

    clear eeg_w file_proc_info
end

% get string of channels for filename
chan_str = get_chan_str({},chans);
if isempty(chan_str)
    chan_str = '1020';
end

save_path = [data_path filesep 'spec_events' filesep];
if ~exist(save_path,'dir')
    mkdir(save_path);
end
% save data
save([save_path 'SET_seg_' chan_str '_' get_time_win_str(time_win) beapp_tag '.mat'],'X','t_classes')

end
