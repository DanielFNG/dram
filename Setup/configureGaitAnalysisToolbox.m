function configureExopt()
% Adds the appropriate Gait Analysis Toolbox source directories to the
% Matlab path. 

% Modify the Matlab path to include the source folder.
addpath(genpath(['..' filesep 'Source'));

% Include any additional libraries. 
addpath(genpath(['..' filesep 'External' filesep 'multiWaitbar']));
    
% Save resulting path.
savepath;

end
