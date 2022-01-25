clear;clc;


[FileName,PathName] = uigetfile({'*.jpg'},'Select one of the images in the directory');

%Image directory
a=dir([PathName '/*.jpg']);

imgs_n = numel(a);   %No of images in the directory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
index=1;

%Loop on each image and detect the cross sections in it
for k = 1:imgs_n 
    %Read the Kth image 
    im_direc=[PathName,a(k).name];
    im_dir2=join(im_direc);
    F = imread(im_dir2);
    %figure;
    %imshow(F)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Resize the image for the half of the original size

im_in=imresize(F, 0.5);
%im_in=F;
%im_in=imadjust(im_in,[],[],2);
im_in=imsharpen(im_in,'Radius',8,'Amount',2);



%Asks for the measure of range of one corss section
if k > 0 && index== 1
    
%Image tool to measure intial range for the circels to specify the range
%for circular hough transform 
imtool(im_in)
    
  prompt = 'What is the measured approximate Diameter of one cross section? ';
  range1 = input(prompt);
  range1=round(range1);
end

%Asks at the first loop whether all of the pictures belong to the sample
%sample and the same magnification 
if k==1
prompt = 'Do pictures belong to the same sample and the same maginification level was used (1 for yes, 0 or else for no)? ';
same_range = input(prompt);

end 


%Conditional case to keep asking the user for the Diameter of one cross
%section or no 

if same_range == 1
    index=2;
else 
    index=1;
end

%Range is always positive for the range input in the findcircles function 
if ~mod(range1,2) == 1
    range1;
else
    range1=range1+1;
end


%Thresholding 
BW = im2bw(im_in,0.45); %was set to 0.8 

% Only "big" objects on binary image
[L, num] = bwlabel(BW); 
figure;
imshow(L)
stats = regionprops(L, 'Area', 'PixelIdxList');

area_vector = [stats(:).Area];
area_vector = sort(area_vector);
threshold_pos = floor(num * 0.50);
threshold = area_vector(threshold_pos);

for i=1:num
    if(stats(i).Area < threshold)
        BW(stats(i).PixelIdxList) = false;
    end
end

%Dilate image with a circle of small radius
str = strel('square', 1); 
BW = imdilate(BW, str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Another area filtraion after dilation
[L, num] = bwlabel(BW); 
stats = regionprops(BW, 'Area', 'PixelIdxList');

area_vector = [stats(:).Area];
area_vector = sort(area_vector);
threshold_pos = floor(num * 0.50);
threshold = area_vector(threshold_pos);

for i=1:num
    if(stats(i).Area < threshold)
        BW(stats(i).PixelIdxList) = false;
    end
end

%here 7.7.2021
%BW2 = bwpropfilt(BW,'Area',[50 100000]);

BW2 = bwareafilt(BW,[0.5*3.13*(0.5*range1)*(0.5.*range1) inf]);


%BW2=BW
imshow(BW2)
%[centers,radii] = imfindcircles(BW2,[30 50],'ObjectPolarity','Bright','Sensitivity',0.93,'Method','twostage');
%[centers,radii] = imfindcircles(BW2,[(range1-10)/2 (range1+10)/2],'ObjectPolarity','Bright','Sensitivity',0.94,'EdgeThreshold',0.7,'Method','twostage');
[centers,radii] = imfindcircles(BW2,[(range1-4)/2 (range1+4)/2],'ObjectPolarity','Bright','Sensitivity',0.90,'EdgeThreshold',0.7,'Method','twostage');


% Plot the circles to the input image
figure;
imshow(im_in);
viscircles(centers,radii);

%Save the Output Image to the same directory of the read input images
Image = getframe(gcf);
imwrite(Image.cdata, join([PathName,join(['out',a(k).name])]));

%Save a file with the outputs at the same directory
filename = join([PathName,join([int2str(k),'Results.xlsx'])]);
writematrix([centers,radii],filename,'Sheet',1)

end