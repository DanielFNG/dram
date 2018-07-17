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
    
    properties (SetAccess = private, GetAccess = private)
        DesiredSubjectValues
        DesiredParameterValues
    end
    
    properties (SetAccess = private)
        DatasetName
        Subjects
        ContextParameters
        ContextParameterRanges
    end
    
    properties (SetAccess = private, Hidden = true)
        IKDirectory
        AdjustmentRRADirectory
        RRADirectory
        IDDirectory
        BodyKinematicsDirectory
        CMCDirectory
    end
    
    properties (GetAccess = private, SetAccess = private)
        SubjectPrefix
        DataFolderName
        ModelFolderName
        NContextParameters
        ModelParameterIndex
        AdjustmentSuffix
        ModelMap
        LoadMap
        DatasetRoot
    end
    
    methods
        
        % The varargin entry should represent a desired parameter list,
        % provided as a set of name-value pairs i.e. the name of a
        % parameter followed by a vector of values which that parameter
        % should take within this dataset. 
        function obj = Dataset(root)
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
            
            % Get the subject vector. 
            subjects = xml_data.getElementsByTagName('Subjects');
            obj.Subjects = str2num(strtrim(char(subjects.item(0). ...
                item(0).getData()))); %#ok<ST2NM>
            obj.DesiredSubjectValues = obj.Subjects;

            % Get the context parameter data.
            parameters = xml_data.getElementsByTagName('Parameter');
            obj.NContextParameters = parameters.getLength();
            parameter_names = cell(1, obj.NContextParameters);
            parameter_values = cell(1, obj.NContextParameters);
            for i=0:obj.NContextParameters - 1
                parameter_names{i + 1} = ...
                    strtrim(char(parameters.item(i). ...
                    getElementsByTagName('Name'). ...
                    item(0).item(0).getData()));
                parameter_values{i + 1} = ...
                    str2num(strtrim(char(parameters.item(i). ...
                    getElementsByTagName('Values'). ...
                    item(0).item(0).getData()))); %#ok<ST2NM>
            end
            obj.ContextParameters = parameter_names;
            obj.DesiredParameterValues = parameter_values;
            obj.ContextParameterRanges = parameter_values;
            model_parameter = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ModelParameter').item(0).item(0).getData()));
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
            k = 1;
            for i=0:n_models - 1
                model_names{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Name').item(0).item(0).getData()));
                model_loads{i + 1} = strtrim(char(model_set.item(i). ...
                    getElementsByTagName('Load').item(0).item(0).getData()));
                model_indices{i + 1} = str2num(strtrim(char(...
                    model_set.item(i).getElementsByTagName(...
                    'ParameterValues').item(0).item(0).getData()))); %#ok<ST2NM>
                for j=1:length(model_indices{i+1})
                    map_key{k} = model_indices{i + 1}(j); %#ok<*AGROW>
                    map_value{k} = model_names{i + 1};
                    load_map_value{k} = model_loads{i + 1};
                    k = k + 1;
                end
            end
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
        
            path = [obj.SubsetRoot filesep obj.SubjectPrefix...
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
        
        function name = getLoadName(obj, element)
            name = obj.LoadMap(...
                element.ParameterValues(obj.ModelParameterIndex));
        end
        
        function n = getNContextParameters(obj)
            n = obj.NContextParameters;
        end
        
        % The function which performs OpenSim processing. Handles should be
        % a cell array of function handles to the appropriate methods of
        % DatasetElement e.g. {@prepareBatchIK, @prepareAdjustmentRRA} is a
        % suitable set of handles. Note that these handles are EXECUTED IN
        % ORDER. Care must be taken of the input order. Attempting to
        % execute RRA before IK will result in an error. 
        function process(obj, handles)
        
            % Note the number of handle functions.
            n_functions = length(handles);
        
            % Create all possible combinations of the context parameters.
            all_combinations = combvec(obj.DesiredParameterValues{:,1});
            n_combinations = size(all_combinations, 2);
            
            % Print a starting message.
            fprintf('Beginning data processing.\n');
            
            % Create a parallel waitbar.
            p = 1;
            queue = parallel.pool.DataQueue;
            progress = waitbar(0, 'Processing data...');
            afterEach(queue, @nUpdateWaitbar);
            
            function nUpdateWaitbar(~)
                waitbar(p/n_combinations, progress);
                p = p + 1;
            end
            
            % For every subject...
            for subject = obj.DesiredSubjectValues
                % For every combination of context parameters...
                try
                    parfor combination = 1:n_combinations 
                        % Create a DatasetElement.
                        element = DatasetElement(obj, subject, ...
                            all_combinations(:, combination));

                        % Perform the handle functions in turn.
                        for i = 1:n_functions
                            handles{i}(element); %#ok<PFBNS>
                        end

                        % Send data to queue to allow waitbar to update.
                        send(queue, combination);
                    end
                catch err
                    close(progress);
                    rethrow(err);
                end
            end
        
            % Print closing message & close loading bar.
            fprintf('Data processing complete.\n');
            close(progress);
        end
    end
    
end