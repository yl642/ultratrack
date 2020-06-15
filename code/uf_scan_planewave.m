function [rf,t0]=uf_scan_planewave(probe, beamset, phantom)
% function [rf,t0]=uf_scan_planewave(probe, beamset, phantom);
	
% make sure that phantom.position and phantom.amplitude are double precision variables
phantom.position = double(phantom.position);
phantom.amplitude = double(phantom.amplitude);
            
% Select each vector in the beamset and calculate echo signal
%pre-allocate memory
rfdata=zeros(1,beamset.no_beams,beamset.no_beamsy,beamset.no_parallel);

tic

for n_vector=1:beamset.no_beams
    fprintf('Processing PlaneWave Scan %d of %d\n',n_vector, beamset.no_beams);
    
    for p_vector = 1:beamset.no_parallel
        fprintf('Processing Vector Lat %d of %d\n',p_vector, beamset.no_parallel);
        % Make transmit and receive apertures as defined by probe
        [tx, rx]=uf_make_xdc(probe);

        toffset = uf_set_beam_planewave(tx, rx, probe, beamset, 1, n_vector, 1, p_vector);

%         [red_phantom] = reduce_scats(phantom, tx, rx, beamset.minDB);
        red_phantom = phantom;

        [v,t1]=calc_scat(tx, rx, red_phantom.position, red_phantom.amplitude);

        t1 = t1 - toffset; % actually not sure how to set toffset
        
        if (size(rfdata,1)<length(v))
%             disp('Memory');
            rfdata=[rfdata ;zeros(length(v)-size(rfdata,1),beamset.no_beams,beamset.no_beamsy,beamset.no_parallel) ];
        end
        
        rfdata(1:length(v),n_vector,1,p_vector)=v;
        start_times(n_vector,1,p_vector)=t1;

        xdc_free(tx)
        xdc_free(rx)
    end
end

% Create rf with equal t0s from rfdata
[rf, t0]=uf_time_eq(rfdata, start_times, probe.field_sample_freq);

[puls, ~]=uf_ir(probe); %impulse response
excitation=uf_txp(beamset.tx_excitation, probe.field_sample_freq);  %if have more than one TX beams might be an issue
noffset_conv=conv(puls,conv(excitation,puls));

t0 = t0 - length(noffset_conv)/probe.field_sample_freq/2;


toc
