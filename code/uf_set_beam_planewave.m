
function toffset = uf_set_beam_planewave(Tx,Rx,geometry,beamset,idx,vectorx,vectory,vectorp)
%
%	uf_set_beam_planewave(Tx,Rx,beamset,set,vector)
%
%	Takes transmit (Tx) and receive (Rx) aperture pointers, 
%	a beam data structure (beam_struct), and set and vector numbers,
%	and sets up the apertures to match the selected beams.
%
%       The excitation pulse, beam direction, transmit and receive focus
%	are set by this function.   
%
%	Apodization will eventually be set by this function.
%
%	Revisions / Bug Fixes:
%	
%	Feb 6, '04 - fixed half-element displacement error in tx & rx 
%			apodization profiles
%	NOT YET COMPLETE:
%		rx fixed apodization
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Corrected the Tx apodization with the txoffset variable.
% Mark 06/21/05
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% v2.6.0 (MLP, 2012-10-04)
% * added matrix_phased imaging option that avoids resetting xdc_center_focus
% * cleaned up old changes to make more readable
% * incorporated 'linear' and 'phased' imaging modes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2.6.0 (MLP, 2012-10-27)
% Not sure if I need to add an offset_Y into the mix here for the matrix arrays...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2.6.1
% Added parallel receive indexing
% PJH7 2012.11.2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% yl642 2020-07-11 -- converted setup for 1D array probe plane wave imaging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debug_fig = 0;

SPEED_OF_SOUND = geometry.c;
pitch = geometry.width + geometry.kerf_x;
offset_X = pitch * geometry.no_elements_x/2;
element_position_x = (0.5 + (0:(geometry.no_elements_x-1)))*pitch - offset_X;

% Transmit pulser waveform
xdc_excitation(Tx,uf_txp(beamset(idx).tx_excitation,geometry.field_sample_freq));  

%------------------------------------tx------------------------------------%

xdc_center_focus(Tx,[0 0 0]);

angle = beamset(idx).directionx(vectorx);
dly = tan(angle) * pitch/SPEED_OF_SOUND;
dly_sequence = (0 : geometry.no_elements_x - 1) * dly;

xdc_times_focus(Tx, -inf, dly_sequence);

% Tx Apodization: full aperture
xdc_apodization(Tx,-inf,ones(1,geometry.no_elements_x));
%------------------------------------rx------------------------------------%


x0r = beamset(idx).rx_offset(vectorp,1);
y0r = 0;
z0r = 0;
toffset = (x0r + offset_X)*tan(angle)/SPEED_OF_SOUND;  % not sure about this!
xdc_center_focus(Rx,[x0r y0r z0r]);
    
if (beamset(idx).is_dyn_focus)
    xdc_dynamic_focus(Rx,-inf,0,0);
else
    focus_x = x0r;
    focus_y = y0r;
    focus_z = beamset(idx).rx_focus_range;
    xdc_focus(Rx,-inf,[focus_x focus_y focus_z]);
end 

% Rx Apodization

% Aperture Growth 
% for n=1:512
%     ap_times(n,1)=2*beamset(idx).rx_f_num(1)*pitch*(n-1)/SPEED_OF_SOUND;
% 
%     rx_width=n*pitch;
%     
%     %Added lateral || rx offset (Pete, 2012.11.2)
%     rx_ap_left_limit =-rx_width/2+x0r;
%     rx_ap_right_limit= rx_width/2+x0r;;
% 
%     rx_apodization(n,:)= double((element_position_x>=rx_ap_left_limit) & ...
%         (element_position_x<=rx_ap_right_limit));
% 
%     % check to see if no elements are on, and if so, at least turn the center
%     % element on
%     if ~any(rx_apodization(n,:))
%         warning(['No elements in the apodized Rx aperture weighted on; '...
%                  'center element turned on.'])
% %         center_element = floor(size(rx_apodization,2));
%         center_element = floor(size(rx_apodization,2)/2);
%         rx_apodization(n,center_element) = 1;
%     end
% 
%     if (beamset(idx).rx_apod_type==1) % If using a hamming window
%         rx_apodization(n,:)=rx_apodization(n,:).*(0.54+0.46*cos(2*pi*...
%             (element_position_x-x0r)/rx_width));
%     end;
% end;
% 
% if(~(strcmp(geometry.probe_type,'matrix'))),
%     xdc_apodization(Rx,ap_times,rx_apodization)
% else,
%     warning('Apodization not supported for matrix probes; no Rx apodization applied.');
% end;

rx_width_x = abs(geometry.elv_focus)/beamset(idx).rx_f_num;

rx_ap_left_limit_x =-rx_width_x/2+x0r;
rx_ap_right_limit_x= rx_width_x/2+x0r;

rx_apodization_x= double((element_position_x>=rx_ap_left_limit_x) & ...
    (element_position_x<=rx_ap_right_limit_x));

if (beamset(idx).rx_apod_type==1) % If using a hamming window
    rx_apodization=rx_apodization_x.*(0.54+0.46*cos(2*pi*...
        (element_position_x-x0r)/rx_width_x));
end

xdc_apodization(Rx,-inf,rx_apodization);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if debug_fig
 figure(3);
 if vectorx==1 && vectory==1 && vectorp==1
    clf;hold all
    for ii = 1:geometry.no_elements_x
        for jj = 1:geometry.no_elements_y
            p(jj,ii) = patch(1e3*(element_position_x(ii) + [-0.5 0.5 0.5 -0.5]*geometry.width_x),[0 0 0 0],1e3*(element_position_y(jj) + [-0.5 -0.5 0.5 0.5]*geometry.width_y),'m','edgecolor','none');
        end
    end 
    xlabel('x (mm)')
    ylabel('z (mm)')
    zlabel('y (mm)')    
    axis image
    axis ij
    hold all
    plot3(0,1e3*beamset.apex,0,'b*','MarkerSize',10)
 end
k = get(gca,'children');
k = k(end-[0:geometry.no_elements_x*geometry.no_elements_y-1]);
k = reshape(k,geometry.no_elements_y,geometry.no_elements_x);
jett = jet(256);
for ii = 1:geometry.no_elements_x
        for jj = 1:geometry.no_elements_y
            set(k(jj,ii),'FaceColor',jett(floor(tx_apodization(jj,ii)*255)+1,:));
        end
end 
if beamset(idx).rx_focus_range>0
    rvec = [0:10e-3:beamset(idx).rx_focus_range];
elseif beamset(idx).tx_focus_range>0
    rvec = [0:10e-3:1.5*beamset(idx).tx_focus_range];
else
    rvec = [0:10e-3:40e-3];
end
plot3(1e3*[focus_x x0r + rvec*sin(theta)],1e3*[focus_z z0r+rvec*cos(theta)*cos(phi)],1e3*[focus_y y0r+rvec*sin(phi)],'o-');
axis image
view(3);
drawnow;
end
