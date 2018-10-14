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
    %   operations such as IK, RRA and CMC. A DatasetElement knows which
    %   operations have been performed on it so far, and will not allow
    %   unworkable combinations of operations e.g. IK must be done before
    %   RRA, etc. 
    %
    %   Users are unlikely to use DatasetElements directly. Instead, they are
    %   created by the Dataset class as part of the process method.
    %
    %   The base MotionFolder can contain either marker data or IK results?

    properties (SetAccess = private)
        ParentDataset
        Subject
        ParameterValues
    end
    
    properties (GetAccess = private, SetAccess = private)
        CellParameterValues
        DataFolderPath
        MotionFolderPath
        ForcesFolderPath
        ModelFolderPath
        ModelPath
        AdjustedModelPath
        RawDataPath
        IKDataPath
        RRADataPath
    end
    
    methods

        % A DatasetElement is initialised from the parent Dataset, a
        % particular subject, and an ordered vector of context parameters.
        function obj = DatasetElement(dataset, subject, parameters)
            obj.ParentDataset = dataset;
            obj.Subject = subject;
            obj.ParameterValues = parameters;
            obj.CellParameterValues = num2cell(parameters);
            obj.DataFolderPath = dataset.getDataFolderPath(obj);
            obj.ModelFolderPath = dataset.getModelFolderPath(obj);
            obj.constructRawDataPaths();
            obj.constructModelPath();
        end
        
        % Create path to the raw data folder. 
        function constructRawDataPaths(obj)
            % Create the parameter string.
            name = [];
            for i=1:obj.ParentDataset.getNContextParameters()
                name = [name filesep obj.ParentDataset.ContextParameters{i} ...
                    num2str(obj.ParameterValues(i))]; %#ok<*AGROW>
            end
            
            % Create the path to the appropriate data folder.
            obj.MarkersPath = [obj.DataFolderPath name filesep ...
                obj.ParentDataset.MotionFolderName];
            obj.ForcesPath = [obj.DataFolderPath name filesep ...
                obj.ParentDataset.ForcesFolderName];
        end
        
        % Create path to the correct model file. 
        function constructModelPath(obj)
            obj.ModelPath = [obj.ModelFolderPath filesep...
                obj.ParentDataset.getModelName(obj)];
        end
        
        % Create path to the correct adjusted model file. 
        function constructAdjustedModelPath(obj)
            [path, name, ext] = fileparts(obj.ModelPath);
            obj.AdjustedModelPath = ...
                [path filesep name obj.ParentDataset.AdjustmentSuffix ext];
        end
        
        function performModelAdjustment(obj)
        
            % Get only the first marker and grf files. 
            markers = dirNoDots(obj.MotionFolderPath);
            forces = dirNoDots(obj.ForcesFolderPath);
            
            trial = OpenSimTrial(obj.ModelPath, ...
                [obj.MotionFolderPath filesep markers(1,1).name], ...
                [obj.DataFolderPath filesep ...
                    obj.ParentDataset.AdjustmentRRADirectory], ...
                [obj.ForcesFolderPath filesep forces(1,1).name]);
            
            % Run an IK if necessary and then perform model adjustment 
            % using the trial.
            if ~trial.computed.IK
                trial.run('IK');
            end
            trial.performModelAdjustment('torso', ...
                obj.constructAdjustedModelPath(), ...
                obj.ParentDataset.getHumanModelPath());
        end
        
        % Run a batch of analyses on the input data.
        function runAnalyses(obj, analyses)
            runBatch(analyses, obj.AdjustedModelPath, ...
                obj.MotionFolderPath, 
        end
            
        
        %% Methods for loading processed data to file.
        
        function result = loadGRF(obj)
            % Load files.
            grf = obj.loadSimple(obj.RawDataPath, '.mot');
            
            % Assign result.
            result.GRF{obj.CellParameterValues{:}} = grf;
        end
        
        function result = loadIK(obj)
            % Load files.
            ik = obj.loadSimple(obj.IKDataPath, '.mot');
            
            % Assign result.
            result.IK{obj.CellParameterValues{:}} = ik;
        end
        
        function result = loadInputMarkers(obj)
            % Load files.
            im = obj.loadSimple([obj.IKDataPath filesep 'MarkerData', '.trc']);
            
            % Assign result.
            result.InputMarkers{obj.CellParameterValues{:}} = im;
        end
        
        function result = loadOutputMarkers(obj)
            % Load files.
            om = obj.loadSimple([obj.IKDataPath filesep 'MarkerData', '.sto']);
            
            % Assign result.
            result.OutputMarkers{obj.CellParameterValues{:}} = om;
        end
        
        function result = loadBodyPositions(obj)
            % Load files.
            pos = obj.loadSimple([obj.RawDataPath filesep ...
                obj.ParentDataset.BodyKinematicsDirectory], '.    
        end
        
        function result = loadID(obj)
            % Identify ID folders.
            id_path = [obj.RawDataPath filesep obj.ParentDataset.IDDirectory];
            folders = getSubfolders(id_path);
                
            % Create a cell array of appropriate size.
            n_folders = length(folders);
            id{n_folders} = {};
            
            % Read in the ID analyses appropriately. 
            for i=1:n_folders
                % Identify current folder.
                folder = getSubfolders([id_path filesep folders(i, 1).name]);
                if length(folder) ~= 1
                    error('Multiple or zero ID folders detected.');
                end
                
                % Load folder. 
                id{i} = Data([id_path folders(i, 1).name filesep ...
                    folder(1, 1).name filesep 'id.sto']);
            end
            
            % Assign result.
            result.ID{obj.CellParameterValues{:}} = id;
        end
        
    end

end

