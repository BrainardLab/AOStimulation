function [regImage,status]=aoRegStripOverlappingOneLine(refImage,desinMovies,sysPara,imagePara)
% Do registration with overlapping strips
%
% Syntax:
%    [regImage,status]=aoRegStripOverlappingOneLine(refImage,desinMovies,sysPara,imagePara)
%
% Description:
%    Registration algorithm, early draft
%
%    At present, just registers the first frame of the passed movie to the
%    reference frame.
%
% Inputs:
%    refImage           - Ref frame, used to registration.
%    desinMovies        - Movies after desinusoiding
%    sysPara            -
%    imagePara          - Image parameters, such as size, frame number, and
%                         so on
%
% Outputs:
%    regImage           - Ref frame, used to registration.
%    status             - Status tells if things are ok.  1 means OK, 0
%                         means error.
%
% Optional key/value pairs:
%    None.
%
% See also:
%

% History:
%   03/14/18  tyh

%for image_iter = 1 : 1 %imagePara.nFrames
% get the current image for registration
image_iter = 1;
curImage = desinMovies(image_iter).cdata;

% Strip increments one line at a time.
lineIncrement = 1;
nStrip = imagePara.H - (sysPara.stripSize-lineIncrement);

%
%gen ROI image according to the sysPara.ROIx,sysPara.ROIy, Padding 0 mode.
%during debug, we can try Padding 255
%RoiImage = (zeros(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W));
RoiImage = 255*(ones(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W));
RoiImage = uint8(RoiImage);
RoiImage(sysPara.ROIy:(sysPara.ROIy+imagePara.H-1),...
    sysPara.ROIx:(sysPara.ROIx+imagePara.W-1))...
    = refImage ;

%  strip clssify loop
for i = 1: nStrip
    Strip_start = i;
    stripData(:,:,i) = curImage(Strip_start:(Strip_start+sysPara.stripSize-1),:);
end %  strip loop
%  one strip register loop
%  motion estimation
for stripIdx = 1 : nStrip
    curStrip = stripData(:,:,stripIdx);
    searchStripUpLeftx=stripIdx+sysPara.ROIx;
    searchStripUpLefty=1+sysPara.ROIy;
    meResult = 0; %2^16
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
            if (searchResult>meResult)
                meResult = searchResult;
                meStrip(stripIdx).result = meResult;
                meStrip(stripIdx).dx = dx;
                meStrip(stripIdx).dy = dy;
                mvx(stripIdx) = dx;
                mvy(stripIdx) = dy;
            end
            
        end
    end
end
%restore the registered image from the motion estimation
regImage = uint8((zeros(2*sysPara.ROIy+imagePara.H,2*sysPara.ROIx+imagePara.W)));
for stripIdx = 1 : nStrip
    
    %calculate the up left point of the strip
    searchStripUpLeftx=stripIdx+sysPara.ROIx;
    searchStripUpLefty=1+sysPara.ROIy;
    regStripStartx=meStrip(stripIdx).dx+searchStripUpLeftx;
    regStripStarty=meStrip(stripIdx).dy+searchStripUpLefty;
    %fill the regImage
    regImage(regStripStartx:(regStripStartx+sysPara.stripSize-1),...
        regStripStarty:(regStripStarty+imagePara.W-1))=stripData(:,:,stripIdx);
    
end

%end  %%frame loop


%% Report status.
%
% For now, always OK.
status = 1;