%本程序完成串扰计算
%测试环境：Windows8.1(x64) MatlabR2016b(x64)
%修改记录：
%   1.

%清空变量空间
clear;

%% 选择数据所在文件夹

%设置对话框标题
DialogTitle = '请选中数据所在文件夹';

%设置默认选中的文件夹
%如果默认文件夹未被设定(打开软件后第一次运行程序)，则将其设定为当前路径
if ~exist('DefaultDataDirectory.mat','file')
    DefaultDataDirectory = pwd;
else
    load('DefaultDataDirectory.mat');
end

%弹出文件夹选择对话框
DataDirectory = uigetdir(DefaultDataDirectory,DialogTitle);

%如果点击的“取消”按键（此时返回的文件夹路径为0）则退出脚本
if DataDirectory == 0 
    %显示退出提示信息
    warning('没有选中任何数据文件夹，程序将退出');
    
    %结束运行脚本
    return;
end

%如果默认选择的文件夹位置发生了改变，则将默认的文件夹更新为上次选中的文件夹
if ~strcmp(DefaultDataDirectory, DataDirectory)
    DefaultDataDirectory = DataDirectory;
    save('DefaultDataDirectory.mat','DefaultDataDirectory');
end

%% 获取数据文件并对其进行读取 

%设置数据文件过滤选项，下面语句表示将所有扩展名为txt的文件视为数据文件
DataFileFilter = '*.txt';

%获得过滤后的数据文件列表DataFileList
DataFileList = dir(fullfile(DataDirectory,DataFileFilter));

%获取数据文件个数
NumDataFile = numel(DataFileList);

DataStruct(1:NumDataFile) = struct('SourceFilePath', [], 'SourceType', [],...
    'DataX', [], 'DataY', [], 'DataZ', []);

%对数据文件列表中的每个文件进行读取
for iDataFile = 1:NumDataFile
    
    %当前处理数据文件的文件名
    DataFilePath = fullfile(DataFileList(iDataFile).folder,DataFileList(iDataFile).name);
   
    %获取文本文件中的GridSize信息（即XY轴格点数目）
    GridSize = FindFirstPatternInTextFile(DataFilePath,'Grid Size is %d x %d %*[^\n]');
    %如果未找到GridSize信息则报错
    if isempty(GridSize)
        error(['无法从',DataFilePath,'找到GridSize信息']);
    end
    %如果能找到GridSize信息，进一步获取X，Y轴方向的GridSize
    GridSizeX =  GridSize{1};
    GridSizeY =  GridSize{2};
        
    %获取文本文件中的DataCell大小信息（即每个小格的长宽尺寸）
    DataCell = FindFirstPatternInTextFile(DataFilePath,'Data Cells are %f64 x %f64 %*[^\n]');
    %如果未找到DataCell信息则报错
    if isempty(DataCell)
        error(['无法从',DataFilePath,'找到DataCell信息']);
    end
    %如果能找到DataCell信息，进一步获取X，Y轴方向的DataCell
    DataCellX =  DataCell{1};
    DataCellY =  DataCell{2};
    
    %获取文本文件中的4个角的坐标
    [~,DataCornerStartLine] = FindFirstPatternInTextFile(DataFilePath,'Corners of Data Set (plotted)%[^\n]');
    %如果未找到4个角的坐标则报错
    if DataCornerStartLine == -1
        error(['无法从',DataFilePath,'找到4个角坐标']);
    end
    
    %打开数据文件
    DataFileId = fopen(DataFilePath);
    
    DataCornerText = textscan(DataFileId,'%[^\n]',4,...
        'HeaderLines', DataCornerStartLine, 'CollectOutput', 1);
    
    DataCornerText = [DataCornerText{1}{:}];
    
    TopLeft = textscan(DataFileId,'TopLeft:(%f64,%f64 %*[^\n]',1,...
        'HeaderLines', DataCornerStartLine, 'CollectOutput', 1);
    
    
    %计算数据的X值和Y值
    DataX = double(0:GridSizeX-1) * DataCellX;
    DataY = double(0:GridSizeY-1) * DataCellY;
    
    %获取文本文件中的二维数据矩阵
    [~,MatDataStartLine] = FindFirstPatternInTextFile(DataFilePath,[repmat('%f64\t',[1,GridSizeX]),'%*[^\n]']);
    %如果未找到二维数据矩阵则报错
    if MatDataStartLine == -1
        error(['无法从',DataFilePath,'找到二维矩阵数据']);
    end
    
    %重新将搜索位置设置到文件开头（因为上一次的textscan会改动指向位置）
    frewind(DataFileId);
    
    %根据上面得到二维矩阵开始的行数读取二维矩阵数据
    MatDataCell = textscan(DataFileId,[repmat('%f64 ',[1,GridSizeX]),'%*[^\n]'],...
        'HeaderLines', MatDataStartLine - 1, 'CollectOutput', 1);
    
    %关闭打开的数据文件
    fclose(DataFileId);
    
    %将二维矩阵数据由cell类型转换为矩阵类型
    DataZ = cell2mat(MatDataCell);
    
    %当得到的二维矩阵尺寸与GridSize指定的不一致时显示错误
    if any(size(DataZ) ~= [GridSizeX, GridSizeY]) 
        error('得到的二维矩阵尺寸与GridSize指定的不一致!');
    end
    
    %获取源文件的文件名作为源类型
    [~ , SourceType, ~] = fileparts(DataFilePath);
    
    %将需要的信息填入结构体数组之中
    DataStruct(iDataFile) = struct('SourceFilePath', DataFilePath , 'SourceType', SourceType,...
        'DataX', DataX, 'DataY', DataY, 'DataZ', DataZ);
    
end
save(fullfile(DataDirectory,'AllData.mat'),'DataStruct');


%% 将读取到结构体的数据进行处理
[MaxZValue,MaxZIndex] = max(DataStruct(1).DataZ(:));
[MaxYIndex, MaxXIndex] = ind2sub(size(DataStruct(1).DataZ),MaxZIndex);
DataZMaxY = DataStruct(1).DataZ(MaxYIndex,:);

for iDataFile = 1:NumDataFile
    
    

end

filecontent = fileread('test.txt');
% result = regexp(filecontent,'Grid Size is ([0-9]*\.?[0-9]+) x ([0-9]*\.?[0-9]+)','tokens');

