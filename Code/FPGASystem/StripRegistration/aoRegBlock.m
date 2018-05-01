function [regImage,status]=aoRegBlock(refImage,desinMovies,sysPara,imagePara)
% do registration
%
% Syntax:
%    [status]=aoRegBlock(refImage,desinMovies,sysPara,imagePara)
%
% Description:
%    registration algorithm
%
%
% Inputs:
%    refImage           - Ref frame, used to registration.
%    desinMovies        - Movies after desinusoiding
%    imagePara          - Image parameters, such as size, frame number, and
%                         so on
% 
% Outputs:
%    regImage           - Ref frame, used to registration.
%    status             - Status tells if things are ok
%    
% Optional key/value pairs:
%    None.
%
% See also:

% History:
%   03/14/18  tyh


%for image_iter = 1 : 1 %imagePara.nFrames
% get the current image for registration
image_iter = 4;
curImage = desinMovies(image_iter).cdata;
nStrip = fix(imagePara.H/sysPara.stripSize);
nBlcokPerStrip = fix(imagePara.W/sysPara.blockSize);
%gen ROI image according to the sysPara.ROIx,sysPara.ROIy, Padding 0 mode.
%during debug, we can try Padding 255
RoiImage = (zeros(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W));
RoiImage = uint8(RoiImage);
RoiImage(sysPara.ROIy:(sysPara.ROIy+imagePara.H-1),...
         sysPara.ROIx:(sysPara.ROIx+imagePara.W-1))...
         = refImage ;

%  strip clssify loop
    for i = 1: nStrip    
        for j = 1 : nBlcokPerStrip
        Strip_start = 1 + (i-1)*sysPara.stripSize;
        Strip_end = i*sysPara.stripSize;
        blockStart = 1 + (j-1)*sysPara.blockSize;
        blockEnd = j*sysPara.blockSize;
        BlockData(:,:,i,j) = curImage(Strip_start:Strip_end,blockStart:blockEnd);
        end
    end %  strip loop
%  one strip register loop
%  motion estimation
for stripIdx = 1 : nStrip
    for blockIdx = 1 : nBlcokPerStrip
        curBlock = BlockData(:,:,stripIdx,blockIdx);
        searchBlockUpLeftx=1+(stripIdx-1)*sysPara.stripSize+sysPara.ROIx;
        searchBlockUpLefty=1+sysPara.ROIy+(blockIdx-1)*sysPara.blockSize;
        meResult = 2^16;
        for dx = -sysPara.ROIx : sysPara.ROIx
            for dy = -sysPara.ROIy : sysPara.ROIy
                % ssad
                %gen ref strip
                searchStripStartx = dx+searchBlockUpLeftx;
                searchStripStarty = dy+searchBlockUpLefty;
                
                searchStrip = RoiImage(searchBlockUpLeftx:...
                    (searchBlockUpLeftx+sysPara.stripSize-1),...
                    searchBlockUpLefty:...
                    (searchBlockUpLefty+sysPara.blockSize-1));
                %calculate the matching process
                searchResult=aoRegMatch(searchStrip,curBlock)*2^8;
                %compare the results to get the best matching and save the
                %result
                if (searchResult<meResult)
                    meResult = searchResult;
                    meStrip(stripIdx,blockIdx).result = meResult;
                    meStrip(stripIdx,blockIdx).dx = dx;
                    meStrip(stripIdx,blockIdx).dy = dy;
                end
                
            end
        end
    end
end
%restore the registered image from the motion estimation
regImage = uint8((zeros(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W)));
for stripIdx = 1 : nStrip
    for blockIdx = 1 : nBlcokPerStrip
    %calculate the up left point of the strip
    searchStripUpLeftx=1+(stripIdx-1)*sysPara.stripSize+sysPara.ROIx;
    searchStripUpLefty=1+sysPara.ROIy+(blockIdx-1)*sysPara.blockSize;
    
    regBlockStartx=meStrip(stripIdx,blockIdx).dx+searchStripUpLeftx;
    regBlockStarty=meStrip(stripIdx,blockIdx).dy+searchStripUpLefty;
    %fill the regImage
    regImage(regBlockStartx:(regBlockStartx+sysPara.stripSize-1),...
             regBlockStarty:(regBlockStarty+sysPara.blockSize-1))=BlockData(:,:,stripIdx,blockIdx);
         
    end 
end

%end  %%frame loop



 xxx=0;