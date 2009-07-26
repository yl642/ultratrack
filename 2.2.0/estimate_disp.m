function [D,C]=estimate_disp(rfdata,TRACKPARAMS)
% function [D,C]=estimate_disp(rfdata,TRACKPARAMS)
% 
% SUMMARY: Estimate displacement from the tracking simulations using a variety
% of tracking algorithms.
%
% INPUTS:
%   rfdata (float) - matrix of RF data [axial x lat x t]
%   TRACKPARAMS (struct):
%       TRACK_ALG (string) - tracking algorithm 
%           'samtrack' - Steve McAleavey's cross correlator
%           'samauto' - Steve McAleavey's Kasai algorithm (auto correlator)
%           'ncorr' - Gianmarco's cross correlator
%           'loupas' - Gianmarco's Loupas algorithm (auto correlator)
%       KERNEL_SAMPLES (int) - size of the tracking kernel
%
% OUTPUTS:
%   D (float) - displacement estimates (um)
%   C (float) - normalized correlation coefficients

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODIFICATION HISTORY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Originally written
% Mark 03/31/08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2009-07-09 (mlp6)
% Reduce the parameter inputs to a single TRACKPARAMS struct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% extract variables from the input TRACKPARAMS struct
alg = TRACKPARAMS.TRACK_ALG;
kernelsize = TRACKPARAMS.KERNEL_SAMPLES;

switch alg
    case 'samtrack',
        disp('Displacement tracking algorithm: samtrack');
        for n=1:size(rfdata,2)
        % MODIFIED THE CODE TO HAVE A VARIABLE KERNEL SIZE AS A FUNCTION OF
        % FREQUENCY TO MAINTAIN A CONSTANT 2.5 CYCLES / KERNEL
        % MARK 01/24/05
        %[D(:,:,n),C(:,:,n)]=sam_track(squeeze(bigRF(:,n,:)),35,-5,5);
                    %
                    % Allow for variable kernel sizes
                    %
        %[D(:,:,n),C(:,:,n)]=sam_track(squeeze(bigRF(:,n,:)),35*7/Freq,-5,5);
        [D(:,:,n),C(:,:,n)]=sam_track(squeeze(rfdata(:,n,:)),kernelsize,-5,5);
        end;

    case 'samauto',
        error('samauto tracking has not been integrated yet');
    case 'ncorr',
        error('ncorr tracking has not been integrated yet');
    case 'loupas',
        error('loupas tracking has not been integrated yet');
    otherwise,
        error(sprintf('%s cannot be found as a tracking algorithm',TRACKPARAMS.TRACK));
end;
