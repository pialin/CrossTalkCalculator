%�˺�������Ѱ��һ���ı��ļ��з���ĳһ�������к�
%���������
%FilePath - �ı��ļ�·��
%PatternRegExp - ����������(����textscan��Ҫ�����)
%��������
%MatchLineNumber������ƥ���е��кţ���û��ƥ������򷵻�-1
%MatchDataCell������ƥ���е���Ӧ���ݣ���û��ƥ������򷵻�{}
function [MatchDataCell,MatchLineNumber] =  FindFirstPatternInTextFile(FilePath, Pattern)

%���ı��ļ����FileId
TextFileId = fopen(FilePath,'r');

%��ȡ�ı��ļ���1��
LineTemp = fgets(TextFileId);
%LineNumber���ڼ�¼��ǰ�к�
LineNumber = 1;

% %IsMatch���ڴ洢�Ƿ����ĳһ�����������Pattern��ƥ�䣬��ʼֵΪfalse
% IsMatch = false;

%�����ļ������У�ischar(LineTemp)�ж��ı��ļ��Ƿ��Ѿ�����
while  ischar(LineTemp)
    
    %�жϵ�ǰ���Ƿ����������ƥ��
    MatchDataCell = textscan(LineTemp, Pattern, 1);
    IsMatch = ~isempty(MatchDataCell{1});
    
    if IsMatch
        %���ƥ�����¼�����кź��ı�����
        MatchLineNumber = LineNumber;
        
        %��������
        break;
    end
    
    %��ȡ�ı��ļ�����һ��
    LineTemp = fgets(TextFileId);
    %�����кż�1
    LineNumber = LineNumber + 1;
end

%���û�г���ƥ�����
if ~IsMatch
    %��MatchLineNumber��Ϊ-1����MatchDataCell��Ϊ{}����δ�ҵ�ƥ�����
    MatchLineNumber = -1;
    MatchDataCell = {};
end

%�رմ򿪵��ļ�
fclose(TextFileId);
end