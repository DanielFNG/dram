function convertMarkerFiles(element, ~)
    markers = element.getMotionFiles();
    for i=1:length(markers)
        file = Data(markers{i});
        file.writeToFile(markers{i});
    end
end