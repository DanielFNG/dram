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

    properties (SetAccess = private)
        ParentDataset
        Subject
        ParameterValues
        IKComputed = false
        AdjustmentRRAComputed = false
        RRAComputed = false
        BodyKinematicsComputed = false
        IDComputed = false
        CMCComputed = false 
    end
    
    properties (GetAccess = private, SetAccess = private)
        CellParameterValues
        DataFolderPath
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
            obj.constructRawDataPath();
            obj.constructModelPath();
        end
        
        % Create path to the GRF and marker data files. 
        function constructRawDataPath(obj)
            % Create the parameter string.
            name = [];
            for i=1:obj.ParentDataset.getNContextParameters()
                name = [name filesep obj.ParentDataset.ContextParameters{i} ...
                    num2str(obj.ParameterValues(i))]; %#ok<*AGROW>
            end
            
            % Create the path to the appropriate data folder.
            obj.RawDataPath = [obj.DataFolderPath name];
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
        
        %% Methods for performing OpenSim analyses. 
    
        % Perform IK on this DatasetElement.
        function prepareBatchIK(obj)
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.IKDirectory];
            runBatchIK(obj.ModelPath, obj.RawDataPath, output_dir);
            
            % Update knowledge of IK data path & fact IK has been computed.
            obj.IKDataPath = output_dir;
            obj.IKComputed = true;
        end
        
        % Perform adjustmentRRA on this DatasetElement.
        function prepareAdjustmentRRA(obj)
            % Check if adjustment is necessary.
            if obj.ParentDataset.ModelAdjustmentCompleted
                error('RRA adjustment has already been performed.');
            end
            
            % Require IK for RRA to be performed.
            if ~obj.IKComputed
                error('IK must be performed before doing RRA analyses.');
            end
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.AdjustmentRRADirectory];
            [~, adjusted_model] = adjustmentRRA(...
                obj.ModelPath, obj.IKDataPath, obj.RawDataPath, output_dir, ...
                obj.ParentDataset.getLoadName(obj));
            
            % Copy the adjusted model file in to the appropriate location and 
            % update paths & computed status.
            obj.constructAdjustedModelPath();
            copyfile(adjusted_model, obj.AdjustedModelPath);
            obj.AdjustmentRRAComputed = true;
        end
        
        % Perform RRA on this DatasetElement.
        function prepareBatchRRA(obj)
            % Require IK for RRA to be performed.
            if ~obj.IKComputed
                error('IK must be performed before doing RRA analyses.');
            end
            
            % Require adjustment RRA.
            if ~obj.ParentDataset.ModelAdjustmentCompleted
                error('RRA adjustment required for this Dataset.');
            end
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.RRADirectory];
            runBatchRRA(obj.AdjustedModelPath, obj.IKDataPath, ...
                obj.RawDataPath, output_dir, ...
                obj.ParentDataset.getLoadName(obj));
            
            % Update paths & computed status.
            obj.RRADataPath = output_dir;
            obj.RRAComputed = true;
        end
        
        % Perform ID on this DatasetElement. 
        function prepareBatchID(obj)
            % Require RRA for ID to be performed. 
            if ~obj.RRAComputed
                error('Require RRA to compute ID.');
            end
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.IDDirectory];
            runBatchID(obj.AdjustedModelPath, obj.RRADataPath, ...
                obj.RawDataPath, output_dir, ...
                obj.ParentDataset.getLoadName(obj));
            
            % Updated computed status.
            obj.IDComputed = true;
        end
        
        % Run BodyKinematicsAnalysis on this DatasetElement.
        function prepareBatchBodyKinematicsAnalysis(obj)
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.BodyKinematicsDirectory];
            
            % Use the best available between RRA and IK. 
            if obj.RRAComputed
                runBatchBodyKinematicsAnalysis(obj.AdjustedModelPath, ...
                    obj.RRADataPath, output_dir);
            elseif obj.IKComputed
                runBatchBodyKinematicsAnalysis(obj.ModelPath, ...
                    obj.IKDataPath, output_dir);
            else
                error('Require IK or RRA data to run BodyKinematicsAnalysis.');
            end
            
            % Update computed status. 
            obj.BodyKinematicsComputed = true;
        end
        
        % Run CMC on this DatasetElement.
        function prepareBatchCMC(obj)
            % Require RRA for CMC computation.
            if obj.RRAComputed
                error('Require RRA to compute CMC.');
            end
            
            output_dir = [obj.RawDataPath filesep ...
                obj.ParentDataset.CMCDirectory];
            runBatchCMC(obj.ModelPath, obj.RRADataPath, obj.RawDataPath, ...
                output_dir, obj.ParentDataset.getLoadName(obj));
            
            % Update computed status. 
            obj.CMCComputed = true;
        end
        
        %% Methods for loading processed data to file.
        
        function temp_cell = loadSimple(obj, folder, identifier)
            % Identify the files.
            files = dir([folder filesep '*' identifier]);
            
            % Create cell array of appropriate size.
            n_files = length(files);
            temp{n_files} = {};
            
            % Read in appropriate files as data objects.
            for i=1:n_files
                temp{i} = Data([folder filesep files(i, 1).name]);
            end
        end
        
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
            im = obj.loadSimple([obj.IKDataPath filesep 'MarkerData', '.trc');
            
            % Assign result.
            result.InputMarkers{obj.CellParameterValues{:}} = im;
        end
        
        function result = loadOutputMarkers(obj)
            % Load files.
            om = obj.loadSimple([obj.IKDataPath filesep 'MarkerData', '.sto');
            
            % Assign result.
            result.OutputMarkers{obj.CellParameterValues{:}} = om;
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

