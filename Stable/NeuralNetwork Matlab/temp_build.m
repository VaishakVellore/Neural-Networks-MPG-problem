
filename = 'C:\Users\Vaishak\Desktop\NeuralNetwork\auto-mpg1.csv';
delimiter = ',';
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);
fclose(fileID);
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8]
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
          
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end

rawNumericColumns = raw(:, [1,2,3,4,5,6,7,8]);
rawStringColumns = string(raw(:, [9,10,11,12,13,14]));

R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells
for catIdx = [1,2,3,4]
    idx = (rawStringColumns(:, catIdx) == "<undefined>");
    rawStringColumns(idx, catIdx) = "";
end
autompg2 = table;
autompg2.Cylinder = cell2mat(rawNumericColumns(:, 2));
autompg2.Displacement = cell2mat(rawNumericColumns(:, 3));

autompg2.HorsePower = cell2mat(rawNumericColumns(:, 5));
autompg2.Carweight = cell2mat(rawNumericColumns(:, 6));
autompg2.Acceleration = cell2mat(rawNumericColumns(:, 7));

autompg2([33,127,331,337,355,375],:) = [];
size(autompg2);

Array1 = table2array(autompg2);
Final_autompg2 = array2table(Array1.');
Final_autompg2.Properties.RowNames = autompg2.Properties.VariableNames;

output= autompg2;
output = table;
output.MPG = cell2mat(rawNumericColumns(:, 1));
output([33,127,331,337,355,375],:) = [];

Array2 = table2array(output);
Output_table = array2table(Array2.');
Output_table.Properties.RowNames = output.Properties.VariableNames;
Output= table2array(Output_table);
Input= table2array(Final_autompg2);

x = Input;
t = Output;


trainFcn = 'trainlm';  
hiddenLayerSize = 10;
net = fitnet(hiddenLayerSize,trainFcn);

net.input.processFcns = {'removeconstantrows','mapminmax'};
net.output.processFcns = {'removeconstantrows','mapminmax'};


net.divideFcn = 'dividerand';  % Divide data randomly
net.divideMode = 'sample';  % Divide up every sample
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

net.performFcn = 'mse';  % Mean squared error

net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
  'plotregression', 'plotfit'};

% Train the Network
[net,tr] = train(net,x,t);

% Test the Network
y = net(x);
e = gsubtract(t,y);
performance = perform(net,t,y);

% Recalculate Training, Validation and Test Performance
trainTargets = t .* tr.trainMask{1};
valTargets = t  .* tr.valMask{1};
testTargets = t  .* tr.testMask{1};
trainPerformance = perform(net,trainTargets,y);
valPerformance = perform(net,valTargets,y);
testPerformance = perform(net,testTargets,y);

% View the Network
view(net)

if (false)
  
  genFunction(net,'myNeuralNetworkFunction');
  y = myNeuralNetworkFunction(x);
end
if (false)
  
  genFunction(net,'myNeuralNetworkFunction','MatrixOnly','yes');
  y = myNeuralNetworkFunction(x);
end
if (false)
  gensim(net);
end

E= sum(y);
A= sum(Output);

Error= (E-A)/A;
Accuracy= (1-Error)*100;





