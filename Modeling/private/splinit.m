%
% Permission was provided by the author, Arnold Neumaier, to 
% modify and distribute this MATLAB code with the informME 
% package. Contact the original author directly for use outside 
% this package. 
%
% Author's website:
% http://www.mat.univie.ac.at/~neum/
%
% Author's source websites:
% http://www.mat.univie.ac.at/~neum/software/mcs/
% http://www.mat.univie.ac.at/~neum/software/minq/
% http://www.mat.univie.ac.at/~neum/software/ls/
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% splinit.m %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [xbest,fbest,f0,xmin,fmi,ipar,level,ichild,f,flag,ncall] = 
% splinit(fcn,data,i,s,smax,par,x0,n0,u,v,x,y,x1,x2,L,l,xmin,fmi,xbest,
% fbest,ipar,level,ichild,f,stop,prt)
% splits box # par at level s according to the initialization list
% in the ith coordinate and inserts its children and their parameters
% in the list 
% Input:
% fcn = 'fun'  	name of function fun(data,x), x an n-vector
% data		data vector
% i            	splitting index
% s            	level of the box
% smax         	depth of search
% par          	label of the box
% x0(1:n,1:max(L)) initialization list
% n0(1:n)      	coordinate i has been split n0(i) times in the history
%              	of the box
% [u,v]        	original box
% x(1:n)       	base vertex of the box
% y(1:n)       	opposite vertex
% x1(1:n), x2(1:n) 'neighbors' of x such that x(i), x1(i), x2(i) are
%		pairwise distinct for i = 1,...,n
% L(1:n)       	lengths of the initialization list
% l(1:n)       	pointer to the initial point in the initialization list
% xmin(1:n,:)  	columns are the base vertices of the boxes in the  
%              	'shopping basket'
% fmi          	fmi(j) is the function value at xmin(:,j)
% xbest       	current best vertex
% fbest    	current best function value
% ipar         	vector containing the labels of the parents of the boxes
%              	not in the shopping basket
% level        	vector containing their levels
% ichild       	the absolute values of this vector specify which child 
%              	they are; ichild(j) < 0 if box j was generated by 
%              	splitting according to the init. list (in the init.
%              	procedure or later) and ichild(j) > 0 otherwise
% f(1:2,:)     	f(1,j) is the base vertex function value of box j and
%              	f(2,j) contains the function value at its splitting 
%              	value (if box j has already been split by default)	
% stop          stop(1) in ]0,1[:  relative error with which the known 
%		 global minimum of a test function should be found
%		 stop(2) = fglob known global minimum of a test function
%		 stop(3) = safeguard parameter for absolutely small 
%		 fglob
%		stop(1) >= 1: the program stops if the best function
%		 value has not been improved for stop(1) sweeps
%		stop(1) = 0: the user can specify a function value that
%		 should be reached
%                stop(2) = function value that is to be achieved
% prt		print level
% Output:
% xbest       	current best vertex
% fbest    	current best function value
% f0(1:L(i))   	base vertex function values of the newly created boxes 
% xmin(1:n,:)  	as before plus newly created boxes 
% fmi          	as before plus newly created boxes 
% ipar         	as before plus newly created boxes
% level        	as before plus newly created boxes
% ichild       	as before plus newly created boxes
% f            	as before plus newly created boxes
% flag         	output flag
%              	= 0 if the known global minimum of a test function has 
%                   been found with the required relative error
%              	= 1 otherwise 
% ncall		number of function evaluations

% Uses the following m-files: 
% bounds.m
% chrelerr.m
% genbox.m
% split1.m
% updtrec.m
% updtoptl.m

function [xbest,fbest,f0,xmin,fmi,ipar,level,ichild,f,flag,ncall] = splinit(fcn,data,i,s,smax,par,x0,n0,u,v,x,y,x1,x2,L,l,xmin,fmi,ipar,level,ichild,f,xbest,fbest,stop,prt)

global nbasket nboxes nglob nsweep nsweepbest record xglob xloc  
% nbasket   	counter for points in the shopping basket
% nboxes      	counter for boxes outside the shopping basket
% nglob       	number of global minimizers of a test function in [u,v]
% nsweep      	sweep counter
% record(1:smax-1) record(i) points to the best non-split box at level i
% xglob(1:n,1:nglob)  xglob(:,i), i=1:nglob, are the global minimizers
% 		of a test function in [u,v]

% initialization 
ncall = 0;
n = length(x); 
f0 = zeros(max(L),1);
flag = 1;
if prt > 1
  [w1,w2] = bounds(n,n0,x,y,u,v);
  iopt = [];
  for iglob = 1:nglob
    if w1 <= xglob(:,iglob) & xglob(:,iglob) <= w2
      iopt = [iopt, iglob];
    end
  end      
end
for j=1:L(i)
  if j ~= l(i)
    x(i) = x0(i,j);
    f0(j) = feval(fcn,data,x);
    ncall = ncall + 1;
    if f0(j) < fbest
      fbest = f0(j);
      xbest = x;
      nsweepbest = nsweep;
      if stop(1) > 0 & stop(1) < 1
        flag = chrelerr(fbest,stop);
      elseif stop(1) == 0
        flag = chvtr(fbest,stop(2));
      end
      if ~flag,return,end
    end
  else
    f0(j) = f(1,par);
  end
end  
[fm,i1] = min(f0); 
if i1 > 1
  splval1 = split1(x0(i,i1-1),x0(i,i1),f0(i1-1),f0(i1));
else
  splval1 = u(i);
end
if i1 < L(i)
  splval2 = split1(x0(i,i1),x0(i,i1+1),f0(i1),f0(i1+1));
else
  splval2 = v(i);
end
if s + 1 < smax 
  nchild = 0;
  if u(i) < x0(i,1) % in that case the box at the boundary gets level s + 1
    nchild = nchild + 1;
    nboxes = nboxes + 1;
    [ipar(nboxes),level(nboxes),ichild(nboxes),f(1,nboxes)] = genbox(par,s+1,-nchild,f0(1)); 
    updtrec(nboxes,level(nboxes),f(1,:));
    if prt > 1,
      updtoptl(i,u(i),x0(i,1),iopt,s+1,f0(1));
    end
  end
  for j=1:L(i)-1
    nchild = nchild + 1;
    splval = split1(x0(i,j),x0(i,j+1),f0(j),f0(j+1));  
    if f0(j) <= f0(j+1) | s + 2 < smax
      nboxes = nboxes + 1;
      if f0(j) <= f0(j+1) 
        level0 = s + 1;
      else
        level0 = s + 2;
      end
% the box with the smaller function value gets level s + 1, the one with
% the larger function value level s + 2
      [ipar(nboxes),level(nboxes),ichild(nboxes),f(1,nboxes)] = genbox(par,level0,-nchild,f0(j));
      updtrec(nboxes,level(nboxes),f(1,:));
      if prt > 1,
        updtoptl(i,x0(i,j),splval,iopt,level0,f0(j));
      end
    else
      x(i) = x0(i,j);
      nbasket = nbasket + 1;
      xmin(:,nbasket) = x;
      fmi(nbasket) = f0(j);
      if prt > 1,
        updtoptl(i,x0(i,j),splval,iopt,smax,f0(j));
      end    
    end
    nchild = nchild + 1;
    if f0(j+1) < f0(j) | s + 2 < smax
      nboxes = nboxes + 1;
      if f0(j+1) < f0(j)  
        level0 = s + 1;
      else
        level0 = s + 2;
      end
      [ipar(nboxes),level(nboxes),ichild(nboxes),f(1,nboxes)] = genbox(par,level0,-nchild,f0(j+1));
      updtrec(nboxes,level(nboxes),f(1,:));
      if prt > 1,
        updtoptl(i,splval,x0(i,j+1),iopt,level0,f0(j+1));
      end         
    else
      x(i) = x0(i,j+1);
      nbasket = nbasket + 1;
      xmin(:,nbasket) = x;
      fmi(nbasket) = f0(j+1);
      if prt > 1,
        updtoptl(i,splval,x0(i,j+1),iopt,smax,f0(j+1));
      end         
    end
  end
  if x0(i,L(i)) < v(i) % in that case the box at the boundary gets level s + 1
    nchild = nchild + 1;
    nboxes = nboxes + 1;
    [ipar(nboxes),level(nboxes),ichild(nboxes),f(1,nboxes)] = genbox(par,s+1,-nchild,f0(L(i)));
    updtrec(nboxes,level(nboxes),f(1,:));
    if prt > 1,
      updtoptl(i,x0(i,L(i)),v(i),iopt,s+1,f0(L(i)));
    end         
  end     
else
  if prt > 1 & u(i) < x0(i,1)
    updtoptl(i,u(i),x0(i,1),iopt,smax,f0(1));
  end
  for j=1:L(i)
    x(i) = x0(i,j);
    nbasket = nbasket + 1;
    xmin(:,nbasket) = x;
    fmi(nbasket) = f0(j);
    if prt > 1 & j < L(i)
      splval = split1(x0(i,j),x0(i,j),f0(j),f0(j+1));
      updtoptl(i,x0(i,j),splval,iopt,smax,f0(j));
      updtoptl(i,splval,x0(i,j+1),iopt,smax,f0(j+1));
    end
    if prt > 1 & x0(i,L(i)) < v(i)
      updtoptl(i,x0(i,L(i)),v(i),iopt,smax,f0(L(i)));
    end
  end  
end
