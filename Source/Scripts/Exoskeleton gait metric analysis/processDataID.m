% Requires that the processDataRRA.m script has already been run.

% Create cell arrays to hold the results.
% ID_array follows the same indexing style as described in
% 'processDataIK.m'.
ID_array{9,3,2,10} = {};

% Get the root folder.
root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

% Total number of ID's to perform. 
% 1680 IK results, only 1496 of which were processed using RRA.
total_ID = 1496;

% ID's performed so far.
current_ID = 0;

% Construct a loading bar.
h = waitbar(current_ID, 'Performing batch ID.');

% Loop over the nine subjects. 
for subject=1:9
    % Skip the missing data.
    if ~ (subject == 5)
        % There are four dates which need to be represented in the path.
        if subject == 1 || subject == 3 || subject == 4
            date = '18';
        elseif subject == 2
            date = '16';
        elseif subject == 6
            date = '19';
        else
            date = '22';
        end
        
        % Get the path for this subject.
        subject_path = [root 'S' num2str(subject) '\17-05-' date];
        
        % Load the RRA_adjustments array.
        load([root 'RRA_Results.mat'], 'RRA_adjustments');
        
        % Get the RRA-adjusted model files for this subject.
        adjusted_model = RRA_adjustments{subject,1}.getAdjustedModel();
        adjusted_model_APO = RRA_adjustments{subject,2}.getAdjustedModel();
        
        % Loop over left/right gait cycles.
        for j=1:2
            switch j
                case 1
                    gait = [subject_path '\dynamicElaborations\right'];
                case 2
                    gait = [subject_path '\dynamicElaborations\left'];
            end
            
            % Loop over the ten contexts.
            for i=1:10
                % Ignore contexts 3 and 5.
                if ~(subject == 3 || subject == 5)
                    % Filenames are different for steady state vs non steady state.
                    if mod(i,2) == 1
                        folder = [gait 'Non-StSt'];
                    else
                        folder = [gait 'StSt'];
                    end
                    
                    for assistance_level=1:3
                        % Get the IK and GRF folders.
                        if assistance_level == 1
                            % No APO.
                            ik_folder = [folder '\NE' num2str(i) '\RRA_Results'];
                            grf_folder = [folder '\NE' num2str(i)];
                            model = adjusted_model;
                        elseif assistance_level == 2
                            % With APO, transparent.
                            ik_folder = [folder '\ET' num2str(i) '\RRA_Results'];
                            grf_folder = [folder '\ET' num2str(i)];
                            model = adjusted_model_APO;
                        elseif assistance_level == 3
                            % With APO, assisted.
                            ik_folder = [folder '\EA' num2str(i) '\RRA_Results'];
                            grf_folder = [folder '\ET' num2str(i)];
                            model = adjusted_model_APO;
                        end
                        
                        % Perform batch RRA.
                        ID_array{subject,assistance_level,j,i} = ...
                            runBatchID(model, ik_folder, grf_folder, [grf_folder '\ID_Results']);
                        
                        % Update the loading bar.
                        if mod(i,2) == 1
                            current_ID = current_ID + 2;
                        else
                            current_ID = current_ID + 5;
                        end
                        waitbar(current_ID/total_ID);
                    end
                end
            end
        end
    end
end

% Close the loading bar.
close(h);

% Save the results to a Matlab save file. 
save([root 'ID_Results.mat'], 'ID_array');
    