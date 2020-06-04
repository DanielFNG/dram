classdef Dataset < handle
    % Dataset An organised set of dynamic motion data. 
    %   A Dataset is a set of dynamic motion data for processing with
    %   musculoskeletal modelling software OpenSim. Data is in the form of
    %   marker trajectories and force data and subject specific
    %   musculoskeletal models. The data is organised by subject and
    %   according to a set of context parameters. Context parameters affect
    %   the context in which data was recorded - examples could be speed
    %   (of gait), assistance level (of robotic assistance), control scheme
    %   (again of robotic assistance), etc. A Dataset must be constructed
    %   according to information provided in a DatasetDescriptor.xml file.
    %   See PDF documentation for more details. 
    %
    %   This class contains methods for working with a Dataset, e.g. parsing
    %   a DatasetDescriptor and allowing easy access to various dataset paths
    %   which are used when performing dynamic analyses. This class also
    %   contains the process method, which breaks the Dataset in to
    %   constituent DatasetElements, then performs a set of motion analyses
    %   which are provided by the user. These analyses are OpenSim functions
    %   such as IK (inverse kinematics) and ID (inverse dynamics). 
    
    properties (SetAccess = private)
        DatasetName
        Subjects
        ContextParameters
        ContextParameterRanges
        ModelAdjustmentCompleted = false
        Elements
    end
    
    properties %(Access = {?DatasetElement, ?Dataset})
        Type = 'GaitCycles'
        Delay
        MarkerSystem
        GRFSystem
        LegLengths
        ToeLengths
        NContextParameters
        ModelParameterIndex
        AdjustmentSuffix
        SubjectPrefix
        MotionFolderName
        ForcesFolderName
        AdjustmentFolderName
        ResultsFolderName
        ModelMap
        LoadMap
        ModelAdjustmentValues
        DataFolderName
        ModelFolderName
        HumanModel
        AdjustmentParameterValues
        DatasetRoot
    end
    
    methods
         
        function obj = Dataset(root)
            % Constructor for Dataset objects. 
            %   The varargin entry should represent a desired parameter list,
            %   provided as a set of name-value pairs i.e. the name of a
            %   parameter followed by a vector of values which that parameter
            %   should take within this dataset.
        
            if nargin > 0
                obj.DatasetRoot = root;
                obj.parseDatasetDescriptor();
                obj.populate();
            end
        end
        
        function performModelAdjustment(obj)
            % Corrects for dynamic inconsistency in the model using RRA.
            %   This function performs RRA analyses (and the IK analyses which
            %   are required to do this) based on what is specified in the
            %   DatasetDescriptor. RRA is performed and then the masses of the
            %   model bodies are adjusted based on the RRA results.
        
            % Check if this is needed.
            if obj.ModelAdjustmentCompleted
                error('Model adjustment already performed.');
            end
            
            model_vals = obj.getModelAdjustmentValues();
            non_model_vals = obj.AdjustmentParameterValues;
            for subject = obj.getDesiredSubjectValues()
                for model = 1:length(model_vals)
                    non_model_vals(obj.ModelParameterIndex) = model_vals(model);
                    element = DatasetElement(obj, subject, non_model_vals);
                    element.performModelAdjustment();
                end
            end
            obj.ModelAdjustmentCompleted = true;
        end
         
        function process(obj, analyses, varargin)
            % Performs OpenSim processing.
            %   Analyses should be a cell array of OpenSim function names to the
            %   appropriate methods of DatasetElement e.g. {'IK',
            %   'RRA'} is a suitable set of analyses. Note that these
            %   analyses are EXECUTED IN ORDER. Care must be taken of the input
            %   order. Attempting to execute RRA before IK will result in an 
            %   error. The user should not manually pass the combinations or 
            %   subjects parameters. These are provided by the resume function 
            %   in the case of resuming from a failed run.
            
            % Function to run - batch OpenSim processing.
            func = @runAnalyses;
            
            % Perform dataLoop.
            obj.dataLoop(func, analyses, varargin{:});    
        end
        
        function assert(obj, analyses)
           
            % Function to run - assertComputed.
            func = @assertComputed;
            
            % Perform dataLoop.
            obj.dataLoop(func, analyses);
            
        end
        
        function load(obj, analyses)
           
            % Function to run - loading of data.
            func = @loadAnalyses;
            
            % Perform dataLoop.
            obj.dataLoop(func, analyses);
            
        end
        
        
        %% Temporary, hard-coded functions 
        function [overall_mean, overall_sdev] = computeObservations(obj, func)
        % Another hard coded function for innovation funding.
        
            n_subjects = 1;
            
            overall_obs = zeros(46*n_subjects, 1);
            %overall_obs = zeros(5*n_subjects, 1);
            count = 1;
            
            for i=1
                
                for j=1:length(obj.Elements(i).Motions)
                    gc = obj.Elements(i).Motions{j};
                    overall_obs(count, 1) = func(gc);
                    count = count + 1;
                end
                
            end
            
            overall_mean = mean(overall_obs);
            overall_sdev = std(overall_obs);
            
        end
        
        function [subject_means, overall_mean, overall_sdev] = ...
                computeTrajectories(obj, joint)
        % Another hard coded function for innovation funding.
        
            n_subjects = 1;
            
            subject_means = zeros(n_subjects, 100);
            overall_mean = zeros(1, 100);
            overall_sdev = zeros(1, 100);
            
            overall_traj = zeros(46*n_subjects, 100);
            %overall_traj = zeros(5*n_subjects, 100);
            mass = obj.Elements(1).Trials{1}.getInputModelMass;
            count = 1;
            
            for i=1
                
                n_motions = length(obj.Elements(i).Motions);
                spline_to = 100;
                outer_traj = zeros(n_motions, 100);
                for j=1:length(obj.Elements(i).Motions)
                    gc = obj.Elements(i).Motions{j};
                    %traj = gc.getJointTrajectory(joint);
                    traj = gc.getJointTorqueTrajectory(joint);
                    outer_traj(j, :) = stretchVector(traj, spline_to);
                    overall_traj(count, :) = stretchVector(traj, spline_to);
                    count = count + 1;
                end
                    
                subject_means(i, :) = mean(outer_traj);
                
            end
            
            overall_mean(:) = mean(overall_traj);
            overall_sdev(:) = std(overall_traj);
            
        end
        
        function observations = compute(obj, metric, args)
        % Note: this function is currently very hard coded and was used to 
        % process some data from the Exoskeleton Gait Metrics dataset. 
        % Obviously this needs to be generalised. 
            
            n_subjects = length(obj.Subjects);
            n_assistances = length(obj.ContextParameterRanges{1});
            n_speeds = length(obj.ContextParameterRanges{2});
            
            observations = zeros(n_speeds * n_subjects * 5, n_assistances);
            
            for i=1:length(obj.Elements)
                subject = find(obj.Subjects == obj.Elements(i).Subject);
                assistance = obj.Elements(i).ParameterValues(1);
                speed = obj.Elements(i).ParameterValues(2);
                this = ((speed - 1)*n_subjects + subject - 1)*5 + 1;
                observations(this:this + 4, assistance) = ...
                    obj.Elements(i).computeMetric(metric, args);
            end
            
        end
        
    end
    
    methods (Access = ?DatasetElement)
        
        function path = getDataFolderPath(obj)
            % Path to external data folder. 
            path = [obj.DatasetRoot filesep obj.DataFolderName];
        end
        
        function path = getResultsFolderPath(obj)
            % Path to external results folder.
            path = [obj.DatasetRoot filesep obj.ResultsFolderName];
        end
        
        function path = getAdjustmentFolderPath(obj)
            % Path to adjustment folder.
            path = [obj.DatasetRoot filesep obj.AdjustmentFolderName];
        end
        
        function path = getModelFolderPath(obj)
            % Path to external model folder. 
            path = [obj.DatasetRoot filesep obj.ModelFolderName];
        end
        
        function path = getHumanModelPath(obj)
            % Path to human model file. 
            path = [obj.getModelFolderPath() filesep obj.HumanModel];
        end
        
    end
    
    methods (Access = protected)
        
        function params = getDesiredParameterValues(obj)
            % Gets vector of parameter values. Required for DataSubset.
            params = obj.ContextParameterRanges;
        end
        
        function subjects = getDesiredSubjectValues(obj)
            % Gets vector of subject values. Required for DataSubset. 
            subjects = obj.Subjects;
        end
        
       function values = getModelAdjustmentValues(obj)
            % Get values of the model parameter to use for adjustment.
            %   Required for DataSubset.
            values = obj.ModelAdjustmentValues;
       end
       
       function populate(obj)
       % Create and store the DatasetElements which populate this Dataset.
           
           % Create all possible combinations of the context parameters.
           params = obj.getDesiredParameterValues();
           combos = combvec(obj.getDesiredSubjectValues(), params{1, :});
           n_combinations = size(combos, 2);
           
           % Initialise an empty cell array to store the DatasetElements. 
           elements(n_combinations) = DatasetElement;
           obj.Elements = elements;
           
           % Create each DatasetElement in turn. 
           for i=1:n_combinations
               % Create a DatasetElement.
               obj.Elements(i) = DatasetElement(...
                   obj, combos(1, i), combos(2:end, i));
           end
           
       end
        
       function dataLoop(obj, func, inputs, combinations)
           % Loops over data to process or load data.
           %   Loops over DatasetElements performing handle functions and
           %   providing visual feedback as to process. In the event of a
           %   failed run, a file is saved to the current directory, which can
           %   be used to resume from once the source of the error has been
           %   fixed (see resume function).
           
           if nargin == 3
               remaining_combinations = 1:length(obj.Elements);
           elseif nargin == 5
               remaining_combinations = combinations;
           else
               error('Incorrect input arguments to dataLoop.');
           end
           
           % Print a starting message.
           fprintf('Beginning processing.\n');
           
           % Create a record of the current attempt. 
           attempt = parallel.pool.DataQueue;
           current_attempt = 0;
           afterEach(attempt, ...
               @(n) (noteCurrentAttempt(n, remaining_combinations)));
           
           function noteCurrentAttempt(n, remaining_combinations)
               current_attempt = remaining_combinations(n);
           end
           
           % Create a parallel waitbar + record of remaining combinations.
           queue = parallel.pool.DataQueue;
           n_elements = length(remaining_combinations);
           combination_status = zeros(1, n_elements);
           computed_elements = 0;
           progress = waitbar(0, 'Processing data...');
           afterEach(queue, @updateCombinations);
           
           function updateCombinations(n)
               combination_status(n) = 1;
               computed_elements = computed_elements + 1;
               waitbar(computed_elements/n_elements, progress);
           end
           
           % Disable permission denied warning for all workers. 
           spmd
               warning('off', 'MATLAB:DELETE:PermissionDenied');
           end
           
           % Get the element array in sliceable form.
           elements = obj.Elements(remaining_combinations);
           
           % For every combination of subject and context parameters...
           try
               parfor combination = 1:n_elements
                   % Note the current attempt.
                   send(attempt, combination);
                   
                   % Access the specifc element.
                   element = elements(combination);
                   
                   % Perform the handle functions in turn.
                   feval(func, element, inputs);
                   
                   % Assign back to elements array.
                   elements(combination) = element;
                   
                   % Send data to queue to allow waitbar to update as well
                   % as the remaining combinations.
                   send(queue, combination);
                   
                   [~, info] = memory;
                   proportion_free = ...
                       info.PhysicalMemory.Total/info.PhysicalMemory.Available;
                   if proportion_free < 0.1
                       error('Running out of RAM. Please resume from save.');
                   end
               end
           catch err
               close(progress);
               success = remaining_combinations(combination_status == 1);
               obj.Elements(success) = elements(success);
               remaining_combinations(combination_status == 1) = []; %#ok<NASGU>
               fprintf('Failed on the following element:\n');
               obj.Elements(current_attempt) 
               save([obj.DatasetRoot filesep ...
                   datestr(now, 30) '.mat'], 'obj', 'inputs', ...
                   'remaining_combinations');
               poolobj = gcp('nocreate');
               delete(poolobj);
               rethrow(err);
           end
           
           % Update the Elements property.
           obj.Elements(remaining_combinations) = elements;
           
           % Print closing message & close loading bar.
           fprintf('Data processing complete.\n');
           close(progress);
       end
    end
    
    methods (Access = private)
    
        function parseDatasetDescriptor(obj)
            % Parse the DatasetDescriptor file and assign properties.
            xml_data = xmlread([obj.DatasetRoot filesep ...
                'DatasetDescriptor.xml']);

            % Get the dataset name.
            obj.DatasetName = strtrim(char(...
                xml_data.getElementsByTagName('Name').item(0). ...
                    item(0).getData()));

            % Get the descriptor strings. 
            obj.SubjectPrefix = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'SubjectPrefix').item(0).item(0).getData()));
            obj.DataFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'DataFolderName').item(0).item(0).getData()));
            obj.ModelFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ModelFolderName').item(0).item(0).getData()));
            obj.MotionFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'MarkersFolderName').item(0).item(0).getData()));
            obj.ForcesFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ForcesFolderName').item(0).item(0).getData()));
            obj.AdjustmentFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'AdjustmentFolderName').item(0).item(0).getData()));
            obj.ResultsFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ResultsFolderName').item(0).item(0).getData()));
            obj.HumanModel = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'HumanModel').item(0).item(0).getData()));
            
            % Get the processing information.
            obj.Delay = ...
                str2double(strtrim(char(xml_data.getElementsByTagName(...
                'Delay').item(0).item(0).getData())));
            
            % Get the marker co-ordinate system information.
            markers = xml_data.getElementsByTagName('Markers');
            obj.MarkerSystem.Forward = strtrim( ...
                char(markers.item(0).getElementsByTagName('Forward'). ...
                item(0).item(0).getData()));
            obj.MarkerSystem.Up = strtrim( ...
                char(markers.item(0).getElementsByTagName('Upwards'). ...
                item(0).item(0).getData()));
            obj.MarkerSystem.Right = strtrim( ...
                char(markers.item(0).getElementsByTagName('Right'). ...
                item(0).item(0).getData()));
            
            % Get the grf co-ordinate system information.
            grfs = xml_data.getElementsByTagName('GRF');
            obj.GRFSystem.Forward = strtrim( ...
                char(grfs.item(0).getElementsByTagName('Forward'). ...
                item(0).item(0).getData()));
            obj.GRFSystem.Up = strtrim( ...
                char(grfs.item(0).getElementsByTagName('Upwards'). ...
                item(0).item(0).getData()));
            obj.GRFSystem.Right = strtrim( ...
                char(grfs.item(0).getElementsByTagName('Right'). ...
                item(0).item(0).getData()));
            
            % Get the subject vector. 
            subjects = xml_data.getElementsByTagName('Subjects');
            obj.Subjects = str2num(strtrim(char(subjects.item(0). ...
                item(0).getData()))); %#ok<ST2NM>
            
            % Get the leg length vector.
            leg_lengths = xml_data.getElementsByTagName('LegLengths');
            obj.LegLengths = str2num(strtrim(char(leg_lengths.item(0). ...
                item(0).getData()))); %#ok<ST2NM>
            
            % Get the toe length vector.
            toe_lengths = xml_data.getElementsByTagName('ToeLengths');
            obj.ToeLengths = str2num(strtrim(char(toe_lengths.item(0). ...
                item(0).getData()))); %#ok<ST2NM>

            % Get the context parameter data.
            parameters = xml_data.getElementsByTagName('Parameter');
            obj.NContextParameters = parameters.getLength();
            model_parameter = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ModelParameter').item(0).item(0).getData()));
            parameter_names = cell(1, obj.NContextParameters);
            parameter_values = cell(1, obj.NContextParameters);
            adjustment_values = zeros(1, obj.NContextParameters);
            for i=0:obj.NContextParameters - 1
                parameter_names{i + 1} = ...
                    strtrim(char(parameters.item(i). ...
                    getElementsByTagName('Name'). ...
                    item(0).item(0).getData()));
                parameter_values{i + 1} = ...
                    str2num(strtrim(char(parameters.item(i). ...
                    getElementsByTagName('Values'). ...
                    item(0).item(0).getData()))); %#ok<ST2NM>
                if strcmp(parameter_names{i + 1}, model_parameter)
                    adjustment_values(i+1) = 0;
                else
                    adjustment_values(i+1) = ...
                        str2double(strtrim(char(parameters.item(i). ...
                        getElementsByTagName('AdjustmentValue'). ...
                        item(0).item(0).getData())));
                end
            end
            obj.ContextParameters = parameter_names;
            obj.ContextParameterRanges = parameter_values;
            obj.AdjustmentParameterValues = adjustment_values;
            obj.ModelParameterIndex = find(strcmp(obj.ContextParameters, ...
                    model_parameter));
            obj.AdjustmentSuffix = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'AdjustmentSuffix').item(0).item(0).getData()));
    
            % Get the model set data.
            model_set = xml_data.getElementsByTagName('Model');
            load_set = xml_data.getElementsByTagName('Load');
            n_models = model_set.getLength();
            n_loads = load_set.getLength();
            model_names = cell(n_models, 1);
            load_names = cell(n_loads, 1);
            model_indices = cell(n_models, 1);
            load_indices = cell(n_models, 1);
            model_adjustment_values = zeros(n_models, 1);
            k = 1;
            for i=0:n_models - 1
                model_names{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Name').item(0).item(0).getData()));
                model_indices{i + 1} = str2num(strtrim(char(...
                    model_set.item(i).getElementsByTagName(...
                    'ParameterValues').item(0).item(0).getData()))); %#ok<ST2NM>
                model_adjustment_values(i+1) = str2double(strtrim(char(...
                    model_set.item(i).getElementsByTagName(...
                    'AdjustmentValue').item(0).item(0).getData())));
                for j=1:length(model_indices{i+1})
                    model_map_key{k} = model_indices{i + 1}(j); %#ok<*AGROW>
                    model_map_value{k} = model_names{i + 1};
                    k = k + 1;
                end
            end
            obj.ModelAdjustmentValues = model_adjustment_values;
            obj.ModelMap = containers.Map(model_map_key, model_map_value);
            k = 1;
            for i=0:n_loads - 1
                load_names{i + 1} = strtrim(char(load_set.item(i). ...
                    getElementsByTagName('Name').item(0).item(0).getData()));
                load_indices{i + 1} = str2num(strtrim(char(...
                    load_set.item(i).getElementsByTagName(...
                    'ParameterValues').item(0).item(0).getData()))); %#ok<ST2NM>
                for j=1:length(load_indices{i + 1})
                    load_map_key{k} = load_indices{i + 1}(j);
                    load_map_value{k} = load_names{i + 1};
                    k = k + 1;
                end
            end               
            obj.LoadMap = containers.Map(load_map_key, load_map_value);
        end
    end
    
    methods (Static)
        
        function resume(filename)
            % Continue data processing from a save file.
            %   Takes as input the filename of a save file which was produced
            %   by the dataLoop method (e.g. for a failed run). Resumes
            %   processing or loading from the point of failure.
            
            load(filename, 'obj', 'inputs', 'remaining_combinations');
            obj.process(inputs, elements);
        end
    end
    
end