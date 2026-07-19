function y = polyphase_resample(x, L, M)
%POLYPHASE_RESAMPLE Rational sample rate conversion by a factor L/M.
%
%   y = POLYPHASE_RESAMPLE(x, L, M) resamples the signal x by the rational
%   factor L/M (upsampling by L, downsampling by M) using an efficient
%   polyphase FIR structure. The output is delay free: the FIR group delay
%   is compensated exactly inside the polyphase index arithmetic.
%
%   Inputs:
%       x - input signal (vector)
%       L - upsampling factor (positive integer)
%       M - downsampling factor (positive integer)
%
%   Output:
%       y - resampled signal, length floor(length(x)*L/M), at rate fs*L/M
%
%   The anti-imaging / anti-aliasing lowpass FIR is designed with a Kaiser
%   window (beta = 5, order 20*max(L,M)) and cutoff min(1/L, 1/M), the
%   same design used by MATLAB's resample() defaults.

x = x(:);

% Reduce L/M to lowest terms
g = gcd(L, M);
L = L / g;
M = M / g;

% Ratio of 1: no resampling and no filtering needed
if L == 1 && M == 1
    y = x;
    return;
end

% Lowpass FIR design (even order, so the group delay D = filterOrder/2
% is an integer at the upsampled rate)
filterOrder = 20 * max(L, M);
cutoffFreq = min(1/M, 1/L);
h = fir1(filterOrder, cutoffFreq, 'low', kaiser(filterOrder + 1, 5));

% Pad the filter length to a multiple of L
N = length(h);
padding = mod(L - mod(N, L), L);
if padding > 0
    h = [h, zeros(1, padding)];
end

% Gain L compensates the energy loss of upsampling
h = L * h / sum(h);

% Polyphase decomposition: L branches, Q taps each
H_polyphase = reshape(h, L, []);
Q = size(H_polyphase, 2);

% Group delay at the upsampled rate, folded into the index arithmetic
% below: the filtered signal is sampled at v[nM + D] instead of v[nM],
% so the output is aligned by construction for any L and M
D = filterOrder / 2;

Ny = floor(length(x) * L / M);
y = zeros(Ny, 1);

% Pad the input once: Q-1 zeros at the start (causal history), zeros at
% the end so edge windows (including the D-sample look-ahead) never
% index past the signal
xp = [zeros(Q - 1, 1); x; zeros(Q * M + Q, 1)];

% Single loop over the L polyphase branches. Output samples
% n0, n0+L, n0+2L, ... share the same filter row, and their input
% window advances by exactly M samples each step, so each branch is
% computed at once with one matrix-vector product.
for n0 = 1:L
    m0 = (n0 - 1) * M + D;         % high-rate index, delay compensated
    p  = mod(m0, L) + 1;           % polyphase branch (filter row)
    b  = floor(m0 / L) + 1;        % input base of the first sample

    idx = (n0:L:Ny)';              % output samples of this branch
    k = (0:numel(idx) - 1)';

    rows = b + k * M + (Q - 1);    % top index of each input window
    IDX  = rows - (0:Q - 1);       % matrix: each row = one window

    y(idx) = xp(IDX) * H_polyphase(p, :).';
end

end
