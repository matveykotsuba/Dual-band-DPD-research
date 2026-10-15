function a = dbBasis(x,kind,band,c)
    m=c.memoryOrder; delays=0:m;
    if ~strcmp(kind,'dual')
        if strcmp(kind,'wideband'), z=x; else, z=x(:,band); end
        g=struct('orders',c.orders,'signalDelays',delays,'envelopeDelays',delays);
        mask=true(m+1,1+(numel(c.orders)-1)*(m+1));
        for p=2:numel(c.orders)
            mask(:,2+(p-2)*(m+1):1+(p-1)*(m+1))=abs(delays.'-delays)<=c.diagonalCount;
        end
        a=gmpActiveBasis([zeros(m,1);z(:)],g,mask);
        return
    end
    pairs=nnz(abs(delays.'-delays)<=c.diagonalCount);
    count=m+1+pairs*sum((c.orders(2:end)+1)/2);
    a=complex(zeros(size(x,1),count)); column=0; xd=cell(2,m+1);
    for b=1:2
        for d=0:m, xd{b,d+1}=[zeros(d,1);x(1:end-d,b)]; end
    end
    for d=0:m, column=column+1; a(:,column)=xd{band,d+1}; end
    for p=c.orders(2:end)
        degree=(p-1)/2;
        for q=0:m
            for d=0:m
                if abs(d-q)>c.diagonalCount, continue; end
                for exponent=0:degree
                    column=column+1;
                    a(:,column)=xd{band,d+1}.*abs(xd{1,q+1}).^(2*exponent).*abs(xd{2,q+1}).^(2*(degree-exponent));
                end
            end
        end
    end
end
