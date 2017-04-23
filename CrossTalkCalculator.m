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
   
    %读取文件内容
    DataFileContent = fileread(DataFilePath);
    
    %匹配一个数值得正则表达式
    RegExpNumber = '[\+\-]?[0-9]*\.?[0-9]+(?:[Ee][\+\-]?[0-9]+)?';

    
    %获取文本文件中的GridSize信息（即XY轴格点数目）
    GridSize = regexp(DataFileContent,['Grid Size is (',RegExpNumber,') x ',...
        '(',RegExpNumber,')[ \t\r\f]*\n'],'tokens');
    %如果未找到GridSize信息则报错
    if isempty(GridSize)
        error(['无法从',DataFilePath,'找到GridSize信息']);
    %如果找到多个GridSize信息
    elseif numel(GridSize) > 1
        %输出警告并选取最后一个目标
        warning('找到多于1个GridSize信息，最靠后的一个将被用于后续计算');
        GridSize = GridSize(end);
    end
    %如果能找到GridSize信息，进一步获取X，Y轴方向的GridSize（regexp获取的信息是字符串类型的，需要转换成数值型）
    GridSizeY =  str2double(GridSize{1}{1});
    GridSizeX =  str2double(GridSize{1}{2});
   
    %获取数据文件中的4个边角的坐标
    CornerXY = regexp(DataFileContent,['Corners of Data Set \(plotted\)[ \t\r\f]*\n',...
        repmat(['[ \t]*(\w+):\((',RegExpNumber,'),(',RegExpNumber,'),',RegExpNumber,'\)[ \t\r\f]*\n'],[1,4])],...
        'tokens');
    %如果未找到边角坐标信息则报错
    if isempty(CornerXY)
        error(['无法从',DataFilePath,'找到边角坐标信息']);
    %如果找到多个边角坐标信息
    elseif numel(CornerXY) > 1
        %输出警告并选取最后一个目标
        warning('找到多于1个边角坐标信息，最靠后的一个将被用于后续计算');
        CornerXY = CornerXY(end);
    end
    %如果能找到边角坐标信息，将获取的token进行reshape便于观察和下一步处理
    CornerXY = reshape(CornerXY{1},3,[])';
    %分别获取文本文件中的4个角的坐标
    for iCorner = 1:size(CornerXY,1)
        switch  lower(CornerXY{iCorner,1})
            case 'topleft'
                TopLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
            case 'topright'
                TopRightCornerXY =  str2double(CornerXY(iCorner,2:3));
            case 'bottomleft'
                BottomLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
            case 'bottomright'
                BottomRightCornerXY =  str2double(CornerXY(iCorner,2:3));
            otherwise
                error(['未知的边角坐标信息:',CornerXY{iCorner,1},'(',CornerXY{iCorner,2},',',CornerXY{iCorner,3},')']);
        end
    end
   
    %判断是否得到了全部4个角坐标
    if ~(exist('TopLeftCornerXY','var') && exist('TopRightCornerXY','var') &&...
        exist('BottomLeftCornerXY','var') && exist('BottomRightCornerXY','var'))
        %如果没有得到全部4个角的坐标,则抛出相应错误
        error('无法得到全部4个角的坐标!');
    end
    
    %计算二维格点的XY坐标
    DataX = linspace(TopLeftCornerXY(1),TopRightCornerXY(1),GridSizeX);
    DataY = linspace(TopLeftCornerXY(2),BottomLeftCornerXY(2),GridSizeY);
    
    %获取文本文件中的二维数据矩阵
    DataZ = regexp(DataFileContent,[repmat(['(',RegExpNumber,')\t'],[1,GridSizeX]),'[ \t\r\f]*\n'],'tokens');
    %将数据从字符串cell类型转换成数值型矩阵
    DataZ = reshape(str2double([DataZ{:}]),GridSizeY,[]);
    
    %当得到的二维矩阵尺寸与GridSize指定的不一致时显示错误
    if any(size(DataZ) ~= [GridSizeY, GridSizeX]) 
        error('得到的二维矩阵尺寸与GridSize指定的不一致!');
    end
    
    %获取源文件的文件名作为源类型
    [~ , SourceType, ~] = fileparts(DataFilePath);
    
    %将需要的信息填入结构体数组之中
    DataStruct(iDataFile) = struct('SourceFilePath', DataFilePath , 'SourceType', SourceType,...
        'DataX', DataX, 'DataY', DataY, 'DataZ', DataZ);
    
end
%将得到的结构体数组存为Mat文件
%生成存储文件路径
AllDataMatPath = fullfile(DataDirectory,'AllData.mat');
%检查是否文件是否已经存在
if exist(AllDataMatPath,'file')
    %如果文件已经存在，弹出对话框询问是否替换掉原有文件
    RepalceDataMatOrNot = questdlg(['''',AllDataMatPath,'''已经存在，是否替换它？'], ...
	'文件替换确认', ...
	'是','否，请保留原有文件','终止程序','否，请保留原有文件');
end
%如果文件不存在，则直接保存文件
if ~exist('RepalceDataMatOrNot','var') 
    save(AllDataMatPath,'DataStruct','-mat');
%如果文件存在，且用户选择了替换，则进行文件替换,
elseif strcmp(RepalceDataMatOrNot,'是') 
    save(AllDataMatPath,'DataStruct','-mat');
    %并在命令行窗口输出提示信息
    disp(['Info:''',AllDataMatPath,'''已被更新']);
elseif isempty(RepalceDataMatOrNot) || strcmp(RepalceDataMatOrNot,'终止程序')
    %终止程序
    return;
end


%% 将读取到结构体的数据进行处理
[MaxZValue, MaxZIndex] = max(DataStruct(1).DataZ(:));
[MaxYIndex, MaxXIndex] = ind2sub(size(DataStruct(1).DataZ),MaxZIndex);
DataZMaxY = DataStruct(1).DataZ(MaxYIndex,:);

for iDataFile = 1:NumDataFile
    
    

end


