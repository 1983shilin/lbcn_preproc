function WaveletFilterAll(sbj_name, project_name, bn, dirs,el,freq_band,span,fs_targ, norm, avgfreq)
%% INPUTS
%   sbj_name: subject name
%   project_name: name of task
%   bn: names of blocks to be analyed (cell of strings)
%   dirs: directories pointing to files of interest (generated by InitializeDirs)
%   el (optional): can select subset of electrodes to epoch (default: all)
%   freq_band (optional): vector containing frequencies at which wavelet is computed (in Hz), 
%                            or string (e.g. 'HFB') corresponding to
%                            particular set of freqs (returned by genFreqs.m)
%   span (optional): span of wavelet (i.e. width of gaussian that forms
%                  wavelet, in units of cycles- specific to each
%                  frequency)
%   fs_targ (optional): target sampling rate of wavelet output
%   norm (optional): normalize amplitude of timecourse within each frequency
%                  band (to eliminate 1/f power drop with frequency)
%   avgfreq (optional): average across frequency dimension to yield single timecourse
%                     (e.g. for computing HFB timecourse). If set to true,
%                     only amplitude information will remain (not phase, since
%                     cannot average phase across frequencies)
if isempty(avgfreq)
    if strcmp(freq_band,'HFB')
        avgfreq = true;
    else
        avgfreq = false;
    end
end

if ~ischar(freq_band)
    freqs = freq_band;
else
    freqs = genFreqs(freq_band);
end

if isempty(span)
    span = 1;
end
if isempty(norm)
    norm = true;
end
%%
% Load globalVar
fn = sprintf('%s/originalData/%s/global_%s_%s_%s.mat',dirs.data_root,sbj_name,project_name,sbj_name,bn);
load(fn,'globalVar');

if strcmp(freq_band,'HFB')
    dir_out = globalVar.HFBData;
else
    dir_out = globalVar.SpecData;
end


if isempty(fs_targ)
    if avgfreq
        fs_targ = 500;
    else
        fs_targ = 200;
    end
end

%% Per electrode
load(sprintf('%s/CARiEEG%s_%.2d.mat',globalVar.CARData,bn,el));

data = WaveletFilter(data.wave,data.fsample,fs_targ,freqs,span,norm,avgfreq);
data.label = globalVar.channame{el};
if strcmp(freq_band,'HFB')
    fn_out = sprintf('%s/HFBiEEG%s_%.2d.mat',dir_out,bn,el);
else
    fn_out = sprintf('%s/SpeciEEG%s_%.2d.mat',dir_out,bn,el);
end
save(fn_out,'data')
disp(['Wavelet filtering: Block ', bn,', Elec ',num2str(el)])


end