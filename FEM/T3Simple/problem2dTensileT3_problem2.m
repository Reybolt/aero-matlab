% A Thin Plate Subjected to Uniform Traction
% T3 Implementation, using n-elements
% modified by Manuel Diaz, f99543083 
% IAM, NTU, 2013.04.11.

% Clear memory
clear all; clc;

% Materials
E  = 30e6;     poisson = 0.30;  thickness = 1;

% Matrix D
D=E/(1-poisson^2)*[1 poisson 0;poisson 1 0;0 0 (1-poisson)/2];
 
% Mesh Generation
test = [1,2,4,8]; % square type of domain is configured

% Initilize figure
figure(1); 

for n_test = 1:4

%% Define Structured grid Parameters
xElements = test(n_test);
yElements = xElements;
% numberElements: number of elements
numberElements = 2*xElements*yElements; 
% numberNodes: number of nodes
xNodes = xElements+1;
yNodes = yElements+1;
numberNodes = xNodes*yNodes;

%% coordinates and connectivities
%elementNodes=[1 3 2; 1 4 3];
elementNodes = [];
for i = 1:xElements;
    for j = 1:yElements;
        k = j+yNodes*(i-1);
        temp = [ k,yNodes+k,yNodes+k+1 ; k,yNodes+k+1,k+1 ];
        elementNodes = [elementNodes;temp];
    end
end
dx = 20/xElements; nx = 0:dx:20; h = dx;
dy = 10/yElements; ny = 0:dy:10; l = dy;

%nodeCoordinates=[0, 0; 0, 10; 20, 10; 20, 0];
[x,y] = meshgrid(nx,ny);
nodeCoordinates=[];
for i = 1:xNodes
    for j = 1:yNodes
        temp = [x(j,i),y(j,i)];
        nodeCoordinates = [nodeCoordinates;temp];
    end
end
figure(2);
subplot(2,2,n_test); drawingMesh(nodeCoordinates,elementNodes,'T3','k-o');
name = [num2str(numberElements),' elements']; title(name);

%% Build Math objects

% GDof: global number of degrees of freedom
GDof=2*numberNodes; 

% Boundary Conditions 
%prescribedDof=[1 2 3 4]';
fixedNodes = find(nodeCoordinates(:,1) == 0); % fixed nodes at  x = 0 [in]
xDofs = 2*fixedNodes-1;
yDofs = 2*fixedNodes;
prescribedDof = [xDofs;yDofs];

% Force vector 
force=zeros(GDof,1);
%force(5)=5000; force(7) =5000;
prescribedForce = find(nodeCoordinates(:,1) == 20); % nodes at x = 20 [in]
xDofs = 2*prescribedForce-1;
xForce = 10000/length(prescribedForce); % from 1000 psi*10in^2 = 10,000 lb
force(xDofs) = xForce;

% Calculation of the system stiffness matrix
stiffness=formStiffness2D(GDof,numberElements,...
    elementNodes,numberNodes,nodeCoordinates,D,thickness);

%% Compute Displacemente
displacements=solution(GDof,prescribedDof,stiffness,force);

%% Compute stress
for e = 1:numberElements
    % elementDof: element degrees of freedom (Dof)
    elementDof = [];
    for i = elementNodes(e,:)
        temp = [2*i-1,2*i];
        elementDof = [elementDof,temp];
    end
    B = Bmat(nodeCoordinates,elementNodes,e);
    stress(:,e) = D*B*displacements(elementDof);
end

%% output displacements
outputDisplacements(displacements, numberNodes, GDof);

%% output stress
for e = 1:numberElements
    fprintf('\n');
    fprintf('Stress in element %1.0f \n', e)
    fprintf('Sigma_xx : %4.6f \n',stress(1,e));
    fprintf('Sigma_yy : %4.6f \n',stress(2,e));
    fprintf('Sigma_xy : %4.6f \n',stress(3,e));
end

% Create plots for point (x,y) = (20,10)
figure(1)
subplot(2,2,1); plot(h,displacements(end-1),'ok'); hold on; title('x displacement');
    ylabel('U_x,in'); xlabel('element size,h(in)');
subplot(2,2,2); plot(h,displacements(end),'ok'); hold on; title('y displacement');
    ylabel('U_y,in'); xlabel('element size,h(in)');
subplot(2,3,4); plot(h,stress(1,end),'ok'); hold on; title('stress xx');
    ylabel('sigma_xx,psi'); xlabel('element size,h(in)');
subplot(2,3,5); plot(h,stress(2,end),'ok'); hold on; title('stress yy');
    ylabel('sigma_yy,psi'); xlabel('element size,h(in)');
subplot(2,3,6); plot(h,stress(3,end),'ok'); hold on; title('stress xy');
    ylabel('sigma_xy,psi'); xlabel('element size,h(in)');

end % end for n_test.
