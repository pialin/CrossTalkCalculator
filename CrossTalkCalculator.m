%本程序完成串扰计算，脚本将在搜索选择文件夹中的扩展名为txt的所有文件，将其作为一组波形，对组内波形计算光串扰
%脚本最终将在所选目录内输出一个'AllDataStruct.mat'文件用于保存组内所有波形的相关数据，
%并输出一个'CrossTalkTable.mat'作为串扰计算的结果
%测试环境：Windows8.1(x64) MatlabR2016b(x64)

%清空变量空间
clear;

%% 用户选择数据所在文件夹

%设置对话框标题
DialogTitle = '请选中数据所在文件夹';

%设置默认选中的文件夹
%如果保存默认文件夹的变量文件不存在(第一次运行程序)，则将当前文件夹设定为默认选中的文件夹
if ~exist('DefaultDataDirectory.mat','file')
    DefaultDataDirectory = pwd;
    %如果保存默认文件夹的变量文件存在，则将读取其中路径作为默认选中的文件夹
else
    load('DefaultDataDirectory.mat');
end

%弹出文件夹选择对话框
DataDirectory = uigetdir(DefaultDataDirectory,DialogTitle);

%如果点击的“取消”按键（此时返回的文件夹路径为0）则退出脚本，否则继续程序
if DataDirectory == 0
    %显示退出提示信息
    warning('没有选中任何数据文件夹，程序将退出');
    
    %结束运行脚本
    return;
end

%如果默认选择的文件夹位置发生了改变，则将默认的文件夹更新为上次选中的文件夹的上一层文件夹(为了便于选择下一个文件夹)
%并存储到DefaultDataDirectory.mat之中
DataDirectoryUpperFolderPath = fileparts(DataDirectory);
if ~strcmp(DefaultDataDirectory, DataDirectoryUpperFolderPath)
    DefaultDataDirectory = DataDirectoryUpperFolderPath;
    save('DefaultDataDirectory.mat','DefaultDataDirectory');
end

%调用参数设置脚本设置用户设定的参数
CrossTalkCalculatorSetting;

%% 获取数据文件并对其进行读取


%设置数据文件过滤选项，下面语句表示将所有扩展名为txt的文件视为数据文件
DataFileFilter = '*.txt';

%获得过滤后的数据文件列表DataFileList
DataFileList = dir(fullfile(DataDirectory,DataFileFilter));

%获取数据文件个数
NumDataFile = numel(DataFileList);

%新建DataStruct用于保存组内所有波形的相关数据:
%其中SourceFilePath记录一组波形的数据来源文件
%SourceLabel为一个波形起一个名称（由'Source'加上txt文件的文件名组成）
%DataX,DataY分别记录X轴和Y轴的刻度，DataZ是一个二维矩阵，用于记录光强矩阵
%DataZMaxY是一个一维矩阵，记录DataZ最大值点所在行的数据
%MaxXIndex和MaxYIndex分别记录DataZ最大值点的X和Y轴坐标
%MainLobeAmpThreshold用于记录取主瓣时选用的幅值阈值，MainLobeXRange记录主瓣的X轴范围，MainLobeArea表示主瓣波形与X轴围成的面积
DataStruct(1:NumDataFile) = struct('SourceFilePath', [] , 'SourceLabel', [],...
    'DataX', [], 'DataY', [], 'DataZ', [],...
    'DataZMaxY', [], 'MaxXIndex', [], 'MaxYIndex', [],...
    'MainLobeAmpThreshold', [], 'MainLobeXRange', [],'MainLobeArea', []);
%如果文件夹中没有找到txt文件
if NumDataFile == 0
    %抛出相应警告
    warning('选中文件夹中无法找到txt数据文件,将退出程序!');
    %退出脚本
    return;
end

%对数据文件列表中的每个文件进行读取
for iDataFile = 1:NumDataFile
    
    %当前处理数据文件的文件名
    DataFilePath = fullfile(DataFileList(iDataFile).folder,DataFileList(iDataFile).name);
    
    %读取文件内容到变量DataFileContent中
    DataFileContent = fileread(DataFilePath);
    
    %匹配一个数值的正则表达式
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
            %左上角坐标
            case 'topleft'
                TopLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
                %右上角坐标
            case 'topright'
                TopRightCornerXY =  str2double(CornerXY(iCorner,2:3));
                %左下角坐标
            case 'bottomleft'
                BottomLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
                %右下角坐标
            case 'bottomright'
                BottomRightCornerXY =  str2double(CornerXY(iCorner,2:3));
                %未知边角坐标信息处理
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
    
    %根据4个边角点坐标计算二维格点的XY轴刻度
    DataX = linspace(TopLeftCornerXY(1),TopRightCornerXY(1),GridSizeX);
    DataY = linspace(TopLeftCornerXY(2),BottomLeftCornerXY(2),GridSizeY);
    
    %获取文本文件中的二维数据矩阵
    DataZ = regexp(DataFileContent,[repmat(['(',RegExpNumber,')\t'],[1,GridSizeX]),'[ \t\r\f]*\n'],'tokens');
    
    %将数据从字符串cell类型转换成数值型矩阵(注意：这里为了便于和附图相对比而做了转置)
    DataZ = reshape(str2double([DataZ{:}]),GridSizeY,[])';
    
    %当得到的二维矩阵尺寸与GridSize指定的不一致时抛出错误
    if any(size(DataZ) ~= [GridSizeY, GridSizeX])
        error('得到的二维矩阵尺寸与GridSize指定的不一致!');
    end
    
    %获取源文件的文件名作为源名称（由'Source'加上txt文件名组成）
    [~ , SourceIndex, ~] = fileparts(DataFilePath);
    SourceLabel = ['Source',SourceIndex];
    
    %获取DataZ最大值及其对应的Z索引
    [MaxZValue, MaxZIndex] = max(DataZ(:));
    %将Z索引转换为XY轴索引
    [MaxYIndex, MaxXIndex] = ind2sub(size(DataZ), MaxZIndex);
    
    %取出最大值所在行的数据
    DataZMaxY = DataZ(MaxYIndex,:);
    
    %根据主瓣阈值计算出主瓣的对应X轴范围
    UnderThresholdXIndex = find(DataZMaxY<=MainLobeAmpThreshold);
    %如果峰值左侧没有小于阈值的点，则将数据最左端设为主瓣左侧起始点
    MainLobeXLeftRange =  max([UnderThresholdXIndex((UnderThresholdXIndex-MaxXIndex)<0),1]);
    %如果峰值右侧没有小于阈值的点，则将数据最右端设为主瓣右侧结束点
    MainLobeXRightRange =  min([UnderThresholdXIndex((UnderThresholdXIndex-MaxXIndex)>=0),numel(DataZMaxY)]);
    %将左右侧点放入MainLobeXRange中
    MainLobeXRange = [MainLobeXLeftRange,MainLobeXRightRange];
    %计算波形主瓣与X轴围成的面积
    MainLobeArea = abs(trapz(DataX(MainLobeXRange(1):MainLobeXRange(2)),...
        DataZMaxY(MainLobeXRange(1):MainLobeXRange(2))));
    
    
    %将得到的信息填入结构体数组之中
    DataStruct(iDataFile) = struct('SourceFilePath', DataFilePath , 'SourceLabel', SourceLabel,...
        'DataX', DataX, 'DataY', DataY, 'DataZ', DataZ,...
        'DataZMaxY', DataZMaxY, 'MaxXIndex', MaxXIndex, 'MaxYIndex', MaxYIndex,...
        'MainLobeAmpThreshold', MainLobeAmpThreshold, 'MainLobeXRange', MainLobeXRange,'MainLobeArea',MainLobeArea);
    
end


%创建一个矩阵用于存放组内所有波形相互之间的串扰值
CrossTalkMat = NaN(numel(DataStruct));
%% 将读取到结构体的数据进行处理
%先取一个目标波形
for iObject = 1:numel(DataStruct)
    %取出目标波形的主瓣X轴范围ObjectMainLobeXRange，最大值所在行数据ObjectDataZMaxY，
    %最大值所在的列索引ObjectMaxXIndex以及X轴的刻度DataX
    ObjectMainLobeXRange = DataStruct(iObject).MainLobeXRange;
    ObjectDataZMaxY = DataStruct(iObject).DataZMaxY;
    ObjectMaxXIndex = DataStruct(iObject).MaxXIndex;
    DataX = DataStruct(iObject).DataX;
    
    %将主瓣与X轴围成的面积填入串扰矩阵的对角线位置
    CrossTalkMat(iObject, iObject) = DataStruct(iObject).MainLobeArea;
    
    %其余波形则被视为干涉波形
    for iInterference = setdiff(1:numel(DataStruct),iObject)
        
        %取出干涉波形最大值所在行数据InterferenceDataZMaxY和最大值所在的列索引InterferenceMaxXIndexMaxXIndex
        InterferenceDataZMaxY =  DataStruct(iInterference).DataZMaxY;
        InterferenceMaxXIndex = DataStruct(iInterference).MaxXIndex;
        
        %求目标（Object）和干涉波形（Interference）的相交点
        %先求二者的差异波
        DiffDataZMaxY = ObjectDataZMaxY - InterferenceDataZMaxY;
        %求差异波的错位相乘（后1项乘前1项）波形
        DislocationProduct = DiffDataZMaxY(2:end) .* DiffDataZMaxY(1:end-1);
        
        %错位相乘小于等于0的点便是目标和干涉波形的相交点
        IntersectionXIndex = find(DislocationProduct <= 0);
        
%         %调试所用语句，用于绘制目标波形和干涉波形
%         figure(iObject*10+iInterference);
%         plot(ObjectDataZMaxY,'k');
%         hold on;
%         plot(InterferenceDataZMaxY,'b');
        
        %只考虑在干涉波形与目标波形主瓣范围内的交点
        IntersectionXIndex = IntersectionXIndex(IntersectionXIndex>=ObjectMainLobeXRange(1) &...
            IntersectionXIndex<=ObjectMainLobeXRange(2));
        
        %对交点横坐标从左到右进行排序
        IntersectionXIndex = sort(IntersectionXIndex,'ascend');
       
        
        %如果干扰波和目标主瓣没有交点
        if isempty(IntersectionXIndex)
            %此部分积分值为0
            CrossTalkMat(iObject, iInterference) = 0;
            
        else
            %若交点全部位于干扰波峰值左侧
            if all(IntersectionXIndex <= InterferenceMaxXIndex)
                %将积分限设置为从主瓣左侧到最靠右的那个交点
                IntegralLimit = [ObjectMainLobeXRange(1),IntersectionXIndex(end)];
                
            %若交点全部位于干扰波峰值右侧
            elseif all(IntersectionXIndex > InterferenceMaxXIndex)
                %将积分限设置为最靠左的那个交点到主瓣右侧
                IntegralLimit = [IntersectionXIndex(1),ObjectMainLobeXRange(2)];
                
             %若交点同时存在于干扰波峰值的左侧和右侧
            else
                %将积分限设置为最左侧的交点到最右侧的交点
                IntegralLimit = [IntersectionXIndex(1),IntersectionXIndex(2)];
                
            end
            %如果积分上下限重叠
            if IntegralLimit(1) == IntegralLimit(2)
                %计算X轴每一个刻度间隔
                XGap = abs(DataX(IntegralLimit(1)) -  DataX(IntegralLimit(1)+1));
                %用一半刻度长度乘以幅值作为面积
                CrossTalkMat(iObject, iInterference) = XGap/2 * InterferenceDataZMaxY(IntegralLimit(1));
            %否则使用trapz计算积分值
            else
            %对干涉波形在积分限内进行积分，并存入串扰矩阵的相应位置
            CrossTalkMat(iObject, iInterference) = abs(trapz(DataX(IntegralLimit(1):IntegralLimit(2)),...
                InterferenceDataZMaxY(IntegralLimit(1):IntegralLimit(2))));
            end
        end
        
    end
    
    %往数据结构体DataStruct中放入串扰计算的结果（包括干涉波形和目标波形与X轴围成的面积以及干涉波形对目标波形的串扰值）
    %取出串扰矩阵中与目标波形对应的那一行
    DataStruct(iObject).InterferenceArea = CrossTalkMat(iObject,:);
    %去掉其中的目标波形与X轴围成面积的那一项（已存于MainLobeArea域中）
    DataStruct(iObject).InterferenceArea(iObject) = NaN;
    %计算干涉波形对目标波形总的串扰值
    DataStruct(iObject).CrossTalk = sum(DataStruct(iObject).InterferenceArea,'omitnan')/DataStruct(iObject).MainLobeArea;
end

%% 进行数据存储和显示
%生成结构体数组存储文件路径
AllDataStructPath = fullfile(DataDirectory,'AllDataStruct.mat');
%存储DataStruct
save(AllDataStructPath,'DataStruct','-mat');

%生成串扰表格
CrossTalkTable = table;
%生成串扰表格第一列
CrossTalkTable.SourceLabel = {DataStruct.SourceLabel}';
%生成串扰表格每一个目标波形所对应的列
for iSource = 1:numel(DataStruct)
    CrossTalkTable.(DataStruct(iSource).SourceLabel) = CrossTalkMat(:,iSource);
end
%生成所有干涉波形对目标波形的总串扰值的列
CrossTalkTable.CrossTalk = [DataStruct.CrossTalk]';
%生成串扰矩阵存储文件路径
CrossTalkTablePath = fullfile(DataDirectory,'CrossTalkTable.mat');
%存储串扰矩阵
save(CrossTalkTablePath,'CrossTalkTable','-mat');
%显示串扰矩阵
open CrossTalkTable;
