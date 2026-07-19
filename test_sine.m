% Independent validation on a synthetic signal.
%
% Comparing against resample() proves the implementation matches MATLAB,
% but both use the same filter design, so it does not prove the design
% itself is correct. This test is independent: a pure sine at f0 must
% come out of the resampler as the same sine, with the same amplitude
% and phase, on the new time grid. Any error in the cutoff, the gain
% normalization, or the delay compensation would show up here directly.
clearvars;
close all;

fs = 8000;      % input sample rate
f0 = 1000;      % test tone, well inside the passband
dur = 1;        % seconds
L = 5;
M = 3;

t = (0 : 1/fs : dur - 1/fs)';
x = sin(2*pi*f0*t);

y = polyphase_resample(x, L, M);

% The ideal result: the same sine evaluated on the output time grid.
% Since the resampler output is delay free, output sample m corresponds
% to time (m-1)/fs_out exactly.
fs_out = fs * L / M;
m = (0 : length(y) - 1)';
y_ideal = sin(2*pi*f0*m/fs_out);

% SNR over the core of the signal, excluding edge transients
edge = 500;
core = (1 + edge) : (length(y) - edge);
err = y(core) - y_ideal(core);
snr_db = 10 * log10(sum(y_ideal(core).^2) / sum(err.^2));
fprintf('Sine test, %d Hz, L/M = %d/%d: SNR vs ideal = %.2f dB\n', ...
        f0, L, M, snr_db);

% Same test on MATLAB's built-in resample(): its default filter is the
% same Kaiser design, so it should land on the same SNR. This shows the
% residual error is the cost of the chosen window, not of either
% implementation.
y_bi = resample(x, L, M);
err_bi = y_bi(core) - y_ideal(core);
snr_bi = 10 * log10(sum(y_ideal(core).^2) / sum(err_bi.^2));
fprintf('Built-in resample, same test:      SNR vs ideal = %.2f dB\n', ...
        snr_bi);

% Plots
figure;

subplot(2, 1, 1);
seg = 1000:1100;
plot(seg, y_ideal(seg), 'b', seg, y(seg), 'r--');
legend('Ideal sine on output grid', 'Polyphase resampler output');
title(sprintf('Sine test overlay, f0 = %d Hz, L/M = %d/%d', f0, L, M));
xlabel('Sample Index'); ylabel('Amplitude');

subplot(2, 1, 2);
plot(seg, err(seg - edge), 'r', seg, err_bi(seg - edge), 'b--');
legend(sprintf('Custom polyphase (SNR = %.1f dB)', snr_db), ...
       sprintf('Built-in resample (SNR = %.1f dB)', snr_bi));
title('Error vs ideal sine (zoom, same segment as above)');
xlabel('Sample Index'); ylabel('Error');
