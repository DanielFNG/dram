classdef DatasetElement < handle 
    % DatasetElement Perform operations on elements of a dataset.
    %   A Dataset can be broken down in to constituent elements, corresponding
    %   to a specific subject and a specific combination of context
    %   parameters. For example, consider a Dataset with 2 subjects, and 2
    %   context parameters A and B, where A can be [1,2,3] and B can be
    %   [1,2]. Here, a an example of a DatasetElement is the piece of the 
    %   Dataset corresponding to subject 1, A = 1, B = 1. 
    %
    %   This class contains methods for working with DatasetElements, e.g.
    %   getting the appropriate data and model paths and performing OpenSim
    %   operations such as IK, RRA and CMC. Internally, a DatasetElement uses 
    %   the runBatch method, which itself builds OpenSimTrial objects.
    %
    %   Users are unable to use DatasetElements directly. Instead, they are
    %   created by the Dataset class as part of the process method.

    properties (Access = ?Dataset)
        ParentDataset
        Subject
        ParameterValues
        DataFolderPath
        MotionFolderPath
        ForcesFolderPath
        ModelFolderPath
        ModelPath
        AdjustedModelPath
    end
    
    methods (Access = ?Dataset)

        function obj = DatasetElement(dataset, subject, parameters)
            % A DatasetElement is initialised from the parent Dataset, a
            % particular subject, and an ordered vector of context
            % parameters.
            
            obj.ParentDataset = dataset;
            obj.Subject = subject;
            obj.ParameterValues = parameters;
            obj.ModelFolderPath = dataset.getModelFolderPath();
            obj.constructDataPaths();
            obj.constructModelPath();
            obj.constructAdjustedModelPath();
        end
        
        function performModelAdjustment(obj)
            % Adjust the model file using the RRA algorithm.
            
            % Get only the first marker and grf files. 
            markers = dirNoDots(obj.MotionFolderPath);
            forces = dirNoDots(obj.ForcesFolderPath);
            
            % Create the OpenSimTrial.
            trial = OpenSimTrial(obj.ModelPath, ...
                [obj.MotionFolderPath filesep markers(1,1).name], ...
                [obj.DataFolderPath filesep ...
                obj.ParentDataset.AdjustmentFolderName], ...
                [obj.ForcesFolderPath filesep forces(1,1).name]);
            
            % Run an IK if necessary.
            if ~trial.computed.IK
                trial.run('IK');
            end
            
            % Do RRA adjustment. 
            trial.performModelAdjustment('torso', ...
                obj.AdjustedModelPath, ...
                obj.ParentDataset.getHumanModelPath(), ...
                'load', obj.constructLoadPath());
        end
        
        function runAnalyses(obj, analyses)
            % Runs batch of OpenSim analyses on the input data.
            
            if obj.ParentDataset.ModelAdjustmentCompleted
                model = obj.AdjustedModelPath;
            else
                model = obj.ModelPath;
            end
            
            runBatch(analyses, model, obj.MotionFolderPath, ...
                [obj.DataFolderPath filesep ...
                obj.ParentDataset.ResultsFolderName], ...
                obj.ForcesFolderPath, 'load', obj.constructLoadPath());
        end
        
    end
        
    methods (Access = private)
        
        function path = constructSubjectFolderName(obj)
            % Construct the name of the subject specific folder.
            path = [obj.ParentDataset.SubjectPrefix num2str(obj.Subject)];
        end
        
        function constructDataPaths(obj)
            % Construct paths to exterior data folder, as well as motion
            % folder and forces folder. 
            
            % Create the parameter string.
            name = [];
            for i=1:obj.ParentDataset.NContextParameters
                name = [name filesep obj.ParentDataset.ContextParameters{i} ...
                    num2str(obj.ParameterValues(i))]; %#ok<*AGROW>
            end
            
            % Construct the path to the appropriate folders.
            obj.DataFolderPath = ...
                [obj.ParentDataset.getDataFolderPath() filesep ...
                obj.constructSubjectFolderName() name];
            obj.MotionFolderPath = [obj.DataFolderPath filesep ...
                obj.ParentDataset.MotionFolderName];
            obj.ForcesFolderPath = [obj.DataFolderPath filesep ...
                obj.ParentDataset.ForcesFolderName];
        end
        
        function constructModelPath(obj)
            % Construct path to correct model file. 
            name = obj.ParentDataset.ModelMap(...
                obj.ParameterValues(obj.ParentDataset.ModelParameterIndex));
            obj.ModelPath = [obj.ParentDataset.getModelFolderPath() filesep ...
                obj.constructSubjectFolderName() filesep name];
        end
        
        function constructAdjustedModelPath(obj)
            % Construct path to correct adjusted model file. 
            [path, name, ext] = fileparts(obj.ModelPath);
            obj.AdjustedModelPath = ...
                [path filesep name obj.ParentDataset.AdjustmentSuffix ext];
        end
        
        function path = constructLoadPath(obj)
            % Construct path to the correct load descriptor xml file.
            name = obj.ParentDataset.LoadMap(...
                obj.ParameterValues(obj.ParentDataset.ModelParameterIndex));
            path = [obj.ParentDataset.getModelFolderPath() filesep name];
        end
       
    end

end

