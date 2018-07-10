new_dir = 'C:\Users\danie\Documents\GDT Testing';
old_dir = 'D:\Dropbox\PhD\Exoskeleton Metrics';

foot_strings = {'right', 'left'};
assistance_strings = {'NE', 'ET', 'EA'};

% subjects = 1;
% feet = 1;
% contexts = 1;
% assistances = 1;
subjects = [1:4, 6:8];
feet = 1:2;
contexts = 1:10;
assistances = 1:3;

for subject = subjects
    for foot = feet
        for context = contexts
            for assistance = assistances 
                new_folder = [new_dir filesep 'S' num2str(subject) filesep 'Data'...
                    filesep 'Foot' num2str(foot) filesep 'Context' ...
                    num2str(context) filesep 'Assistance' num2str(assistance)];
                mkdir(new_folder);
                old_folder = [old_dir filesep 'S' num2str(subject) filesep...
                    'dynamicElaborations' filesep foot_strings{foot} filesep...
                    assistance_strings{assistance} num2str(context)];
                trc_files = dir([old_folder filesep '*.trc']);
                mot_files = dir([old_folder filesep '*.mot']);
                for i=1:length(trc_files)
                    copyfile(...
                        [old_folder filesep trc_files(i).name], ...
                        [new_folder filesep '00' num2str(i) '.trc']);
                end
                for i=1:length(mot_files)
                    copyfile(...
                        [old_folder filesep mot_files(i).name], ...
                        [new_folder filesep '00' num2str(i) '.mot']);
                end
            end
        end
    end
end