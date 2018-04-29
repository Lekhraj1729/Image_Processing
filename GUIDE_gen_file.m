function varargout = test2(varargin)
% TEST2 MATLAB code for test2.fig
%      TEST2, by itself, creates a new TEST2 or raises the existing
%      singleton*.
%
%      H = TEST2 returns the handle to a new TEST2 or the handle to
%      the existing singleton*.
%
%      TEST2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST2.M with the given input arguments.
%
%      TEST2('Property','Value',...) creates a new TEST2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before test2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to test2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help test2

% Last Modified by GUIDE v2.5 22-Apr-2018 15:14:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @test2_OpeningFcn, ...
                   'gui_OutputFcn',  @test2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before test2 is made visible.
function test2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to test2 (see VARARGIN)

% Choose default command line output for test2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes test2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = test2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% uigetfile is used to get the image file for testing and its complete path 
 [filename pathname] = uigetfile({'*.jpg';'*.bmp';'*.png'},'File Selector');
 handles.q = strcat(pathname, filename);
 axes(handles.axes1);
 %imshow - pre defined function for loading image and showing to user screen
 imshow(handles.q);
 %added handle to make sure taht all the functions get access to the image
 %file, without handle only this function could process the image file.
 
 guidata(hObject,handles);



% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 q = imread(handles.q);
  %reading the image file to a vriable for further processing
  %the image is stored in a matrix q
  
[rows, columns, numberOfColorChannels] = size(q);
if numberOfColorChannels > 1
	% It's not really gray scale like we expected - it's color.
	% Use weighted sum of ALL channels to create a gray scale image.
	grayImage = rgb2gray(q);   
    red = q(:,:,1);
    green = q(:,:,2);
    blue = q(:,:,3);
    out = red>=0 & red<=255 & green>=0 & green<=100 & blue>=0 & blue<=255;
    [centers1,radii1] = imfindcircles(out,[3 8],'ObjectPolarity','bright','Sensitivity',0.93);
    %imfindcircles is used to find the smaller circle present in the
    %parasite infected image. the radius range is small for these kind of circle.
else
    [centers1,radii1] = imfindcircles(q,[3 8],'ObjectPolarity','bright','Sensitivity',0.94);
    %imshow(q);
    grayImage = q;
	% ALTERNATE METHOD: Convert it to gray scale by taking only the green channel,
	% which in a typical snapshot will be the least noisy channel.
	% grayImage = grayImage(:, :, 2); % Take green channel.
end
imshow(grayImage);

c=imfuse(out,grayImage);%imfuse is used to overlap two images

%applying watershed segmentation
%This technique help us enhance the image accordingly so that the parasite
%and the cell becomes distinguishable from the surroundings.
hy = fspecial('sobel');
hx = hy';
Iy = imfilter(double(grayImage), hy, 'replicate');
Ix = imfilter(double(grayImage), hx, 'replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);
%figure
%imshow(gradmag,[]), title('Gradient magnitude (gradmag)')

se = strel('disk', 20);
Io = imopen(grayImage, se);
%figure
%imshow(Io), title('Opening (Io)')
Ie = imerode(grayImage, se);
Iobr = imreconstruct(Ie, grayImage);
%figure
%imshow(Iobr), title('Opening-by-reconstruction (Iobr)')
Ioc = imclose(Io, se);
%figure
%imshow(Ioc), title('Opening-closing (Ioc)')

%imp can superimpose this by openingbr
Iobrd = imdilate(Iobr, se);
Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);
%figure
%imshow(Iobrcbr), title('Opening-closing by reconstruction (Iobrcbr)')

%binary image with unclear edges
bw = imbinarize(Iobrcbr);
%figure
%imshow(bw), title('Thresholded opening-closing by reconstruction (bw)');
bw=(bw==0);
%imshow(bw), title('Thresholded opening-closing by reconstruction (bw)');

%overlapping several images to make a combined better image.
d=imfuse(bw,Iobrcbr);
e=imfuse(bw,Io);
r=imfuse(bw,Ioc);%less clear few parasites were missing, so processing further
w=imfuse(bw,Iobr);
f=imfuse(d,e);
g=imfuse(w,r);
t=imfuse(f,g);%approved
%figure, imshow(t);
%the IMAGE contained in the MATRIX 't' is the final image that we will use
%for detection of red blood cells RBCs
[centers3,radii3] = imfindcircles(t,[25 45],'ObjectPolarity','bright','Sensitivity',0.96,'Method','twostage');
%using imfindcircles a predefined function we will look for bigger radius
%circular object in the image that will resemble cells.
%h3 = viscircles(centers3,radii3);

c1=size(centers1,1);
c2=size(centers3,1);
%size is used to know the no. of distinguish centers identified by the
%imfindcircles function.



function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
 [filename pathname] = uigetfile({'*.jpg';'*.bmp'},'File Selector');
