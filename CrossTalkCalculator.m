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
   
    %��ȡ�ı��ļ��е�GridSize��Ϣ����XY������Ŀ��
    GridSize = FindFirstPatternInTextFile(DataFilePath,'Grid Size is %d x %d %*[^\n]');
    %���δ�ҵ�GridSize��Ϣ�򱨴�
    if isempty(GridSize)
        error(['�޷���',DataFilePath,'�ҵ�GridSize��Ϣ']);
    end
    %������ҵ�GridSize��Ϣ����һ����ȡX��Y�᷽���GridSize
    GridSizeX =  GridSize{1};
    GridSizeY =  GridSize{2};
        
    %��ȡ�ı��ļ��е�DataCell��С��Ϣ����ÿ��С��ĳ���ߴ磩
    DataCell = FindFirstPatternInTextFile(DataFilePath,'Data Cells are %f64 x %f64 %*[^\n]');
    %���δ�ҵ�DataCell��Ϣ�򱨴�
    if isempty(DataCell)
        error(['�޷���',DataFilePath,'�ҵ�DataCell��Ϣ']);
    end
    %������ҵ�DataCell��Ϣ����һ����ȡX��Y�᷽���DataCell
    DataCellX =  DataCell{1};
    DataCellY =  DataCell{2};
    
    %��ȡ�ı��ļ��е�4���ǵ�����
    [~,DataCornerStartLine] = FindFirstPatternInTextFile(DataFilePath,'Corners of Data Set (plotted)%[^\n]');
    %���δ�ҵ�4���ǵ������򱨴�
    if DataCornerStartLine == -1
        error(['�޷���',DataFilePath,'�ҵ�4��������']);
    end
    
    %�������ļ�
    DataFileId = fopen(DataFilePath);
    
    DataCornerText = textscan(DataFileId,'%[^\n]',4,...
        'HeaderLines', DataCornerStartLine, 'CollectOutput', 1);
    
    DataCornerText = [DataCornerText{1}{:}];
    
    TopLeft = textscan(DataFileId,'TopLeft:(%f64,%f64 %*[^\n]',1,...
        'HeaderLines', DataCornerStartLine, 'CollectOutput', 1);
    
    
    %�������ݵ�Xֵ��Yֵ
    DataX = double(0:GridSizeX-1) * DataCellX;
    DataY = double(0:GridSizeY-1) * DataCellY;
    
    %��ȡ�ı��ļ��еĶ�ά���ݾ���
    [~,MatDataStartLine] = FindFirstPatternInTextFile(DataFilePath,[repmat('%f64\t',[1,GridSizeX]),'%*[^\n]']);
    %���δ�ҵ���ά���ݾ����򱨴�
    if MatDataStartLine == -1
        error(['�޷���',DataFilePath,'�ҵ���ά��������']);
    end
    
    %���½�����λ�����õ��ļ���ͷ����Ϊ��һ�ε�textscan��Ķ�ָ��λ�ã�
    frewind(DataFileId);
    
    %��������õ���ά����ʼ��������ȡ��ά��������
    MatDataCell = textscan(DataFileId,[repmat('%f64 ',[1,GridSizeX]),'%*[^\n]'],...
        'HeaderLines', MatDataStartLine - 1, 'CollectOutput', 1);
    
    %�رմ򿪵������ļ�
    fclose(DataFileId);
    
    %����ά����������cell����ת��Ϊ��������
    DataZ = cell2mat(MatDataCell);
    
    %���õ��Ķ�ά����ߴ���GridSizeָ���Ĳ�һ��ʱ��ʾ����
    if any(size(DataZ) ~= [GridSizeX, GridSizeY]) 
        error('�õ��Ķ�ά����ߴ���GridSizeָ���Ĳ�һ��!');
    end
    
    %��ȡԴ�ļ����ļ�����ΪԴ����
    [~ , SourceType, ~] = fileparts(DataFilePath);
    
    %����Ҫ����Ϣ����ṹ������֮��
    DataStruct(iDataFile) = struct('SourceFilePath', DataFilePath , 'SourceType', SourceType,...
        'DataX', DataX, 'DataY', DataY, 'DataZ', DataZ);
    
end
save(fullfile(DataDirectory,'AllData.mat'),'DataStruct');


%% ����ȡ���ṹ������ݽ��д���
[MaxZValue,MaxZIndex] = max(DataStruct(1).DataZ(:));
[MaxYIndex, MaxXIndex] = ind2sub(size(DataStruct(1).DataZ),MaxZIndex);
DataZMaxY = DataStruct(1).DataZ(MaxYIndex,:);

for iDataFile = 1:NumDataFile
    
    

end

filecontent = fileread('test.txt');
% result = regexp(filecontent,'Grid Size is ([0-9]*\.?[0-9]+) x ([0-9]*\.?[0-9]+)','tokens');

