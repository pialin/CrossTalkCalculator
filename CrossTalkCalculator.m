%��������ɴ��ż���
%���Ի�����Windows8.1(x64) MatlabR2016b(x64)
%�޸ļ�¼��
%   1.

%��ձ����ռ�
clear;

%% ѡ�����������ļ���

%���öԻ������
DialogTitle = '��ѡ�����������ļ���';

%����Ĭ��ѡ�е��ļ���
%���Ĭ���ļ���δ���趨(��������һ�����г���)�������趨Ϊ��ǰ·��
if ~exist('DefaultDataDirectory.mat','file')
    DefaultDataDirectory = pwd;
else
    load('DefaultDataDirectory.mat');
end

%�����ļ���ѡ��Ի���
DataDirectory = uigetdir(DefaultDataDirectory,DialogTitle);

%�������ġ�ȡ������������ʱ���ص��ļ���·��Ϊ0�����˳��ű�
if DataDirectory == 0 
    %��ʾ�˳���ʾ��Ϣ
    warning('û��ѡ���κ������ļ��У������˳�');
    
    %�������нű�
    return;
end

%���Ĭ��ѡ����ļ���λ�÷����˸ı䣬��Ĭ�ϵ��ļ��и���Ϊ�ϴ�ѡ�е��ļ���
if ~strcmp(DefaultDataDirectory, DataDirectory)
    DefaultDataDirectory = DataDirectory;
    save('DefaultDataDirectory.mat','DefaultDataDirectory');
end

%% ��ȡ�����ļ���������ж�ȡ 

%���������ļ�����ѡ���������ʾ��������չ��Ϊtxt���ļ���Ϊ�����ļ�
DataFileFilter = '*.txt';

%��ù��˺�������ļ��б�DataFileList
DataFileList = dir(fullfile(DataDirectory,DataFileFilter));

%��ȡ�����ļ�����
NumDataFile = numel(DataFileList);

DataStruct(1:NumDataFile) = struct('SourceFilePath', [], 'SourceType', [],...
    'DataX', [], 'DataY', [], 'DataZ', []);

%�������ļ��б��е�ÿ���ļ����ж�ȡ
for iDataFile = 1:NumDataFile
    
    %��ǰ���������ļ����ļ���
    DataFilePath = fullfile(DataFileList(iDataFile).folder,DataFileList(iDataFile).name);
   
    %��ȡ�ļ�����
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
            case 'topleft'
                TopLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
            case 'topright'
                TopRightCornerXY =  str2double(CornerXY(iCorner,2:3));
            case 'bottomleft'
                BottomLeftCornerXY =  str2double(CornerXY(iCorner,2:3));
            case 'bottomright'
                BottomRightCornerXY =  str2double(CornerXY(iCorner,2:3));
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
    
    %�����ά����XY����
    DataX = linspace(TopLeftCornerXY(1),TopRightCornerXY(1),GridSizeX);
    DataY = linspace(TopLeftCornerXY(2),BottomLeftCornerXY(2),GridSizeY);
    
    %��ȡ�ı��ļ��еĶ�ά���ݾ���
    DataZ = regexp(DataFileContent,[repmat(['(',RegExpNumber,')\t'],[1,GridSizeX]),'[ \t\r\f]*\n'],'tokens');
    %�����ݴ��ַ���cell����ת������ֵ�;���
    DataZ = reshape(str2double([DataZ{:}]),GridSizeY,[]);
    
    %���õ��Ķ�ά����ߴ���GridSizeָ���Ĳ�һ��ʱ��ʾ����
    if any(size(DataZ) ~= [GridSizeY, GridSizeX]) 
        error('�õ��Ķ�ά����ߴ���GridSizeָ���Ĳ�һ��!');
    end
    
    %��ȡԴ�ļ����ļ�����ΪԴ����
    [~ , SourceType, ~] = fileparts(DataFilePath);
    
    %����Ҫ����Ϣ����ṹ������֮��
    DataStruct(iDataFile) = struct('SourceFilePath', DataFilePath , 'SourceType', SourceType,...
        'DataX', DataX, 'DataY', DataY, 'DataZ', DataZ);
    
end
%���õ��Ľṹ�������ΪMat�ļ�
%���ɴ洢�ļ�·��
AllDataMatPath = fullfile(DataDirectory,'AllData.mat');
%����Ƿ��ļ��Ƿ��Ѿ�����
if exist(AllDataMatPath,'file')
    %����ļ��Ѿ����ڣ������Ի���ѯ���Ƿ��滻��ԭ���ļ�
    RepalceDataMatOrNot = questdlg(['''',AllDataMatPath,'''�Ѿ����ڣ��Ƿ��滻����'], ...
	'�ļ��滻ȷ��', ...
	'��','���뱣��ԭ���ļ�','��ֹ����','���뱣��ԭ���ļ�');
end
%����ļ������ڣ���ֱ�ӱ����ļ�
if ~exist('RepalceDataMatOrNot','var') 
    save(AllDataMatPath,'DataStruct','-mat');
%����ļ����ڣ����û�ѡ�����滻��������ļ��滻,
elseif strcmp(RepalceDataMatOrNot,'��') 
    save(AllDataMatPath,'DataStruct','-mat');
    %���������д��������ʾ��Ϣ
    disp(['Info:''',AllDataMatPath,'''�ѱ�����']);
elseif isempty(RepalceDataMatOrNot) || strcmp(RepalceDataMatOrNot,'��ֹ����')
    %��ֹ����
    return;
end


%% ����ȡ���ṹ������ݽ��д���
[MaxZValue, MaxZIndex] = max(DataStruct(1).DataZ(:));
[MaxYIndex, MaxXIndex] = ind2sub(size(DataStruct(1).DataZ),MaxZIndex);
DataZMaxY = DataStruct(1).DataZ(MaxYIndex,:);

for iDataFile = 1:NumDataFile
    
    

end


