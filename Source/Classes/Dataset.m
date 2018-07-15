classdef Dataset < handle
   
    properties (SetAccess = private)
        DatasetName
        ContextParameters
        ModelParameter
        SubsetName
        DesiredSubjects
        DesiredParameters
        IKDirectory
        AdjustmentRRADirectory
        RRADirectory
        IDDirectory
        BodyKinematicsDirectory
        CMCDirectory
    end
    
    properties % (GetAccess = private, SetAccess = private)
        SubjectPrefix
        DataFolderName
        ModelFolderName
        NContextParameters
        ModelParameterIndex
        AdjustmentSuffix
        ModelMap
        LoadMap
        SubsetRoot
    end
    
    methods
        
        % The varargin entry should represent a desired parameter list,
        % provided as a set of name-value pairs i.e. the name of a
        % parameter followed by a vector of values which that parameter
        % should take within this dataset. 
        function obj = Dataset(name, root, subjects, varargin)
            if nargin > 0
                obj.SubsetName = name;
                obj.SubsetRoot = root;
                obj.parseDatasetDescriptor();
                obj.DesiredSubjects = subjects;
                obj.parseParameterList(varargin));
                obj.ModelParameterIndex = find(strcmp(obj.ContextParameters, ...
                    obj.ModelParameter));
            end
        end
    
        function parseDatasetDescriptor(obj)

            % Parse the DatasetDescriptor file.
            xml_data = xmlread([obj.SubsetRoot filesep ...
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

            % Get the context parameter data.
            parameters = xml_data.getElementsByTagName('Parameter');
            obj.NContextParameters = parameters.getLength();
            parameter_names = cell(obj.NContextParameters, 1);
            for i=0:obj.NContextParameters - 1
                parameter_names{i + 1} = ...
                    strtrim(char(parameters.item(i). ...
                    getElementsByTagName('Name'). ...
                    item(0).item(0).getData()));
            end
            obj.ContextParameters = parameter_names;
            obj.ModelParameter = ...
                strtrim(char(xml_data.getElementsByTagName(...
                'ModelParameter').item(0).item(0).getData()));
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
                    map_key{k} = model_indices{i + 1}(j);
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
                getElementsByTagName('BK').item(0).item(0).getData()));
            obj.IDDirectory = strtrim(char(xml_data.getElementsByTagName(...
                'ID').item(0).item(0).getData()));
            obj.CMCDirectory = strtrim(char(xml_data.getElementsByTagName(...
                'CMC').item(0).item(0).getData()));
        end
        
        function parseParameterList(obj, param_list)
            if length(param_list) == 2 * obj.NContextParameters
                parsed_param_list = cell(obj.NContextParameters, 1);
                for i=1:2:2 * obj.NContextParameters - 1
                    if ~strcmp(obj.ContextParameters, param_list{i})
                        error('Context parameter name not recognised.');
                    else
                        parsed_param_list{strcmp(obj.ContextParameters, ...
                            param_list{i})} = param_list{i + 1};
                    end
                end
            else
                error(['The number of parameter values given ' ...
                    'does not match the number of ' ...
                    'context parameters in this Dataset.']);
            end
            obj.DesiredParameters = parsed_param_list;
        end
        
        function path = getSubjectFolderPath(obj, element)
        
            path = [obj.SubsetRoot filesep obj.SubjectPrefix...
                num2str(element.Subject)];
        
        end
        
        function path = getDataFolderPath(obj, element)
        
            path = [obj.getSubjectFolderPath(element.Subject) filesep ...
                obj.DataFolderName]; 
        
        end
        
        function path = getModelFolderPath(obj, element)
        
            path = [obj.getSubjectFolderPath(element.Subject) filesep ...
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
        
        function process(obj, handles)
        
            % Note the number of handle functions.
            n_functions = length(handles);
        
            % Create all possible combinations of the context parameters.
            combinations = combvec(obj.DesiredParameters);
            
            % For every subject...
            for subject = obj.DesiredSubjects
                % For every combination of context parameters...
                for parameters = combinations 
                    % Create a DatasetElement.
                    element = DatasetElement(obj, subject, parameters);
                    
                    % Perform the handle functions in turn.
                    for i = 1:n_functions
                        @handles{i}(element);
                    end
                end
            end
        
        end
    end
    
end