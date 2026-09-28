%% DSP Project 01 - Toilet vs Long Corridor
% Room impulse response comparison and convolution reverb
% Final organized version
%
% Required input files in Current Folder:
%   tolite.m4a
%   zoulang.m4a
%   Speech - All Around 1.wav
%
% Main outputs:
%   dry.wav
%   toilet_rir.wav
%   corridor_rir.wav
%   toilet_reverb.wav
%   corridor_reverb.wav

clear;
clc;
close all;

%% 1. Read the two room recordings
[toilet, fsT] = audioread("tolite.m4a");
[corridor, fsC] = audioread("zoulang.m4a");

if size(toilet,2) > 1
    toilet = mean(toilet,2);
end
if size(corridor,2) > 1
    corridor = mean(corridor,2);
end

fprintf("Toilet recording: %.2f s, %d Hz\n", length(toilet)/fsT, fsT);
fprintf("Corridor recording: %.2f s, %d Hz\n", length(corridor)/fsC, fsC);

%% 2. Extract approximate room impulse responses
t_start_T = 12.44;
t_end_T   = 13.15;
t_start_C = 13.99;
t_end_C   = 14.65;

idx_start_T = round(t_start_T*fsT) + 1;
idx_end_T   = min(round(t_end_T*fsT) + 1, length(toilet));
idx_start_C = round(t_start_C*fsC) + 1;
idx_end_C   = min(round(t_end_C*fsC) + 1, length(corridor));

h_toilet = toilet(idx_start_T:idx_end_T);
h_corridor = corridor(idx_start_C:idx_end_C);

h_toilet = h_toilet - mean(h_toilet);
h_corridor = h_corridor - mean(h_corridor);
h_toilet = h_toilet / max(abs(h_toilet));
h_corridor = h_corridor / max(abs(h_corridor));

audiowrite("toilet_rir.wav", h_toilet, fsT);
audiowrite("corridor_rir.wav", h_corridor, fsC);

%% 3. Plot the measured RIRs
timeT = (0:length(h_toilet)-1)'/fsT;
timeC = (0:length(h_corridor)-1)'/fsC;

figure("Name","RIR comparison");
subplot(2,1,1);
plot(timeT,h_toilet); grid on;
xlabel("Time / s"); ylabel("Normalized amplitude");
title("Toilet room impulse response h_T[n]");
xlim([0 length(h_toilet)/fsT]);

subplot(2,1,2);
plot(timeC,h_corridor); grid on;
xlabel("Time / s"); ylabel("Normalized amplitude");
title("Long-corridor room impulse response h_C[n]");
xlim([0 length(h_corridor)/fsC]);

%% 4. Read and extract the clean speech
[original, fsDry] = audioread("Speech - All Around 1.wav");
if size(original,2) > 1
    original = mean(original,2);
end

dry_start = 103.15;
dry_end   = 105.40;
idxDry1 = round(dry_start*fsDry) + 1;
idxDry2 = min(round(dry_end*fsDry) + 1, length(original));

dry = original(idxDry1:idxDry2);
dry = dry - mean(dry);

peakDry = max(abs(dry));
if peakDry == 0
    error("The selected dry-speech interval is silent.");
end
dry = 0.9 * dry/peakDry;
audiowrite("dry.wav", dry, fsDry);

fprintf("Dry speech: %.3f s, peak %.3f, RMS %.3f\n", ...
    length(dry)/fsDry, max(abs(dry)), rms(dry));

%% 5. Convolution reverb
if fsDry ~= fsT || fsDry ~= fsC
    error("Sampling rates are not equal. Resampling is required.");
end

reverb_toilet = conv(dry, h_toilet);
reverb_corridor = conv(dry, h_corridor);

reverb_toilet = 0.9 * reverb_toilet/max(abs(reverb_toilet));
reverb_corridor = 0.9 * reverb_corridor/max(abs(reverb_corridor));

audiowrite("toilet_reverb.wav", reverb_toilet, fsDry);
audiowrite("corridor_reverb.wav", reverb_corridor, fsDry);
fprintf("Convolution completed.\n");

%% 6. Spectrogram comparison
windowLength = 1024;
overlapLength = 768;
nfft = 2048;

figure("Name","Spectrogram comparison");
subplot(3,1,1);
spectrogram(dry,hann(windowLength),overlapLength,nfft,fsDry,"yaxis");
title("Dry Speech"); ylim([0 8]); clim([-120 -30]); colorbar;

subplot(3,1,2);
spectrogram(reverb_toilet,hann(windowLength),overlapLength,nfft,fsDry,"yaxis");
title("Toilet Reverb"); ylim([0 8]); clim([-120 -30]); colorbar;

subplot(3,1,3);
spectrogram(reverb_corridor,hann(windowLength),overlapLength,nfft,fsDry,"yaxis");
title("Corridor Reverb"); ylim([0 8]); clim([-120 -30]); colorbar;
sgtitle("Time-frequency comparison of dry speech and room reverberation");

%% 7. Smoothed normalized spectrum comparison
welchWindow = hann(4096);
welchOverlap = 3072;
welchNFFT = 8192;

[Pdry,f] = pwelch(dry,welchWindow,welchOverlap,welchNFFT,fsDry);
[Ptoilet,~] = pwelch(reverb_toilet,welchWindow,welchOverlap,welchNFFT,fsDry);
[Pcorridor,~] = pwelch(reverb_corridor,welchWindow,welchOverlap,welchNFFT,fsDry);

Pdry_dB = 10*log10(Pdry/max(Pdry) + eps);
Ptoilet_dB = 10*log10(Ptoilet/max(Ptoilet) + eps);
Pcorridor_dB = 10*log10(Pcorridor/max(Pcorridor) + eps);

figure("Name","Spectrum comparison");
plot(f/1000,Pdry_dB,"LineWidth",1.2); hold on;
plot(f/1000,Ptoilet_dB,"LineWidth",1.2);
plot(f/1000,Pcorridor_dB,"LineWidth",1.2); hold off;
grid on;
xlabel("Frequency / kHz"); ylabel("Normalized PSD / dB");
title("Normalized spectral comparison");
legend("Dry Speech","Toilet Reverb","Corridor Reverb","Location","best");
xlim([0 8]); ylim([-80 5]);

%% 8. Schroeder EDC and T20-based RT60 estimate
EDC_T = flipud(cumsum(flipud(h_toilet.^2)));
EDC_C = flipud(cumsum(flipud(h_corridor.^2)));

EDC_T_dB = 10*log10(EDC_T/max(EDC_T) + eps);
EDC_C_dB = 10*log10(EDC_C/max(EDC_C) + eps);

maskT = EDC_T_dB <= -5 & EDC_T_dB >= -25;
maskC = EDC_C_dB <= -5 & EDC_C_dB >= -25;

if nnz(maskT) < 2 || nnz(maskC) < 2
    error("Not enough samples in the -5 to -25 dB fitting interval.");
end

pT = polyfit(timeT(maskT),EDC_T_dB(maskT),1);
pC = polyfit(timeC(maskC),EDC_C_dB(maskC),1);

RT60_T = -60/pT(1);
RT60_C = -60/pC(1);

fprintf("\n===== T20-based RT60 estimate =====\n");
fprintf("Toilet RT60 ~= %.3f s\n",RT60_T);
fprintf("Long corridor RT60 ~= %.3f s\n",RT60_C);

figure("Name","Schroeder EDC");
plot(timeT,EDC_T_dB,"LineWidth",1.5); hold on;
plot(timeC,EDC_C_dB,"LineWidth",1.5);
yline(-5,"--"); yline(-25,"--"); hold off;
grid on;
xlabel("Time / s"); ylabel("Energy decay / dB");
title("Schroeder energy decay curves");
legend("Toilet","Corridor","-5 dB","-25 dB","Location","best");
ylim([-60 5]);

%% 9. Optional listening
% soundsc(dry,fsDry);
% soundsc(reverb_toilet,fsDry);
% soundsc(reverb_corridor,fsDry);
