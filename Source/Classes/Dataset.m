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
    
    properties (SetAccess = private, Hidden = true)
        IKDirectory
        AdjustmentRRADirectory
        RRADirectory
        IDDirectory
        BodyKinematicsDirectory
        CMCDirectory
        AdjustmentSuffix
        ModelAdjustmentValues
    end
    
    properties (GetAccess = private, SetAccess = private)
        SubjectPrefix
        DataFolderName
        MarkersFolderName
        ForcesFolderName
        ResultsFolderName
        ModelFolderName
        NContextParameters
        ModelParameterIndex
        ModelMap
        LoadMap
        DatasetRoot
        
        AdjustmentParameterValues
        DesiredSubjectValues
        DesiredParameterValues
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
    
        function parseDatasetDescriptor(obj)

            % Parse the DatasetDescriptor file.
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
            obj.MarkersFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'MarkersFolderName').item(0).item(0).getData()));
            obj.ForcesFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ForcesFolderName').item(0).item(0).getData()));
            obj.ResultsFolderName = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ResultsFolderName').item(0).item(0).getData()));
            
            % Get the subject vector. 
            subjects = xml_data.getElementsByTagName('Subjects');
            obj.Subjects = str2num(strtrim(char(subjects.item(0). ...
                item(0).getData()))); %#ok<ST2NM>
            obj.DesiredSubjectValues = obj.Subjects;

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
            obj.DesiredParameterValues = parameter_values;
            obj.ContextParameterRanges = parameter_values;
            obj.AdjustmentParameterValues = adjustment_values;
            obj.ModelParameterIndex = find(strcmp(obj.ContextParameters, ...
                    model_parameter));
            obj.AdjustmentSuffix = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'AdjustmentSuffix').item(0).item(0).getData()));
    
            % Get the model set data.
            model_set = xml_data.getElementsByTagName('Model');
            n_models = model_set.getLength();
            model_names = cell(n_models, 1);
            model_loads = cell(n_models, 1);
            model_indices = cell(n_models, 1);
            model_adjustment_values = zeros(n_models, 1);
            k = 1;
            for i=0:n_models - 1
                model_names{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Name').item(0).item(0).getData()));
                model_loads{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Load').item(0).item(0).getData()));
                model_indices{i + 1} = str2num(strtrim(char(...
                    model_set.item(i).getElementsByTagName(...
                    'ParameterValues').item(0).item(0).getData()))); %#ok<ST2NM>
                model_adjustment_values(i+1) = str2double(strtrim(char(...
                    model_set.item(i).getElementsByTagName(...
                    'AdjustmentValue').item(0).item(0).getData())));
                for j=1:length(model_indices{i+1})
                    map_key{k} = model_indices{i + 1}(j); %#ok<*AGROW>
                    map_value{k} = model_names{i + 1};
                    load_map_value{k} = model_loads{i + 1};
                    k = k + 1;
                end
            end
            obj.ModelAdjustmentValues = model_adjustment_values;
            obj.ModelMap = containers.Map(map_key, map_value);
            obj.LoadMap = containers.Map(map_key, load_map_value);
            
            % Get the results directory names. 
            obj.IKDirectory = strtrim(char(xml_data.getElementsByTagName(...
                'IK').item(0).item(0).getData()));
            obj.AdjustmentRRADirectory = strtrim(char(...
                xml_data.getElementsByTagName('AdjRRA').item(0).item(0). ...
                getData()));
            obj.RRADirectory = strtrim(char(xml_data.getElementsByTagName(...
                'RRA').item(0).item(0).getData()));
            obj.BodyKinematicsDirectory = strtrim(char(xml_data. ...
                getElementsByTagName('BodyKinematics'). ...
                item(0).item(0).getData()));
            obj.IDDirectory = strtrim(char(xml_data.getElementsByTagName(...
                'ID').item(0).item(0).getData()));
            obj.CMCDirectory = strtrim(char(xml_data.getElementsByTagName(...
                'CMC').item(0).item(0).getData()));
        end
        
        function path = getSubjectFolderPath(obj, element)
            path = [obj.DatasetRoot filesep obj.SubjectPrefix...
                num2str(element.Subject)];
        end
        
        function path = getDataFolderPath(obj, element)
            path = [obj.getSubjectFolderPath(element) filesep ...
                obj.DataFolderName]; 
        end
        
        function path = getModelFolderPath(obj, element)
            path = [obj.getSubjectFolderPath(element) filesep ...
                obj.ModelFolderName];
        end
        
        function name = getModelName(obj, element)
            name = obj.ModelMap(...
                element.ParameterValues(obj.ModelParameterIndex));
        end
        
        function n = getNContextParameters(obj)
            n = obj.NContextParameters;
        end
        
        function params = getDesiredParameterValues(obj)
            params = obj.DesiredParameterValues;
        end
        
        function subjects = getDesiredSubjectValues(obj)
            subjects = obj.DesiredSubjectValues;
        end
        
        function adj_mod_values = getModelAdjustmentValues(obj)
            adj_mod_values = obj.ModelAdjustmentValues;
        end
        
        function index = getModelParameterIndex(obj)
            index = obj.ModelParameterIndex;
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
            
            adj_mod_values = obj.getModelAdjustmentValues();
            adj_values = obj.AdjustmentParameterValues;
            model_index = adj_values == 0;
            for subject = obj.getDesiredSubjectValues()
                for model = 1:length(adj_mod_values)
                    adj_values(model_index) = adj_mod_values(model);
                    element = DatasetElement(obj, subject, adj_values);
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
            func = @DatasetElement.runAnalyses;
            
            % Perform dataLoop.
            obj.dataLoop(func, analyses, varargin{:});    
        end
        
        function dataLoop(obj, func, inputs, combinations)
            % Loops over data to process or load data.
            %   Loops over DatasetElements performing handle functions and
            %   providing visual feedback as to process. In the event of a 
            %   failed run, a file is saved to the current directory, which can 
            %   be used to resume from once the source of the error has been 
            %   fixed (see resume function).
        
            if nargin == 4
                % Create all possible combinations of the context parameters.
                params = obj.getDesiredParameterValues();
                remaining_combinations = combvec(obj.Subjects, params{1,:});
            elseif nargin == 6
                % Continue from previous state.
                remaining_combinations = combinations;
            else
                error('Incorrect input arguments to dataLoop.');
            end
            
            n_combinations = size(remaining_combinations, 2);
            computed_elements = 0;
            
            % Print a starting message.
            fprintf('Beginning processing.\n');
            
            % Create a parallel waitbar.
            p = 1;
            queue = parallel.pool.DataQueue;
            progress = waitbar(0, [func 'ing data...']);
            afterEach(queue, @nUpdateWaitbar);
            afterEach(queue, @updateCombinations);
            
            function nUpdateWaitbar(~)
                waitbar(p/total, progress);
                p = p + 1;
            end
            
            function updateCombinations(n)
                remaining_combinations(:, n) = 0;
                computed_elements = computed_elements + 1;
            end
            
            % For every combination of subject and context parameters...
            try
                parfor combination = 1:n_combinations 
                    % Create a DatasetElement.
                    element = DatasetElement(obj, ...
                        remaining_combinations(1, combination), ...
                        remaining_combinations(2:end, combination));

                    % Perform the handle functions in turn.
                    func(element, inputs); %#ok<*PFBNS>

                    % Send data to queue to allow waitbar to update as well
                    % as the remaining combinations.
                    send(queue, combination);
                end
            catch err
                close(progress);
                nrows = size(remaining_combinations, 1);
                ncols = size(remaining_combinations, 2);
                remaining_combinations(remaining_combinations == 0) = [];
                remaining_combinations = reshape(remaining_combinations, ...
                    [nrows, ncols - computed_elements]);
                save([obj.DatasetRoot filesep ...
                    datestr(now, 30) '.mat'], 'obj', 'handles', 'func', ...
                    'remaining_combinations');
                rethrow(err);
            end
        
            % Print closing message & close loading bar.
            fprintf('Data processing complete.\n');
            close(progress);
        end
    end
    
    methods (Static)
     
        function resume(filename)
            % Continue data processing from a save file.
            %   Takes as input the filename of a save file which was produced
            %   by the dataLoop method (e.g. for a failed run). Resumes 
            %   processing or loading from the point of failure.
            
            load(filename, 'obj', 'handles', 'func', 'remaining_combinations');
            if strcmp(func, 'process')
                obj.process(...
                    handles, remaining_combinations);
            elseif strcmp(func, 'load')
                obj.load(...
                    handles, remaining_combinations);
            end
        end
    end
    
end