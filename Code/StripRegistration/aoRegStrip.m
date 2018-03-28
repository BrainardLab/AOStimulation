function [regImage,status]=aoRegStrip(refImage,desinMovies,sysPara,imagePara)
% do registration
%
% Syntax:
%    [status]=aoRegStrip(refImage,desinMovies,sysPara,imagePara)
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
%non overlap
nStrip = fix(imagePara.H/sysPara.stripSize);

%gen ROI image according to the sysPara.ROIx,sysPara.ROIy, Padding 0 mode.
%during debug, we can try Padding 255
RoiImage = (zeros(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W));
RoiImage = uint8(RoiImage);
RoiImage(sysPara.ROIy:(sysPara.ROIy+imagePara.H-1),...
         sysPara.ROIx:(sysPara.ROIx+imagePara.W-1))...
         = refImage ;

%  strip clssify loop
    for i = 1: nStrip    
        Strip_start = 1 + (i-1)*sysPara.stripSize;
        Strip_end = i*sysPara.stripSize;
        stripData(:,:,i) = curImage(Strip_start:Strip_end,:);
    end %  strip loop
%  one strip register loop
%  motion estimation
for stripIdx = 1 : nStrip
    curStrip = stripData(:,:,stripIdx);
    searchStripUpLeftx=1+(stripIdx-1)*sysPara.stripSize+sysPara.ROIx;
    searchStripUpLefty=1+sysPara.ROIy;
    meResult = 2^16;
    for dx = -sysPara.ROIx : sysPara.ROIx
        for dy = -sysPara.ROIy : sysPara.ROIy
            % ssad
              %gen ref strip
              searchStripStartx = dx+searchStripUpLeftx;
              searchStripStarty = dy+searchStripUpLefty;
              
              searchStrip = RoiImage(searchStripStartx:...
                                    (searchStripStartx+sysPara.stripSize-1),...
                                    searchStripStarty:...
                                    (searchStripStarty+imagePara.W-1));
              %calculate the matching process                  
              searchResult=aoRegMatch(searchStrip,curStrip);    
              %compare the results to get the best matching and save the result 
              if (searchResult<meResult)
                  meResult = searchResult;
                  meStrip(stripIdx).result = meResult;
                  meStrip(stripIdx).dx = dx;
                  meStrip(stripIdx).dy = dy;
              end
              
        end
    end
end
%restore the registered image from the motion estimation
regImage = uint8((zeros(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W)));
for stripIdx = 1 : nStrip
    
    %calculate the up left point of the strip
    searchStripUpLeftx=1+(stripIdx-1)*sysPara.stripSize+sysPara.ROIx;
    searchStripUpLefty=1+sysPara.ROIy;
    regStripStartx=meStrip(stripIdx).dx+searchStripUpLeftx;
    regStripStarty=meStrip(stripIdx).dy+searchStripUpLefty;
    %fill the regImage
    regImage(regStripStartx:(regStripStartx+sysPara.stripSize-1),...
             regStripStarty:(regStripStarty+imagePara.W-1))=stripData(:,:,stripIdx);
    
end

%end  %%frame loop



 xxx=0;