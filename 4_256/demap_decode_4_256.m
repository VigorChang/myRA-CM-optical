function estimateInfo=demap_decode_4_256(receivedQAM,G,turboInterleaver,QAMInterleaver,X,pX,numDemapIteration,numDecodeIteration)
%Demapper and decoder
%% Basic Parameter
%Table, 1 for 1, 0 for 0, 2 for ambiguities
bitTable=[1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0;
          0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0;
          0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0;
          0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0];
inf=1e10;

%% First Demap
%First demap iteration, give out the first LLR, without the a piror
%information
firstLLR1_WithoutAPP=zeros(length(receivedQAM)*4,16);
firstLLR0_WithoutAPP=zeros(length(receivedQAM)*4,16);
%First demap
for i=1:1:length(receivedQAM)
    tempQAM=receivedQAM(i);
    %For real part
    for k=1:1:4
        for j=1:1:16
            if bitTable(k,j)==1
                firstLLR1_WithoutAPP(((i-1)*4+k),j)=1/(-2)*(tempQAM-X(j))^2;
                firstLLR0_WithoutAPP(((i-1)*4+k),j)=-inf;
            end
            if bitTable(k,j)==0
                firstLLR0_WithoutAPP(((i-1)*4+k),j)=1/(-2)*(tempQAM-X(j))^2;
                firstLLR1_WithoutAPP(((i-1)*4+k),j)=-inf;
            end
        end
    end
end

%% Demap and Decode
%Turbo code length
turboL=length(turboInterleaver);
% At first, assume the L_M_a is all zero, and set all of other L values
L_M_a=zeros(1,length(receivedQAM)*4);

% L_M_p=soft_demapper_4_256(L_M_a,firstLLR1_WithoutAPP,firstLLR0_WithoutAPP);
% L_D_p=deinterleaver_depuncture_4_256(L_M_p,QAMInterleaver,turboLength);

for itDemap=1:1:numDemapIteration
    %Demapper, give out the L_M_p
    L_M_p=soft_demapper_4_256(L_M_a,firstLLR1_WithoutAPP,firstLLR0_WithoutAPP);
    %Get L_M_e
    L_M_e=L_M_p-L_M_a;
    %Deinterleaver and depuncture
    L_D_a=deinterleaver_depuncture_4_256(L_M_e,QAMInterleaver,turboL);
    L_D_a=limit_number(L_D_a);
    %Turbo decoder
    L_D_p=turbo_decoder(L_D_a,turboInterleaver,G,numDecodeIteration);
    L_D_p=limit_number(L_D_p);
    L_D_e=L_D_p-L_D_a;
    %QAM interleaver and puncture
    L_M_a=interleaver_puncture_4_256(L_D_e,QAMInterleaver);
    tempLMp=L_M_p;
end

%Give out the estimation info
tempLDp=L_D_p(1,:);
tempLDp=(sign(tempLDp)+1)/2;
estimateInfo=tempLDp(1,1:4996);



end

