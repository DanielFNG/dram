% Test script for Gait Processing Toolbox changes. 

% Select the root folder.
root = 'C:\Users\Daniel\Documents\Dropbox\PhD\GAT';

% Select desired context parameters to use. 
subjects = 1:2;
contexts = 1:2;
assistances = 1:2;

% Create the Dataset.
%this_dataset = Dataset('this', root, ...
%'Foot', feet, 'Context', contexts, 'Assistance', assistances);

this_dataset = Dataset(root);

this_dataset.performModelAdjustment();

this_dataset.process({'IK', 'RRA', 'BK', 'ID'});