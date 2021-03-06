function [sentQAM,QAMInterleaver,X,pX] = mapper_14_1024(turboCode,SNR)
%Mapper for 1024-QAM, l_max is 14 (each dimension is 7)

[blockNumber,codeLength]=size(turboCode);
%7 bits per channel use
%Way of puncture and interleave:
% 1    2   3   4    5   6    7   8   9   10  11   12  13   14  15  16  17
%[a1] u11 u12 [a2] u21 u22 [a3] u31 u32 [a4] u41 u42 [a5] u51 u52 [a6] u61
%18   19  20  27
%u62 [a7] u71 u72

% 16   10   1    13   15  2   5
%[a6] [a4] [a1] [a5] u52 u11 u21
% 4    19   7    9  14   18 12
%[a2] [a7] [a3] u32 u51 u62 u42
% 3   6   8  11  17  20  21
%u12 u22 u31 u41 u61 u71 u72
QAMInterleaver=[16 10 1 13 15 2 5 4 19 7 9 14 18 12 3 6 8 11 17 20 21];

X=[-31 -29 -27 -25 -23 -21 -19 -17 -15 -13 -11 -9 -7 -5 -3 -1 ...
   1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31];
pX=[1/128 1/128 1/128 1/128 1/64 1/64 1/32 1/32 1/32 1/32 1/32 1/32 1/16 1/16 1/16 1/16 ...
    1/16 1/16 1/16 1/16 1/32 1/32 1/32 1/32 1/32 1/32 1/64 1/64 1/128 1/128 1/128 1/128];
%Calculate P
P=10.^(SNR./10);
%Calculate average power
X=X/sqrt(sum(abs(X).^2.*pX))*sqrt(P);

bitTable=[1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
          0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0;
          1 1 1 1 1 1 1 1 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1;
          1 1 1 1 1 1 0 0 0 0 1 1 1 0 0 1 1 0 0 1 1 1 0 0 0 0 1 1 1 1 1 1;
          1 1 1 1 0 0 0 1 1 0 0 1 2 2 2 2 2 2 2 2 1 0 0 1 1 0 0 0 1 1 1 1;
          1 1 0 0 0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 0 0 0 1 1;
          1 0 0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 0 0 1];

sentQAM=[];
for label=1:blockNumber
    tempTurboCode=turboCode(label,:);
    %Add 0 to turbo code
    templ=mod(length(tempTurboCode),length(QAMInterleaver));
    if templ~=0
        pp=zeros(1,length(QAMInterleaver)-templ);
        tempTurboCode=[tempTurboCode,pp];
    end
    %Reshape
    tempBinQAM=[];
    for i=1:length(QAMInterleaver):length(tempTurboCode)
        ppp=tempTurboCode(1,i:(i+length(QAMInterleaver)-1));
        tempBinQAM=[tempBinQAM;ppp];
    end
    binQAM=[];
    %Apply interleaver and puncture
    for i=1:1:(length(tempTurboCode)/length(QAMInterleaver))
        temp=tempBinQAM(i,:);
        tempInt=temp(QAMInterleaver);
        tempIntPunc=tempInt(1,1:14);
        binQAM=[binQAM;tempIntPunc];
    end
    %Map
    tempSentQAM=[];
    for i=1:1:(length(tempTurboCode)/length(QAMInterleaver))
        tempBinQAM1=binQAM(i,1:7);
        tempBinQAM2=binQAM(i,8:14);
        QAMSymbol1=qam_mapper(tempBinQAM1,X,bitTable);
        QAMSymbol2=qam_mapper(tempBinQAM2,X,bitTable);
        tempSentQAM=[tempSentQAM,QAMSymbol1,QAMSymbol2];
    end
    sentQAM=[sentQAM;tempSentQAM];
end

%Mapper
    function QAMSymbol=qam_mapper(binQAM,X,bitTable)
        if length(binQAM)~=7
            error('Binary QAM length is not equal to 7.(l_max=14,1024-QAM)');
        end
        num=0;
        for k=1:1:32
            flag=0;
            for p=1:1:7
                if (bitTable(p,k)~=2 && bitTable(p,k)~=binQAM(p))
                    flag=1;
                end
            end
            if flag==0
                QAMSymbol=X(k);
                num=num+1;
            end
        end
        if num==0
            error('Mapper, mapping is failed.');
        end
        if num>1
            error('Mapper, more than one mapping decesion.');
        end
    end

end

