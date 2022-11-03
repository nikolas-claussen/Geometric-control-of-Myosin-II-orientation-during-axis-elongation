%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Using GetPIV we computes the flow field estimate based on an image sequence 
%   im1 & im2 are assumed to have the same dimensions. The grid X1,Y1
%   is assmued to be contained in the image domain with finite
%   EdgeLength defining size of PIV box. 
%   This script generates a movie displaying the original image with flow
%   field overlayed. 
%   
%   Written by: Sebastian J Streichan, KITP, February 14, 2013
%   Minor modifications: NC, 07/15/2020
%  
%   Note: for some reason, this seems to have problems with 32bit images.
%   Convert images to 16bit beforehand.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


maxNumCompThreads(4)

%% define parameters

EdgeLength  = 15;   % Length of box edges in pixels; % 15 original
isf         = .5;   % image scaling factor.  % .5!!
step        = 1;    % step in timeframes.
smooth      = 1;    % set to 1 if gaussian smoothing is desired
sigma       = 3;    % standard deviation of gaussian kernel
KernelSize  = round(3*sigma);    % Smoothing kernel size % 10 in vishank's script

hist_eq = 0;        % whether to use local histogram equalization.
NumTiles = 16;      % number of local hist tiles (image size /  kernel size)

show_plots = 0; % whether to show a movie at the end

% define data directory and list of embryos to process
root_path = '/data/';
embryos = ["1", "2", "3"];

%% loop over movies

for embryo = embryos
    disp(embryo)
	% get file name    
	Name = strcat(root_path, num2str(embryo), '/', dir(strcat(root_path, num2str(embryo), '/*.tif')).name);
    
    StackSize   = length(imfinfo(Name));
    im1 = imread(Name,1);
    if isf ~= 1
        im1 = imresize(im1, isf, 'bicubic');
    end
    % define the grid on which to compute the flow field
    [X1,Y1] = meshgrid(EdgeLength/2:EdgeLength:size(im1,1)-EdgeLength/2,EdgeLength/2:EdgeLength:size(im1,2)-EdgeLength/2); 
    
    % loop over time points
    for t = 1:step:StackSize-step
        disp(t)
        % read the image and scale
        im1 = imread(Name,t);
        im2 = imread(Name,t+step);
        
        im1 = imadjust(im1);
        im2 = imadjust(im2);
        
        if isf ~= 1
            im1 = imresize(im1, isf, 'bicubic'); % rescale image if desired
            im2 = imresize(im2, isf, 'bicubic');
        end
        if hist_eq == 1
            im1 = adapthisteq(im1, 'NumTiles', [NumTiles, NumTiles]);
            im2 = adapthisteq(im2, 'NumTiles', [NumTiles, NumTiles]);
        end
        
        % compute the piv flow field
        [VX,VY] = GetPIV(im1, im2, X1, Y1, EdgeLength);
        VX = VX/step;
        VY = VY/step;

        % smooth if desired
        if smooth == 1
            VX = imfilter(VX, fspecial('gaussian', KernelSize, sigma));
            VY = imfilter(VY, fspecial('gaussian', KernelSize, sigma));
        end

        save(strcat(root_path, embryo, '/PIV/', sprintf('VeloT_%06d.mat',t)), 'VX', 'VY');

        % Display image and overlay flow field.
        if show_plots == 1
            imshow(im1',[])
            hold on 
            f = 5;
            quiver(X1, Y1, f*VX, f*VY, 0, 'g-')
            % records a movieloci
            M(t) = getframe(gca); % don't close the figure or this line will throw an error
        end
    end
    %%
    %play a movie
    if show_plots == 1
        implay(M)
    end
end
