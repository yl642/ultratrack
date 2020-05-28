function [rf,t0]=uf_scan(probe, beamset, phantom, varargin);
% function [rf,t0]=uf_scan(probe, beamset, phantom, varargin);

if (nargin>3),
	stat_win=(varargin{1}==2);
	stat_txt=(varargin{1}==1);
	else
	stat_txt=1;
	stat_win=0;
	end;
	
% make sure that phantom.position and phantom.amplitude are double precision variables
%run('/getlab/pjh7/field_sims/LoadPhantom.m')
phantom.position = double(phantom.position);
phantom.amplitude = double(phantom.amplitude);
            
% Select each vector in the beamset and calculate echo signal
%

%pre-allocate memory
rfdata=zeros(1,beamset.no_beams,beamset.no_beamsy,beamset.no_parallel);

tic

for n_vector=1:beamset.no_beams;
    if stat_txt,
        disp(sprintf('Processing Vector Lat %d of %d',n_vector, beamset.no_beams));
    end
    for m_vector = 1:beamset.no_beamsy;
        if stat_txt && beamset.no_beamsy>1,
            disp(sprintf('Processing Vector Elev %d of %d', m_vector, beamset.no_beamsy));
        end
        for p_vector = 1:beamset.no_parallel;
            if stat_txt && beamset.no_parallel>1,
                disp(sprintf('Processing Parallel RX %d of %d', p_vector, beamset.no_parallel));
            end
        
            % Make transmit and receive apertures as defined by probe
            [tx, rx]=uf_make_xdc(probe);
        
            toffset = uf_set_beam(tx, rx, probe, beamset, 1, n_vector, m_vector, p_vector);

            [red_phantom] = reduce_scats(phantom, tx, rx, beamset.minDB);
            
            [v,t1]=calc_scat(tx, rx, red_phantom.position, red_phantom.amplitude);
            
            t1 = t1-toffset;
            if (size(rfdata,1)<length(v)),
                disp('Memory');
                rfdata=[rfdata ;zeros(length(v)-size(rfdata,1),beamset.no_beams,beamset.no_beamsy,beamset.no_parallel) ];
            end;
            rfdata(1:length(v),n_vector,m_vector,p_vector)=v;
            start_times(n_vector,m_vector,p_vector)=t1;
            
            xdc_free(tx)
            xdc_free(rx)
        end;
    end;
end

% Create rf with equal t0s from rfdata
[rf,t0]=uf_time_eq(rfdata,start_times,probe.field_sample_freq);

[puls tpuls] = makeImpulseResponse(probe.impulse_response.bw*1e-2,probe.impulse_response.f0,probe.field_sample_freq);

t0=t0-(max(tpuls)-min(tpuls));%length(puls)/probe.field_sample_freq;

toc
