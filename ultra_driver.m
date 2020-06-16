function ultra_driver(phantom_seed, nodes, dispdat)
% function ultra_driver(phantom_seed, nodes, dispdat)
% INPUTS:
%   phantom_seed (int) - scatterer position RNG seed
%   nodes (string) - location of nodes.dyn (comma-delimited); must be absolute
%                    or explicitely relative
%   dispdat (string) - location of disp.dat (where phantom* results will be
%                      saved); must be absolute or explicitely relative
%
% OUTPUTS:
%   Nothing returned, but lots of files and directories created in the parent
%   directory of disp.
%
% EXAMPLE: driver(0, './nodes.dyn', './disp.dat')
%

% ------------------PHANTOM PARAMETERS----------------------------
% setup phantom parameters (PPARAMS)

generatephantom = false;
PPARAMS.sym = 'h';                      % 'q', 'h', 'none'  % for FEM data
PPARAMS.xmin=[-0.5];PPARAMS.xmax=[0.5];	% out-of-plane,cm
PPARAMS.ymin=[-1.0];PPARAMS.ymax=[1.0];	% lateral, cm \
PPARAMS.zmin=[-3.0];PPARAMS.zmax=[-2.0];% axial, cm   / X,Y SWAPPED vs FIELD!
% Timesteps to simulation (leave empty for all FEM timesteps)
PPARAMS.TIMESTEP=[];

% compute number of scatteres to use
% SCATTERER_DENSITY = 20000;            % scatterers/cm^3
SCATTERER_DENSITY = 100;                % scatterers/cm^3
PPARAMS.N = calc_n_scats(SCATTERER_DENSITY, PPARAMS);
PPARAMS.seed=phantom_seed;              % RNG seed

% amplitude of the randomly-distributed scatterers 
% set to 0 if you just want the point scatterers defined below
% set NaN for uniform amplitude 1 scatterers
% PPARAMS.rand_scat_amp = 1;
PPARAMS.rand_scat_amp = NaN;

% optional point-scatterer locations
USE_POINT_SCATTERERS = false;
if USE_POINT_SCATTERERS  % wire scatters, still needs to be reflected
    % x, y, z locations and amplitudes of point scatteres (FIELD II coords)
    PPARAMS.pointscatterers.x = 1e-3 * (-2:1:2); 
    PPARAMS.pointscatterers.z = 1e-3 * (5:1:25); 
    PPARAMS.pointscatterers.y = 1e-3 * (-3:1:0); 
    PPARAMS.pointscatterers.a = 1;
end

% rigid pre-zdisp-displacement scatterer translation, in the dyna
% coordinate/unit system to simulate ARFI sequences with multiple runs
PPARAMS.delta=[0 0 0];

%% MAP DYNA DISPLACEMENTS TO SCATTERER FIELD & GENERATE PHANTOMS 
PHANTOM_DIR=[make_file_name('phantom', [fileparts(dispdat) '/phantom'], PPARAMS) '/'];
PHANTOM_FILE=[PHANTOM_DIR 'phantom'];
d = dir([PHANTOM_FILE '*.mat']);
if isempty(d) || generatephantom
    mkdir(PHANTOM_DIR);
    mkphantomfromdyna3(nodes, dispdat, PHANTOM_FILE, PPARAMS);
end

%  --------------IMAGING PARAMETERS---------------------------------
PARAMS.PROBE ='l7-4';
PARAMS.COMPUTATIONMETHOD = 'none';  % 'cluster','parfor', or 'none'

% setup some Field II parameters
PARAMS.field_sample_freq = 1e9;     % Hz
PARAMS.c = 1540;                    % sound speed (m/s)

% TRACKING BEAM PARAMETERS
% tx
PARAMS.TX_FOCUS_ANGLE = [-3 0 3];   % 1D probe, plane wave imaging (deg)
PARAMS.TX_FOCUS_R = NaN;            % Tramsmit focus depth. if diverging or converging wave (m)
if ~isnan(PARAMS.TX_FOCUS_R)
    PARAMS.TX_FOCUS = [PARAMS.TX_FOCUS_R*sind(PARAMS.TX_FOCUS_ANGLE) 0 PARAMS.TX_FOCUS_R*cosd(PARAMS.TX_FOCUS_ANGLE)];
    
    % if matrix probe, 2D plane wave configuration
%     zfoc=PARAMS.TX_FOCUS_R./sqrt(1+tand(PARAMS.TX_FOCUS_ANGLE(1)).^2+tand(PARAMS.TX_FOCUS_ANGLE(2)).^2);
%     PARAMS.TX_FOCUS= [zfoc.*tand(PARAMS.TX_FOCUS_ANGLE(1)) zfoc.*tand(PARAMS.TX_FOCUS_ANGLE(2)) zfoc];
else
    PARAMS.TX_FOCUS = [0 0 0];
end

PARAMS.TX_F_NUM = 0;                % zero for full array
PARAMS.TX_FREQ = 5.2e6;             % Transmit frequency (Hz)
PARAMS.TX_NUM_CYCLES = 2;           % Number of cycles in transmit toneburst
PARAMS.tx_apod_type = 0;            % 1 for Hamming apodization, 0 for rectangular

% rx
PARAMS.XMIN=    -19/1000;           % Leftmost scan line (m)
PARAMS.XSTEP =  1/1000;             % Azimuth step size (m);
PARAMS.XMAX=    19/1000;            % Rightmost scan line (m)

% curvilinear scan or volumic scan
PARAMS.THMIN =  0;              % Leftmost azimuth angle (deg)
PARAMS.THSTEP = 0;              % Azimuth angle step(deg)
PARAMS.THMAX =  0;              % Rightmost azimuth angle (deg)
PARAMS.PHIMIN= 0;               % Frontmost elevation angle (deg)
PARAMS.PHISTEP = 0;             % Elevation angle step(deg)
PARAMS.PHIMAX= 0;               % Backmost elevation angle (deg)
PARAMS.YMIN=   0;		        % Frontmost scan line (m)
PARAMS.YSTEP = 0;               % Elevation step size (m)
PARAMS.YMAX=   0;	            % Backmost scan line (m)
PARAMS.APEX = 0;                % Apex of scan geometry; 0 for linear scanning

PARAMS.RX_FOCUS = 0;            % Depth of receive focus - use 0 for dynamic Rx
PARAMS.RX_F_NUM = 1;            % Zero for full array
PARAMS.rx_apod_type = 1;        % 1 for Hamming apodization, 0 for rectangular
PARAMS.RX_GROW_APERTURE = 0;    % Not actually implemented!
PARAMS.MINDB = -20;             % Min dB to include a scat in reduction (NaN to disable)

PARAMS = planewave_tx_rx(PARAMS); % Tx & Rx beam override possible with 1s

%% ------------- GENERATE RF SCANS OF SCATTERER FIELDS -------------------
RF_DIR = [make_file_name('rf', [PHANTOM_DIR 'rf'], PARAMS) '/'];
RF_FILE = [RF_DIR 'rf'];
mkdir(RF_DIR);
field_init(-1);
do_dyna_scans_planewave(PHANTOM_FILE, RF_FILE, PARAMS);
field_end;
