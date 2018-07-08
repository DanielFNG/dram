function dataset = parseDatasetDescriptor(filename)

% Parse the DatasetDescriptor file.
xml_data = xmlread(filename);

% Get the dataset name.
dataset_name = strtrim(char(...
    xml_data.getElementsByTagName('Name').item(0).item(0).getData()));

% Get the descriptor strings. 
string_info.subject_prefix = strtrim(char(xml_data.getElementsByTagName(...
    'SubjectPrefix').item(0).item(0).getData()));
string_info.data_folder = strtrim(char(xml_data.getElementsByTagName(...
    'DataFolderName').item(0).item(0).getData()));
string_info.model_folder = strtrim(char(xml_data.getElementsByTagName(...
    'ModelFolderName').item(0).item(0).getData()));

% Get the context parameter data.
parameters = xml_data.getElementsByTagName('Parameter');
context_info.n_context_parameters = parameters.getLength();
parameter_names = cell(context_info.n_context_parameters, 1);
for i=0:context_info.n_context_parameters - 1
    parameter_names{i + 1} = strtrim(char(parameters.item(i). ...
        getElementsByTagName('Name').item(0).item(0).getData()));
end
context_info.parameter_names = parameter_names;
context_info.model_parameter = strtrim(char(xml_data. ...
    getElementsByTagName('ModelParameter').item(0).item(0).getData()));
    
% Get the model set data.
model_set = xml_data.getElementsByTagName('Model');
model_info.n_models = model_set.getLength();
model_names = cell(model_info.n_models, 1);
model_indices = cell(model_info.n_models, 1);
for i=0:model_info.n_models - 1
    model_names{i + 1} = strtrim(char(model_set.item(i). ...
        getElementsByTagName('Name').item(0).item(0).getData()));
    model_indices{i + 1} = str2num(strtrim(char(model_set.item(i). ...
        getElementsByTagName('ParameterValues').item(0). ...
        item(0).getData()))); %#ok<ST2NM>
end
model_info.model_names = model_names;
model_info.model_indices = model_indices;

% Create the dataset.
dataset = Dataset(dataset_name, string_info, context_info, model_info);

end