% Benchmark: this project's polyphase resampler vs MATLAB's built-in
% resample(), on the same signal and the same filter design, across
% several L/M ratios. Reports median runtimes and their ratio.
clearvars;
close all;

fs = 8000;
x = randn(fs * 30, 1);      % 30 seconds of white noise
ratios = [5 3; 3 5; 2 1; 1 2; 7 4; 160 147];   % last one: 44.1k -> 48k
nRuns = 7;                  % median of several runs

fprintf('\n%-12s %14s %14s %10s\n', 'L/M', 'Custom [ms]', 'resample [ms]', 'Ratio');

for i = 1:size(ratios, 1)
    L = ratios(i, 1);
    M = ratios(i, 2);

    tc = zeros(nRuns, 1);
    tb = zeros(nRuns, 1);
    for r = 1:nRuns
        tic; y_custom = polyphase_resample(x, L, M); tc(r) = toc;
        tic; y_builtin = resample(x, L, M);          tb(r) = toc;
    end

    tcm = median(tc) * 1000;
    tbm = median(tb) * 1000;
    fprintf('%3d/%-8d %14.1f %14.1f %9.1fx\n', L, M, tcm, tbm, tcm / tbm);

    % Sanity: outputs must agree to machine precision
    len = min(length(y_custom), length(y_builtin));
    assert(max(abs(y_custom(1:len) - y_builtin(1:len))) < 1e-10, ...
           'Outputs diverged for L/M = %d/%d', L, M);
end

fprintf(['\nresample() calls compiled C code (upfirdn), so a single-digit\n' ...
         'ratio is the expected cost of staying in pure MATLAB. In absolute\n' ...
         'terms both are far faster than real time: %.0f s of audio in %.0f ms\n' ...
         'is about %dx real-time for the custom implementation.\n'], ...
        length(x) / fs, median(tc) * 1000, round(length(x) / fs / median(tc)));
