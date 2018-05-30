function [LL,UU,Pp,Qp,Rr,dH] = LUFactc(m,Q,model)
% Frequency domain FD modeling operator
%
% use:
%   D = F(m,Q,model)
% input:
%   m                 - vector with gridded squared slowness in [km^2/s^2]
%   Q                 - source matrix. size(Q,1) must match source grid
%                       definition, size(Q,2) determines the number of
%                       sources, if size(Q,3)>1, it represents a
%                       frequency-dependent source and has to be
%                       distributed over the last dimension.
%   model.{o,d,n}     - physical grid: z = ox(1) + [0:nx(1)-1]*dx(1), etc.
%   model.nb          - number of points to add for absorbing boundary
%   model.freq        - frequencies
%   model.f0          - peak frequency of Ricker wavelet, 0 for no wavelet.
%   model.t0          - phase shift [s] of wavelet.
%   model.{zsrc,xsrc} - vectors describing source array
%   model.{zrec,xrec} - vectors describing receiver array.
%
% output:
%   D  - Data cube (nrec x nsrc x nfreq) as (distributed) vector. nsrc  = size(Q,2);
%                                                                 nrec  = length(zrec)*length(xrec)
%                                                                 nfreq = length(freq)
% comp. grid
dt = model.d;
nt = model.n+2*model.nb(1,:);
nfreq  = length(model.freq);

% define wavelet
w = exp(1i*2*pi*model.freq*model.t0);
if model.f0
    % Ricker wavelet with peak-frequency model.f0
    w = (model.freq).^2.*exp(-(model.freq/model.f0).^2).*w;
end

% mapping from source/receiver/physical grid to comp. grid
Px = opKron(opExtension(model.n(2),model.nb(1,2)),opExtension(model.n(1),model.nb(1,1)));
% model parameter: slowness [s/m] on computational grid.
mu = Px*m;

% distribute frequencies according to standard distribution
freq = distributed(model.freq);
spmd
    freqloc  = getLocalPart(freq);
    nfreqloc = length(freqloc);
    LL    = cell(nfreqloc,1);
    UU    = cell(nfreqloc,1);
    Pp    = cell(nfreqloc,1);
    Qp    = cell(nfreqloc,1);
    Rr    = cell(nfreqloc,1);
    dH    = cell(nfreqloc,1);
    for k = 1:nfreqloc
       [Hk, dH{k}]        = Helm2D_opt(mu,dt,nt,model.nb,model.unit,freqloc(k),model.f0);
       [LL{k},UU{k},Pp{k},Qp{k},Rr{k}] = lu(Hk);
    end
end