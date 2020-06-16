function do_dyna_scans_planewave(PHANTOM_FILE,OUTPUT_FILE,PARAMS)
%
% do_dyna_scans_planewave(PHANTOM_FILE,OUTPUT_FILE,PARAMS)
%
% Function for doing ARFI scans with the URI/Field toolkit 
%
% 11/11/04 Stephen McAleavey, U. Rochester BME
%
%
% PHANTOM_FILE	Filename for phantom files - will look for 
% 		everything w/ %03d number appended, e.g.
% 		phantom001, phantom010, etc
%
% OUTPUT_FILE	Filename containing simulated RF.  Output 
%		will have same number appended as input
%
% PARAMS	structure with the following entries:
%
% PARAMS.PROBE              Name of text file containing probe description
% PARAMS.TX_FOCUS_ANGLE     Planewave tilting angles
% PARAMS.XMIN               Leftmost scan RX line
% PARAMS.XSTEP              RX scanline spacing
% PARAMS.XMAX               Rightmost scan RX line
% PARAMS.TX_FREQ            Transmit frequency
% PARAMS.TX_NUM_CYCLES		Number of cycles in transmit toneburst
% PARAMS.RX_FOCUS           Depth of receive focus - use zero for dyn. foc
% PARAMS.RX_FNUM            Receive aperture f number
% PARAMS.RX_GROW_APERTURE	1 means use aperture growth, 0 means don't
% PARAMS.RXOFFSET           Spatial offset for RX for plabewave receiving
%
% The uf_scan() call has been modified to allow for parallel rx
% simulations, by passing PARAMS.RXOFFSET to uf_scan() that
% is then passed to uf_set_beam() to laterally offset the Rx
% beam from the Tx beam.  This is also passed to uf_make_xdc().
% Mark 06/16/05
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This version is for planewave imaging, thus disabled parallel rx
% Yangpei 06/15/20
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ADD PATHS FOR CODE AND PROBES
add_paths;

% BEGIN PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debug_fig = 0;

PROBE_NAME = PARAMS.PROBE;
BEAM_ORIGIN_X = PARAMS.BEAM_ORIGIN_X;
BEAM_ORIGIN_Y = PARAMS.BEAM_ORIGIN_Y;
BEAM_ANGLE_X = PARAMS.BEAM_ANGLE_X;
BEAM_ANGLE_Y = PARAMS.BEAM_ANGLE_Y;
TX_FOCUS = PARAMS.TX_FOCUS;
TX_FNUM = PARAMS.TX_F_NUM;
TX_FREQ = PARAMS.TX_FREQ;
TX_NUM_CYCLES = PARAMS.TX_NUM_CYCLES;
RX_FOCUS = PARAMS.RX_FOCUS;
RX_FNUM = PARAMS.RX_F_NUM;
RX_GROW_APERTURE = PARAMS.RX_GROW_APERTURE;
RXOFFSET = PARAMS.RXOFFSET;
APEX = PARAMS.APEX;
MINDB = PARAMS.MINDB;
% END PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~strcmp(PROBE_NAME(end-3:end),'.txt')
    PROBE_NAME = [PROBE_NAME '.txt'];
end
% Create probe structure for specified probe
probe = uf_txt_to_probe(PROBE_NAME);
probe.field_sample_freq = PARAMS.field_sample_freq;
probe.c = PARAMS.c;

% Create beamset based on params above
beamset.type='B';
beamset.originx=BEAM_ORIGIN_X';
beamset.originy=BEAM_ORIGIN_Y';

beamset.directionx=BEAM_ANGLE_X';
beamset.directiony=BEAM_ANGLE_Y';

beamset.no_beams=max(length(beamset.originx),length(beamset.directionx));
beamset.no_beamsy=max(length(beamset.originy),length(beamset.directiony));

if length(beamset.originx)==1 && length(beamset.directionx)>1
    beamset.originx = repmat(beamset.originx,beamset.no_beams,1);
elseif length(beamset.originx)>1 && length(beamset.directionx)==1
    beamset.directionx = repmat(beamset.directionx,beamset.no_beams,1);
end
if length(beamset.originy)==1 && length(beamset.directiony)>1
    beamset.originy = repmat(beamset.originy,beamset.no_beamsy,1);
elseif length(beamset.originy)>1 && length(beamset.directiony)==1
    beamset.directiony = repmat(beamset.directiony,beamset.no_beamsy,1);
end

beamset.tx_focus_range=TX_FOCUS(3);
beamset.tx_f_num=TX_FNUM;
beamset.tx_excitation.f0=TX_FREQ;
beamset.tx_excitation.num_cycles=TX_NUM_CYCLES;
beamset.tx_excitation.phase=0;
beamset.tx_excitation.wavetype='Square';
beamset.prf=NaN;
beamset.tx_apod_type=PARAMS.tx_apod_type;   % 1 for Hamming apodization, 0 for rectangular
beamset.is_dyn_focus=(RX_FOCUS==0);       % If RX_FOCUS is spec'd zero, use dynamic focus
beamset.rx_focus_range=RX_FOCUS;            % Receive focal point, zero=dynamic
beamset.rx_apod_type=PARAMS.rx_apod_type;   % 1 for Hamming apodization, 0 for rectangular
beamset.rx_f_num=RX_FNUM;
beamset.aperture_growth=RX_GROW_APERTURE;
beamset.apex=APEX;
beamset.no_parallel=size(RXOFFSET,1);
beamset.rx_offset=RXOFFSET;
beamset.minDB = MINDB;

% Extract the pathname, if any, from PHANTOM_FILE
slashes=regexp(PHANTOM_FILE,'/'); % slashes has indicies of occurances of '/'
phantom_path=PHANTOM_FILE(1:max(slashes));

% Extract phantom name
if isempty(slashes)
    phantom_name=PHANTOM_FILE;
else
    phantom_name=PHANTOM_FILE((max(slashes+1):end));
end

%Generate list of all files matching PHANTOM_FILE prefix
phantom_files=dir([PHANTOM_FILE '*']);

% Abort with message if there are no files found
if isempty(phantom_files)
    error('No phantom files found matching name given');
end

switch lower(PARAMS.COMPUTATIONMETHOD)
    case 'cluster'
        [pth, ID] = fileparts(tempname(pwd));
        datafile = fullfile(pth,ID);
        save(datafile, 'phantom_files', 'phantom_path', 'phantom_name', ...
                       'probe', 'beamset', 'OUTPUT_FILE');
        sge_file = gen_cluster_sge('cluster_scan', length(phantom_files), ...
                                   datafile);
        returnpath = pwd;
        system(sprintf('qsub --bash %s',sge_file))
        cd(returnpath);
        
    case 'parfor'
        [pth, ID] = fileparts(tempname(pwd));
        datafile = fullfile(pth,ID);
        save(datafile, 'phantom_files', 'phantom_path', 'phantom_name', ...
                       'probe', 'beamset', 'OUTPUT_FILE');
%         nProc = matlabpool('size');
%         if nProc == 0
%             matlabpool('open')
%         end
        nProc = parpool('size');
        if nProc == 0
            parpool('open')
        end
        tic
        parfor n =1:length(phantom_files)
            cluster_scan(datafile,n)
        end
        if exist(datafile,'file')
            delete(datafile);
        end

        toc
    otherwise
        for n=1:length(phantom_files) % For each file,
            tstep=sscanf(phantom_files(n).name, [phantom_name '%03d']);
            if isempty(tstep)
                % Warn that we're skipping a file
                warning(['Skipping ' phantom_files(n).name]);
            else
                % Load the phantom
                s=[phantom_path phantom_files(n).name];
                bungle=load(s);
                disp(['Processing ' s]);
                % be careful with built-in function phantom
                dog=bungle.phantom;
                
                [rf,t0]=uf_scan_planewave(probe, beamset, dog);
                
                if debug_fig
                    show_Bmode
                end
                
                % Prepend zeros to make all start at zero
                rf=[zeros(round(t0*probe.field_sample_freq),beamset.no_beams,beamset.no_beamsy,beamset.no_parallel);rf];
                t0=0;
                
                % convert to single precision
                rf = single(rf);
                t0 = single(t0);
                
                % Save the result
                save(sprintf('%s%03d', OUTPUT_FILE, n), 'rf', 't0');
                
            end % matches if isempty(tstep)
        end
        
end
