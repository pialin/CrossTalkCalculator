%��������ɴ��ż��㣬�ű���������ѡ���ļ����е���չ��Ϊtxt�������ļ���������Ϊһ�鲨�Σ������ڲ��μ���⴮��
%�ű����ս�����ѡĿ¼�����һ��'AllDataStruct.mat'�ļ����ڱ����������в��ε�������ݣ�
%�����һ��'CrossTalkTable.mat'��Ϊ���ż���Ľ��
%���Ի�����Windows8.1(x64) MatlabR2016b(x64)

%��ձ����ռ�
clear;

%% �û�ѡ�����������ļ���

%���öԻ������
DialogTitle = '��ѡ�����������ļ���';

%����Ĭ��ѡ�е��ļ���
%�������Ĭ���ļ��еı����ļ�������(��һ�����г���)���򽫵�ǰ�ļ����趨ΪĬ��ѡ�е��ļ���
if ~exist('DefaultDataDirectory.mat','file')
    DefaultDataDirectory = pwd;
    %�������Ĭ���ļ��еı����ļ����ڣ��򽫶�ȡ����·����ΪĬ��ѡ�е��ļ���
else
    load('DefaultDataDirectory.mat');
end

%�����ļ���ѡ��Ի���
DataDirectory = uigetdir(DefaultDataDirectory,DialogTitle);

%�������ġ�ȡ������������ʱ���ص��ļ���·��Ϊ0�����˳��ű��������������
if DataDirectory == 0
    %��ʾ�˳���ʾ��Ϣ
    warning('û��ѡ���κ������ļ��У������˳�');
    
    %�������нű�
    return;
end

%���Ĭ��ѡ����ļ���λ�÷����˸ı䣬��Ĭ�ϵ��ļ��и���Ϊ�ϴ�ѡ�е��ļ��е���һ���ļ���(Ϊ�˱���ѡ����һ���ļ���)
%���洢��DefaultDataDirectory.mat֮��
DataDirectoryUpperFolderPath = fileparts(DataDirectory);
if ~strcmp(DefaultDataDirectory, DataDirectoryUpperFolderPath)
    DefaultDataDirectory = DataDirectoryUpperFolderPath;
    save('DefaultDataDirectory.mat','DefaultDataDirectory');
end

%���ò������ýű������û��趨�Ĳ���
CrossTalkCalculatorSetting;

%% ��ȡ�����ļ���������ж�ȡ


%���������ļ�����ѡ���������ʾ��������չ��Ϊtxt���ļ���Ϊ�����ļ�
DataFileFilter = '*.txt';

%��ù��˺�������ļ��б�DataFileList
DataFileList = dir(fullfile(DataDirectory,DataFileFilter));

%��ȡ�����ļ�����
NumDataFile = numel(DataFileList);

%�½�DataStruct���ڱ����������в��ε��������:
%����SourceFilePath��¼һ�鲨�ε�������Դ�ļ�
%SourceLabelΪһ��������һ�����ƣ���'Source'����txt�ļ����ļ�����ɣ�
%DataX,DataY�ֱ��¼X���Y��Ŀ̶ȣ�DataZ��һ����ά�������ڼ�¼��ǿ����
%DataZMaxY��һ��һά���󣬼�¼DataZ���ֵ�������е�����
%MaxXIndex��MaxYIndex�ֱ��¼DataZ���ֵ���X��Y������
%MainLobeAmpThreshold���ڼ�¼ȡ����ʱѡ�õķ�ֵ��ֵ��MainLobeXRange��¼�����X�᷶Χ��MainLobeArea��ʾ���겨����X��Χ�ɵ����
DataStruct(1:NumDataFile) = struct('SourceFilePath', [] , 'SourceLabel', [],...
    'DataX', [], 'DataY', [], 'DataZ', [],...
    'DataZMaxY', [], 'MaxXIndex', [], 'MaxYIndex', [],...
    'MainLobeAmpThreshold', [], 'MainLobeXRange', [],'MainLobeArea', []);
%����ļ�����û���ҵ�txt�ļ�
if NumDataFile == 0
    %�׳���Ӧ����
    warning('ѡ���ļ������޷��ҵ�txt�����ļ�,���˳�����!');
    %�˳��ű�
    return;
end

%�������ļ��б��е�ÿ���ļ����ж�ȡ
for iDataFile = 1:NumDataFile
    
    %��ǰ���������ļ����ļ���
    DataFilePath = fullfile(DataFileList(iDataFile).folder,DataFileList(iDataFile).name);
    
    %��ȡ�ļ����ݵ�����DataFileContent��
    DataFileContent = fileread(DataFilePath);
    
    %ƥ��һ����ֵ��������ʽ
    RegExpNumber = '[\+\-]?[0-9]*\.?[0-9]+(?:[Ee][\+\-]?[0-9]+)?';
    
    %��ȡ�ı��ļ��е�GridSize��Ϣ����XY������Ŀ��
    GridSize = regexp(DataFileContent,['Grid Size is (',RegExpNumber,') x ',...
        '(',RegExpNumber,')[ \t\r\f]*\n'],'tokens');
    %���δ�ҵ�GridSize��Ϣ�򱨴�
    if isempty(GridSize)
        error(['�޷���',DataFilePath,'�ҵ�GridSize��Ϣ']);
        %����ҵ����GridSize��Ϣ
    elseif numel(GridSize) > 1
        %������沢ѡȡ���һ��Ŀ��
        warning('�ҵ�����1��GridSize��Ϣ������һ���������ں�������');
        GridSize = GridSize(end);
    end
    %������ҵ�GridSize��Ϣ����һ����ȡX��Y�᷽���GridSize��regexp��ȡ����Ϣ���ַ������͵ģ���Ҫת������ֵ�ͣ�
    GridSizeY =  str2double(GridSize{1}{1});
    GridSizeX =  str2double(GridSize{1}{2});
    
    %��ȡ�����ļ��е�4���߽ǵ�����
    CornerXY = regexp(DataFileContent,['Corners of Data Set \(plotted\)[ \t\r\f]*\n',...
        repmat(['[ \t]*(\w+):\((',RegExpNumber,'),(',RegExpNumber,'),',RegExpNumber,'\)[ \t\r\f]*\n'],[1,4])],...
        'tokens');
    %���δ�ҵ��߽�������Ϣ�򱨴�
    if isempty(CornerXY)
        error(['�޷���',DataFilePath,'�ҵ��߽�������Ϣ']);
        %����ҵ�����߽�������Ϣ
    elseif numel(CornerXY) > 1
        %������沢ѡȡ���һ��Ŀ��
        warning('�ҵ�����1���߽�������Ϣ������һ���������ں�������');
        CornerXY = CornerXY(end);
    end
    %������ҵ��߽�������Ϣ������ȡ��token����reshape���ڹ۲����һ������
    CornerXY = reshape(CornerXY{1},3,[])';
    %�ֱ��ȡ�ı��ļ��е�4���ǵ�����
    for iCorner = 1:size(CornerXY,1)
        switch  lower(CornerXY{iCorner,1})
            %���Ͻ�����
            case 'topleft'
                TopLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
                %���Ͻ�����
            case 'topright'
                TopRightCornerXY =  str2double(CornerXY(iCorner,2:3));
                %���½�����
            case 'bottomleft'
                BottomLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
                %���½�����
            case 'bottomright'
                BottomRightCornerXY =  str2double(CornerXY(iCorner,2:3));
                %δ֪�߽�������Ϣ����
            otherwise
                error(['δ֪�ı߽�������Ϣ:',CornerXY{iCorner,1},'(',CornerXY{iCorner,2},',',CornerXY{iCorner,3},')']);
        end
    end
    
    %�ж��Ƿ�õ���ȫ��4��������
    if ~(exist('TopLeftCornerXY','var') && exist('TopRightCornerXY','var') &&...
            exist('BottomLeftCornerXY','var') && exist('BottomRightCornerXY','var'))
        %���û�еõ�ȫ��4���ǵ�����,���׳���Ӧ����
        error('�޷��õ�ȫ��4���ǵ�����!');
    end
    
    %����4���߽ǵ���������ά����XY��̶�
    DataX = linspace(TopLeftCornerXY(1),TopRightCornerXY(1),GridSizeX);
    DataY = linspace(TopLeftCornerXY(2),BottomLeftCornerXY(2),GridSizeY);
    
    %��ȡ�ı��ļ��еĶ�ά���ݾ���
    DataZ = regexp(DataFileContent,[repmat(['(',RegExpNumber,')\t'],[1,GridSizeX]),'[ \t\r\f]*\n'],'tokens');
    
    %�����ݴ��ַ���cell����ת������ֵ�;���(ע�⣺����Ϊ�˱��ں͸�ͼ��Աȶ�����ת��)
    DataZ = reshape(str2double([DataZ{:}]),GridSizeY,[])';
    
    %���õ��Ķ�ά����ߴ���GridSizeָ���Ĳ�һ��ʱ�׳�����
    if any(size(DataZ) ~= [GridSizeY, GridSizeX])
        error('�õ��Ķ�ά����ߴ���GridSizeָ���Ĳ�һ��!');
    end
    
    %��ȡԴ�ļ����ļ�����ΪԴ���ƣ���'Source'����txt�ļ�����ɣ�
    [~ , SourceIndex, ~] = fileparts(DataFilePath);
    SourceLabel = ['Source',SourceIndex];
    
    %��ȡDataZ���ֵ�����Ӧ��Z����
    [MaxZValue, MaxZIndex] = max(DataZ(:));
    %��Z����ת��ΪXY������
    [MaxYIndex, MaxXIndex] = ind2sub(size(DataZ), MaxZIndex);
    
    %ȡ�����ֵ�����е�����
    DataZMaxY = DataZ(MaxYIndex,:);
    
    %����������ֵ���������Ķ�ӦX�᷶Χ
    UnderThresholdXIndex = find(DataZMaxY<=MainLobeAmpThreshold);
    %�����ֵ���û��С����ֵ�ĵ㣬�������������Ϊ���������ʼ��
    MainLobeXLeftRange =  max([UnderThresholdXIndex((UnderThresholdXIndex-MaxXIndex)<0),1]);
    %�����ֵ�Ҳ�û��С����ֵ�ĵ㣬���������Ҷ���Ϊ�����Ҳ������
    MainLobeXRightRange =  min([UnderThresholdXIndex((UnderThresholdXIndex-MaxXIndex)>=0),numel(DataZMaxY)]);
    %�����Ҳ�����MainLobeXRange��
    MainLobeXRange = [MainLobeXLeftRange,MainLobeXRightRange];
    %���㲨��������X��Χ�ɵ����
    MainLobeArea = abs(trapz(DataX(MainLobeXRange(1):MainLobeXRange(2)),...
        DataZMaxY(MainLobeXRange(1):MainLobeXRange(2))));
    
    
    %���õ�����Ϣ����ṹ������֮��
    DataStruct(iDataFile) = struct('SourceFilePath', DataFilePath , 'SourceLabel', SourceLabel,...
        'DataX', DataX, 'DataY', DataY, 'DataZ', DataZ,...
        'DataZMaxY', DataZMaxY, 'MaxXIndex', MaxXIndex, 'MaxYIndex', MaxYIndex,...
        'MainLobeAmpThreshold', MainLobeAmpThreshold, 'MainLobeXRange', MainLobeXRange,'MainLobeArea',MainLobeArea);
    
end


%����һ���������ڴ���������в����໥֮��Ĵ���ֵ
CrossTalkMat = NaN(numel(DataStruct));
%% ����ȡ���ṹ������ݽ��д���
%��ȡһ��Ŀ�겨��
for iObject = 1:numel(DataStruct)
    %ȡ��Ŀ�겨�ε�����X�᷶ΧObjectMainLobeXRange�����ֵ����������ObjectDataZMaxY��
    %���ֵ���ڵ�������ObjectMaxXIndex�Լ�X��Ŀ̶�DataX
    ObjectMainLobeXRange = DataStruct(iObject).MainLobeXRange;
    ObjectDataZMaxY = DataStruct(iObject).DataZMaxY;
    ObjectMaxXIndex = DataStruct(iObject).MaxXIndex;
    DataX = DataStruct(iObject).DataX;
    
    %��������X��Χ�ɵ�������봮�ž���ĶԽ���λ��
    CrossTalkMat(iObject, iObject) = DataStruct(iObject).MainLobeArea;
    
    %���ನ������Ϊ���沨��
    for iInterference = setdiff(1:numel(DataStruct),iObject)
        
        %ȡ�����沨�����ֵ����������InterferenceDataZMaxY�����ֵ���ڵ�������InterferenceMaxXIndexMaxXIndex
        InterferenceDataZMaxY =  DataStruct(iInterference).DataZMaxY;
        InterferenceMaxXIndex = DataStruct(iInterference).MaxXIndex;
        
        %��Ŀ�꣨Object���͸��沨�Σ�Interference�����ཻ��
        %������ߵĲ��첨
        DiffDataZMaxY = ObjectDataZMaxY - InterferenceDataZMaxY;
        %����첨�Ĵ�λ��ˣ���1���ǰ1�����
        DislocationProduct = DiffDataZMaxY(2:end) .* DiffDataZMaxY(1:end-1);
        
        %��λ���С�ڵ���0�ĵ����Ŀ��͸��沨�ε��ཻ��
        IntersectionXIndex = find(DislocationProduct <= 0);
        
%         %����������䣬���ڻ���Ŀ�겨�κ͸��沨��
%         figure(iObject*10+iInterference);
%         plot(ObjectDataZMaxY,'k');
%         hold on;
%         plot(InterferenceDataZMaxY,'b');
        
        %ֻ�����ڸ��沨����Ŀ�겨�����귶Χ�ڵĽ���
        IntersectionXIndex = IntersectionXIndex(IntersectionXIndex>=ObjectMainLobeXRange(1) &...
            IntersectionXIndex<=ObjectMainLobeXRange(2));
        
        %�Խ������������ҽ�������
        IntersectionXIndex = sort(IntersectionXIndex,'ascend');
       
        
        %������Ų���Ŀ������û�н���
        if isempty(IntersectionXIndex)
            %�˲��ֻ���ֵΪ0
            CrossTalkMat(iObject, iInterference) = 0;
            
        else
            %������ȫ��λ�ڸ��Ų���ֵ���
            if all(IntersectionXIndex <= InterferenceMaxXIndex)
                %������������Ϊ��������ൽ��ҵ��Ǹ�����
                IntegralLimit = [ObjectMainLobeXRange(1),IntersectionXIndex(end)];
                
            %������ȫ��λ�ڸ��Ų���ֵ�Ҳ�
            elseif all(IntersectionXIndex > InterferenceMaxXIndex)
                %������������Ϊ�����Ǹ����㵽�����Ҳ�
                IntegralLimit = [IntersectionXIndex(1),ObjectMainLobeXRange(2)];
                
             %������ͬʱ�����ڸ��Ų���ֵ�������Ҳ�
            else
                %������������Ϊ�����Ľ��㵽���Ҳ�Ľ���
                IntegralLimit = [IntersectionXIndex(1),IntersectionXIndex(2)];
                
            end
            %��������������ص�
            if IntegralLimit(1) == IntegralLimit(2)
                %����X��ÿһ���̶ȼ��
                XGap = abs(DataX(IntegralLimit(1)) -  DataX(IntegralLimit(1)+1));
                %��һ��̶ȳ��ȳ��Է�ֵ��Ϊ���
                CrossTalkMat(iObject, iInterference) = XGap/2 * InterferenceDataZMaxY(IntegralLimit(1));
            %����ʹ��trapz�������ֵ
            else
            %�Ը��沨���ڻ������ڽ��л��֣������봮�ž������Ӧλ��
            CrossTalkMat(iObject, iInterference) = abs(trapz(DataX(IntegralLimit(1):IntegralLimit(2)),...
                InterferenceDataZMaxY(IntegralLimit(1):IntegralLimit(2))));
            end
        end
        
    end
    
    %�����ݽṹ��DataStruct�з��봮�ż���Ľ�����������沨�κ�Ŀ�겨����X��Χ�ɵ�����Լ����沨�ζ�Ŀ�겨�εĴ���ֵ��
    %ȡ�����ž�������Ŀ�겨�ζ�Ӧ����һ��
    DataStruct(iObject).InterferenceArea = CrossTalkMat(iObject,:);
    %ȥ�����е�Ŀ�겨����X��Χ���������һ��Ѵ���MainLobeArea���У�
    DataStruct(iObject).InterferenceArea(iObject) = NaN;
    %������沨�ζ�Ŀ�겨���ܵĴ���ֵ
    DataStruct(iObject).CrossTalk = sum(DataStruct(iObject).InterferenceArea,'omitnan')/DataStruct(iObject).MainLobeArea;
end

%% �������ݴ洢����ʾ
%���ɽṹ������洢�ļ�·��
AllDataStructPath = fullfile(DataDirectory,'AllDataStruct.mat');
%�洢DataStruct
save(AllDataStructPath,'DataStruct','-mat');

%���ɴ��ű��
CrossTalkTable = table;
%���ɴ��ű���һ��
CrossTalkTable.SourceLabel = {DataStruct.SourceLabel}';
%���ɴ��ű��ÿһ��Ŀ�겨������Ӧ����
for iSource = 1:numel(DataStruct)
    CrossTalkTable.(DataStruct(iSource).SourceLabel) = CrossTalkMat(:,iSource);
end
%�������и��沨�ζ�Ŀ�겨�ε��ܴ���ֵ����
CrossTalkTable.CrossTalk = [DataStruct.CrossTalk]';
%���ɴ��ž���洢�ļ�·��
CrossTalkTablePath = fullfile(DataDirectory,'CrossTalkTable.mat');
%�洢���ž���
save(CrossTalkTablePath,'CrossTalkTable','-mat');
%��ʾ���ž���
open CrossTalkTable;
