function [PARAMS] = planewave_tx_rx(PARAMS)
% function [PARAMS] = planewave_tx_rx(PARAMS)
%
% INPUTS: 
%         PARAMS (struct) - Tx/Rx parameters
%
% OUTPUTS: 
%         PARAMS (struct) - Tx/Rx parmeters w/ updated fields
%
%% ---------- AUTOMATICALLY CALCULATED PARAMETERS -------------------
%  ----------------- Planewave TX ---------------------------
% Automatically generate planewave Tx and Rx beams structures.
% For 1D probe planewave, only tilting within z-x plane.

PARAMS.BEAM_ANGLE_X = PARAMS.TX_FOCUS_ANGLE;
PARAMS.BEAM_ANGLE_Y = 0;

PARAMS.BEAM_ORIGIN_X = zeros(1, size(PARAMS.TX_FOCUS_ANGLE, 2));
PARAMS.BEAM_ORIGIN_Y = 0;


PARAMS.BEAM_ANGLE_X = deg2rad(PARAMS.BEAM_ANGLE_X);
PARAMS.BEAM_ANGLE_Y = deg2rad(PARAMS.BEAM_ANGLE_Y);


PARAMS.NO_BEAMS_X = length(PARAMS.BEAM_ANGLE_X);
PARAMS.NO_BEAMS_Y = 1;


%  ----------------- Planewave RX ---------------------------
% Receiving each line.

PARALLEL_X_OFFSET0 = PARAMS.XMIN:PARAMS.XSTEP:PARAMS.XMAX;
PARALLEL_Y_OFFSET0 = 0;
% PARALLEL_TH_OFFSET0 = 0;
% PARALLEL_PHI_OFFSET0 = 0;

[PARALLEL_X_OFFSET, PARALLEL_Y_OFFSET] = meshgrid(PARALLEL_X_OFFSET0,PARALLEL_Y_OFFSET0);
PARALLEL_TH_OFFSET = zeros(size(PARALLEL_X_OFFSET)); 
PARALLEL_PHI_OFFSET = zeros(size(PARALLEL_Y_OFFSET)); 

PARAMS.RXOFFSET =  [PARALLEL_X_OFFSET(:) PARALLEL_Y_OFFSET(:) PARALLEL_TH_OFFSET(:) PARALLEL_PHI_OFFSET(:)];
