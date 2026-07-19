% Demo: resample a speech recording by L/M and validate against MATLAB's
% built-in resample(). Run from the project folder.
clearvars;
close all;

% Load the audio signal
[x, fs] = audioread('speech_8khz.wav');

% Resampling ratio L/M
L = 5;
M = 3;

y = polyphase_resample(x, L, M);

% Play the result
disp('Playing custom polyphase resampled signal:');
sound(y, fs * L / M);
pause(2);

%% ------------------- Validation against resample() -------------------
% Both outputs are delay free (resample compensates internally, our
% implementation compensates via the polyphase index shift), so they can
% be compared sample by sample directly.
y_builtin = resample(x, L, M);

% Trim both signals to a common length
len = min(length(y), length(y_builtin));
ya = y(1:len);
yb = y_builtin(1:len);

% Error and SNR, excluding the edge transients of both filters
edge = ceil(20 * max(L, M) / M);
core = (1 + edge) : (len - edge);
err  = ya - yb;
snr_db = 10 * log10(sum(yb(core).^2) / sum(err(core).^2));
fprintf('SNR of custom implementation vs resample(): %.2f dB\n', snr_db);

% Plots
figure;

% Overlay of a short segment: full-signal plots hide all differences,
% so zoom into a few hundred samples in the middle of the signal
seg = round(len/2) : round(len/2) + 300;
subplot(2, 1, 1);
plot(seg, yb(seg), 'b', seg, ya(seg), 'r--');
legend('Built-in resample', 'Custom polyphase');
title(sprintf('Overlay (zoom), L/M = %d/%d', L, M));
xlabel('Sample Index'); ylabel('Amplitude');

% Error signal
subplot(2, 1, 2);
plot(err);
title(sprintf('Error (SNR = %.1f dB)', snr_db));
xlabel('Sample Index'); ylabel('Error');
