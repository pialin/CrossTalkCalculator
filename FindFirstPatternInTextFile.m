%此函数用于寻找一个文本文件中符合某一特征的行号
%输入参数：
%FilePath - 文本文件路径
%PatternRegExp - 搜索的特征(根据textscan的要求给定)
%输出结果：
%MatchLineNumber：返回匹配行的行号，若没有匹配的行则返回-1
%MatchDataCell：返回匹配行的相应数据，若没有匹配的行则返回{}
function [MatchDataCell,MatchLineNumber] =  FindFirstPatternInTextFile(FilePath, Pattern)

%打开文本文件获得FileId
TextFileId = fopen(FilePath,'r');

%读取文本文件第1行
LineTemp = fgets(TextFileId);
%LineNumber用于记录当前行号
LineNumber = 1;

% %IsMatch用于存储是否存在某一行与给定特征Pattern相匹配，初始值为false
% IsMatch = false;

%遍历文件所有行，ischar(LineTemp)判断文本文件是否已经结束
while  ischar(LineTemp)
    
    %判断当前行是否与给定特征匹配
    MatchDataCell = textscan(LineTemp, Pattern, 1);
    IsMatch = ~isempty(MatchDataCell{1});
    
    if IsMatch
        %如果匹配则记录所在行号和文本内容
        MatchLineNumber = LineNumber;
        
        %结束遍历
        break;
    end
    
    %读取文本文件的下一行
    LineTemp = fgets(TextFileId);
    %并且行号加1
    LineNumber = LineNumber + 1;
end

%如果没有出现匹配的行
if ~IsMatch
    %将MatchLineNumber设为-1并将MatchDataCell设为{}表明未找到匹配的行
    MatchLineNumber = -1;
    MatchDataCell = {};
end

%关闭打开的文件
fclose(TextFileId);
end