
function varargout = heatTransferGUI(varargin)

% Begin initialization code
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @heatTransferGUI_OpeningFcn, ...
    'gui_OutputFcn',  @heatTransferGUI_OutputFcn, ...
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

% --- Executes just before heatTransferGUI is made visible.
function heatTransferGUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for heatTransferGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = heatTransferGUI_OutputFcn(hObject, eventdata, handles)

% Get default command line output from handles structure
varargout{1} = handles.output;

function handles = getpara(handles)
handles.data.T_int = str2double(get(handles.T_int,'String'));
handles.data.T_top = str2double(get(handles.T_int,'String'));
handles.data.T_btm = str2double(get(handles.T_int,'String'));
handles.data.T_lft = str2double(get(handles.T_lft,'String'));
handles.data.T_rht = str2double(get(handles.T_rht,'String'));
handles.data.L = str2double(get(handles.L,'String'));
handles.data.H = 1;
handles.data.dx = 0.009; 
handles.data.dy = 0.008; 
handles.data.tmax = str2double(get(handles.tmax,'String')); 
handles.data.dt = 0.1;
handles.data.epsilon = 1e-20;
% Preset the thermal diffusivity of the medium chosen from list
listStrings = get(handles.listalp,'String');
domaintype = listStrings{get(handles.listalp,'Value')};
switch domaintype
    case 'Aluminium'
        domainalp = 9.7e-5;
    case 'Copper'
        domainalp = 1.11e-4;
    case 'Silver'
        domainalp = 1.6563e-4;
    case 'Iron'
        domainalp = 2.3e-5;
end
handles.data.alp = domainalp;
set(handles.alp,'String',handles.data.alp);

handles.data.r_x = handles.data.alp*handles.data.dt/handles.data.dx^2;
handles.data.r_y = handles.data.alp*handles.data.dt/handles.data.dy^2;
fo = handles.data.r_x + handles.data.r_y;


function conduction(handles)

% obtain the input parameters
L = handles.data.L;
H = handles.data.H;
dx = handles.data.dx;
dy = handles.data.dy;
tmax = handles.data.tmax;
tmax=(tmax*60);
dt = handles.data.dt;
epsilon = handles.data.epsilon;
r_x = handles.data.r_x;
r_y = handles.data.r_y;
% create the x, y mesh grid
nx = uint32(L/dx + 1);
ny = uint32(H/dy + 1);
[X,Y] = meshgrid(linspace(0,L,nx),linspace(0,H,ny));
% take the center point
ic = uint32((nx-1)/2+1);
jc = uint32((ny-1)/2+1);   
% set initial + boundary conditions
T = handles.data.T_int*ones(ny,nx);
T(:,1) = handles.data.T_lft;
T(:,end) = handles.data.T_rht;
T(1,:) = handles.data.T_btm;
T(end,:) = handles.data.T_top;
Tmin = min(min(T));
Tmax = max(max(T));
% iteration
n = 0; 
nmax = uint32(tmax/dt);
while n < nmax
    n = n + 1;
    T_n = T;
    for j = 2:ny-1
        for i = 2:nx-1
        T(j,i) = T_n(j,i) + r_x*(T_n(j,i+1)-2*T_n(j,i)+T_n(j,i-1))...
                + r_y*(T_n(j+1,i)-2*T_n(j,i)+T_n(j-1,i));
        end
    end
    if uint16(n/50) == n/50 % refresh the plot every 50 time steps  
        % plot temperature at center
        handles.fig.pl = scatter(handles.Tplot,n*dt,T(jc,ic),'r.');
        xlim(handles.Tplot,[0 tmax]),xlabel(handles.Tplot,'time (s)'),ylabel(handles.Tplot,'center temp. (C)')
        hold(handles.Tplot,'on')
        pause(0.01)
    end
    % convergence check
    err = max(max(abs((T-T_n))));
    if err <= epsilon
        break
    end
end

% Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
x=str2double(get(handles.T_lft,'String'));
y=str2double(get(handles.T_rht,'String'));
z=str2double(get(handles.T_int,'String'));
b=str2double(get(handles.L,'String'));
c=str2double(get(handles.tmax,'String')); 
if mod(x,1) ~= 0 || x<0 || x>100 
    errordlg('Inner surface temp is invalid. Please enter integer between 0-100','Input Error');
    return;
end
if mod(y,1) ~= 0 || y<0 || y>100
    errordlg('Outer surface temp is invalid. Please enter integer between 0-100','Input Error');
    return;
end
if mod(z,1) ~= 0
    errordlg('Please press "random" button to generate initial temp.','Input Error');
    return;
end
if isnan(b) || b<0.01 || b>1
    errordlg('Plate width is invalid. Please enter value between 0.01 - 1','Input Error.');
    return;
end
if mod(c,1) ~= 0 || c<0 || c>6 
    errordlg('Simulation time is invalid. Please enter integer between 0-6','Input Error');
    return;
end

    
cla(handles.Tplot);
handles = getpara(handles);
conduction(handles);
guidata(hObject,handles);

function listalp_Callback(hObject, eventdata, handles)
getpara(handles);

function dt_Callback(hObject, eventdata, handles)
getpara(handles);

function dx_Callback(hObject, eventdata, handles)
getpara(handles);

function dy_Callback(hObject, eventdata, handles)
getpara(handles);

% Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
set(handles.T_int,'String',round(rand(1)*100));


% Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)

function slider1_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
