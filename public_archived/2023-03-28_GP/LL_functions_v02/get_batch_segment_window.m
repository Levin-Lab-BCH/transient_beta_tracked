function [seg_win,t,Fs] = get_batch_segment_window(batch_folder,beapp_tag, ...
                                                   default_srate)
% GET_BATCH_SEGMENT_WINDOWS fetches segmentation windos from BEAPP
% grp_proc_info and returns double: [evt_seg_win_start evt_seg_win_end]
%   Inputs:
%       - batch_folder - path to folder containing BEAPP batch
%       - beapp_tag    - BEAPP tag of batch to load segmentation window for
%   Returns:
%       - seg_win - double containing segment start and end times in sec
%       - t       - double with mapping of samples to times
%%
if ~exist('default_srate','var'), default_srate = 1000; end
gpi_fname = ['Run_Report_Variables_and_Settings' beapp_tag '.mat'];
gpi_path  = fullfile(batch_folder,['out' beapp_tag],gpi_fname);
load(gpi_path,'grp_proc_info'); gpi = grp_proc_info;
% get segmentation window
if ~gpi.beapp_toggle_mods{'format','Module_On'}
    gpi.src_format_typ = 1;
    warning(['format module not used for this batch (potentially ' ...
            'imported from HAPPE V3). assuming baseline data type'])
end
if gpi.src_format_typ == 1
    seg_win = [0 gpi.win_size_in_secs];
else
    seg_win = [gpi.evt_seg_win_start gpi.evt_seg_win_end];
end
% get mapping of samples to times
if gpi.beapp_toggle_mods{'rsamp','Module_On'}
    Fs = gpi.beapp_rsamp_srate;
else
    Fs = default_srate;
end
n_samp = round(sum(abs(seg_win)) * Fs);
t = linspace(seg_win(1),seg_win(2),n_samp);
end