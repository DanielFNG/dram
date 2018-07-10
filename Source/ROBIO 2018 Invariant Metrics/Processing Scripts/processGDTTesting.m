% Test script for Gait Processing Toolbox changes. 

% Select the root folder.
root = 'C:\Users\danie\Documents\GDT Testing';

% Select desired context parameters to use. 
subjects = 1;
feet = 1;
contexts = 2;
assistances = 1:2;

% Create the Dataset.
this_dataset = Dataset('this', root, ...
    'Foot', feet, 'Context', contexts, 'Assistance', assistances);