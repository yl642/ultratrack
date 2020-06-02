function [active_min,active_max]=def_active_min_max_ele_ids(num_ele,focal_depth,fnum,pitch)
    % calculate the number of active elements
    active_elements = (focal_depth / fnum) / pitch;
    
    % we want to center this active aperture in the matrix
    center_element_id = floor(num_ele/2);

    % computer the min and max element ids for the active aperture
    active_min = center_element_id - floor(active_elements/2);
    active_max = center_element_id + floor(active_elements/2);

    % check to make sure that the min and max ids don't exceed the number of physical elements
    if (active_min < 1),
        warning('Matrix Min Element < 1; being set to 1.  Check matrix definition.');
        active_min = 1;
    end;

    if(active_max > num_ele),
        warning('Matrix Max Element > NUM_ELE; being set to NUM_ELE.  Check matrix definition.');
        active_max = num_ele;
    end;

end