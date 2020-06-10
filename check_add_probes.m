function check_add_probes(probesPath)
if exist(probesPath, 'dir')
    addpath(probesPath);
else
    warning('Probe definitions do not exist; must create your own');
end
