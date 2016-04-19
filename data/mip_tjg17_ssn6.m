function [ ] = mip_tjg17_ssn6(PET_filename,CT_filename, output_filename,...
                              numAngles, maxProjectionOption, depthWeightingValue)
%% This function performs maximum intensity projection (MIP) for PET/CT datasets

% PET_filename: filename for PET (e.g. 'petimg.fl') with 128x128 slices
% CT_filename: filename for CT (e.g. 'ctimg.fl') with 512x512 slices
% output filname: filename for RAW output (e.g. 'MIP_out.fl')
% NumAngles: Number of angles for MIP projection
% maxProjection: value of 1 for max projection, 0 for summed image
% depthWeightingValue: enter number 1-100 for depth weighting (0 is none)

%% Open and Read PET Images
fprintf('\nLoading 128x128 PET images...')
fid = fopen(PET_filename);
[img_PET,cnt] = fread(fid,inf,'float32');
fclose(fid);
NumSlices = cnt/128/128;
fprintf('done.\n')
fprintf('Number of Slices in PET Input: %d\n\n', NumSlices)

%% Open and read CT images if necessary
% Don't need to load CT if not doing depth weighting
if (maxProjectionOption && depthWeightingValue)
    fprintf('\nLoading 512x512 CT images...')
    fid = fopen(CT_filename);
    [img_CT,cnt] = fread(fid,inf,'float32');
    fclose(fid);
    NumSlices = cnt/512/512;
    fprintf('done.\n')
    fprintf('Number of Slices in CT Input: %d\n\n', NumSlices)
else
    fprintf('Depth Weighting not selected (CT not loaded)\n')
end

%% Resize PET and CT images to 128x128xnumSlices stacks
fprintf('\nReshaping PET input...')
I_PET = reshape(img_PET,128,128,[]); % Resize PET
fprintf('done.\n')

if (maxProjectionOption && depthWeightingValue)
    fprintf('Reshaping CT input...')
    I_CT = reshape(img_CT,512,512,[]); % Resize CT
    I_CT = imresize(I_CT,0.25); % resize to 128x128
    fprintf('done.\n')
    
    fprintf('Normalizing CT input...')
    I_CT = I_CT+500;
    I_CT(I_CT<0)=0;
    I_CT(I_CT>1500)=1500; % Normalize CT
    fprintf('done.\n')
end

%% Compute Angle Locations
angles = 0:(360/numAngles):((360-(360/numAngles)));

%% Compute MIP based on input parameters

% Compute summed output image if max option not chosen
if ~maxProjectionOption
    fprintf('\nComputing summed output image:\n')
    out = zeros(128, NumSlices, numAngles); % preallocate for speed
    for i = 1:numAngles
        fprintf('Computing Angle %i/%i\n',i,numAngles)
        deg1 = imrotate(I_PET,angles(i),'bilinear','crop');
        out(:,:,i) = sum(deg1);
    end
end

% Compute MIP for max projection with no depth weighting
if (maxProjectionOption && ~depthWeightingValue)
    fprintf('\nComputing MIP output image (no depth weighting):\n')
    out = zeros(128, NumSlices, numAngles); % preallocate for speed
    for i = 1:numAngles
        fprintf('Computing Angle %i/%i\n',i,numAngles)
        deg1 = imrotate(I_PET,angles(i),'bilinear','crop');
        out(:,:,i) = max(deg1);
    end
end

% Compute MIP for max projection with depth weighting
if (maxProjectionOption && depthWeightingValue)
    fprintf('\nComputing MIP output image with CT depth weighting:\n')
    out = zeros(128, NumSlices, numAngles); % preallocate for speed
    for i = 1:numAngles
        fprintf('Computing Angle %i/%i\n',i,numAngles)
        for slice = 1:NumSlices
            ax = I_PET(:,:,slice); % pet axial slice
            ct = I_CT(:,:,slice);  % ct axial slice
            deg1 = imrotate(ax,angles(i),'bilinear','crop');
            [intermediate(:,slice), indices] = max(deg1);
            for j = 1:length(indices)
                ctline = ct(:,j);
                summedCT = sum(ctline(indices(j):end));
                % Exponential for depth weighting
                final(j,slice) = intermediate(j,slice)*exp(-0.0000005*depthWeightingValue*summedCT);
            end
        end
        out(:,:,i) = final;
    end   
end

%% Save output as RAW file
fprintf('\nSaving output as RAW file...')
fileID = fopen(output_filename,'w');
fwrite(fileID,out,'float32');
fclose(fileID);
fprintf('done.')

%% Exit MATLAB
fprintf('\n\nExiting MATLAB Now.\n\n')
quit()

end

