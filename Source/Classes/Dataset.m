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
    end
    
    properties (Access = {?DatasetElement, ?Dataset})
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
        
       function dataLoop(obj, func, inputs, combinations)
           % Loops over data to process or load data.
           %   Loops over DatasetElements performing handle functions and
           %   providing visual feedback as to process. In the event of a
           %   failed run, a file is saved to the current directory, which can
           %   be used to resume from once the source of the error has been
           %   fixed (see resume function).
           
           if nargin == 3
               % Create all possible combinations of the context parameters.
               params = obj.getDesiredParameterValues();
               remaining_combinations = combvec(...
                   obj.getDesiredSubjectValues(), params{1,:});
           elseif nargin == 4
               % Continue from previous state.
               remaining_combinations = combinations;
           else
               error('Incorrect input arguments to dataLoop.');
           end
           
           % Print a starting message.
           fprintf('Beginning processing.\n');
           
           % Create a record of the current attempt. 
           attempt = parallel.pool.DataQueue;
           current_attempt = 0;
           afterEach(attempt, @noteCurrentAttempt);
           
           function noteCurrentAttempt(n)
               current_attempt = remaining_combinations(:, n);
           end
           
           % Create a parallel waitbar + record of remaining combinations.
           queue = parallel.pool.DataQueue;
           n_combinations = size(remaining_combinations, 2);
           combination_status = zeros(1, n_combinations);
           computed_elements = 0;
           progress = waitbar(0, 'Processing data...');
           afterEach(queue, @updateCombinations);
           
           function updateCombinations(n)
               combination_status(n) = 1;
               computed_elements = computed_elements + 1;
               waitbar(computed_elements/n_combinations, progress);
           end
           
           % Disable permission denied warning for all workers. 
           spmd
            warning('off', 'MATLAB:DELETE:PermissionDenied');
           end
           
           % For every combination of subject and context parameters...
           try
               parfor combination = 1:n_combinations
                   % Note the current attempt.
                   send(attempt, combination);
                   
                   % Create a DatasetElement.
                   element = DatasetElement(obj, ...
                       remaining_combinations(1, combination), ...
                       remaining_combinations(2:end, combination));
                   
                   % Perform the handle functions in turn.
                   func(element, inputs); %#ok<*PFBNS>
                   
                   % Send data to queue to allow waitbar to update as well
                   % as the remaining combinations.
                   send(queue, combination);
                   
                   [~, info] = memory;
                   proportion_free = ...
                       info.PhysicalMemory.Total/info.PhysicalMemory.Available
                   if proportion_free < 0.1
                       error('Running out of RAM. Please resume from save.');
                   end
               end
           catch err
               close(progress);
               nrows = size(remaining_combinations, 1);
               ncols = size(remaining_combinations, 2);
               remaining_combinations(combination_status == 1) = [];
               remaining_combinations = reshape(remaining_combinations, ...
                   [nrows, ncols - computed_elements]);
               fprintf('Failed on the following combination:\n');
               current_attempt %#ok<NOPRT>
               save([obj.DatasetRoot filesep ...
                   datestr(now, 30) '.mat'], 'obj', 'inputs', ...
                   'remaining_combinations');
               poolobj = gcp('nocreate');
               delete(poolobj);
               rethrow(err);
           end
           
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
            
            % Get the subject vector. 
            subjects = xml_data.getElementsByTagName('Subjects');
            obj.Subjects = str2num(strtrim(char(subjects.item(0). ...
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
            obj.process(inputs, remaining_combinations);
        end
    end
    
end