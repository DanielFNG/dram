function dataset = parseDatasetDescriptor(filename)

% Parse the DatasetDescriptor file.
xml_data = xmlread(model_path);

% Get the dataset name.
dataset_name = xml_data.getElementsByTagName('Name').item(0);

% Get all the descriptor strings, the context parameters and the model set.
descriptor_strings = xml_data.getElementsByTagName('Strings');
context_parameters = xml_data.getElementsByTagName('ContextParameters');
model_set = xml_data.getElementsByTagName('ModelSet');

% Get the individual strings. 
string_info.subject_prefix = descriptor_strings.getElementsByTagName('SubjectPrefix').item(0);
string_info.data_folder = descriptor_strings.getElementsByTagName('DataFolderName').item(0);
string_info.model_folder = descriptor_strings.getElementsByTagName('ModelFolderName').item(0);


% Get the context parameter data. 
context_info.n_context_parameters = str2num(context_parameters.getElementsByTagName('NParameters').item(0));
context_info.model_parameter_index = str2num(context_parameters.getElementsByTagName('ModelParameterIndex').item(0));
named_parameters = context_parameters.getElementsByTagName('NamedParameter');
context_info.n_named_parameters = named_parameters.getLength();
named_parameter_indices = cell(n_named_parameters, 1);
named_parameter_names = cell(n_named_parameters, 1);
for i=0:n_named_parameters - 1
    named_parameter_indices{i + 1} = str2num(named_parameters.item(i).getElementsByTagName('Index').item(0));
    named_parameter_indices{i + 1} = named_parameters.item(i).getElementsByTagName('Name').item(0);
end
context_info.named_parameter_indices = named_parameter_indices;
context_info.named_parameter_names = named_parameter_names;
    
% Get the model set data.
model_info.n_models = model_set.getLength();
model_names = cell(n_models, 1);
model_indices = cell(n_models, 1);
for i=0:n_models - 1
    model_names{i} = model_names.item(i).getElementsByTagName('Name');
    model_indices{i} = str2num(model_names.item(i).getElementsByTagName('ParameterValues');
end
model_info.model_names = model_names;
model_info.model_indices = model_indices;

% Create the dataset.
dataset = Dataset(dataset_name, string_info, context_info, model_info);

end