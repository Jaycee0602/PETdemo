clear;clc;close all

%% Open and Read PET Images
fid = fopen('petimg.fl');
[img_PET,cnt] = fread(fid,inf,'float32');
fclose(fid);
num_slices = cnt/128/128;

%% Open and Read CT Images
fid = fopen('ctimg.fl');
[img_CT,cnt] = fread(fid,inf,'float32');
fclose(fid);

%% Reshape images to Proper Formats 
I = reshape(img_PET,128,128,[]); % reslice PET into 3D volume
I_CT = reshape(img_CT,512,512,[]); % reshape CT into 3d volume
I_CT = imresize(I_CT,0.25); % resize to 128x128

% % display axial PET
% figure(1);clf
% for i = 1:264
%     imshow(I(:,:,i),[-1000 2000])
%     %%pause(0.00001)
% end
% 
% % Display axial CT
% figure(1);clf
% for i = 1:264
%     imshow(I_CT(:,:,i),[-500 1000])
%     %%pause(0.00001)
% end

% % reslice coronal
% b = zeros(128,264,128);
% for i = 1:128;
%     b(:,:,i) = I(:,i,:);
% end
% 
% for i = 1:128
%     imshow(b(:,:,i),[0,20000])
%     %%pause(0.00001)
% end

NumAng = 12;
angles = 0:(360/NumAng):((360-(360/NumAng)));

for i = 1:NumAng
    deg1 = imrotate(I,angles(i),'bilinear','crop');
    out(:,:,i) = sum(deg1);
end


figure(2);clf
for j = 1:3
    for i = 1:NumAng
        imshow(out(:,:,i),[0,1000000])
        pause(0.1)
    end
end
