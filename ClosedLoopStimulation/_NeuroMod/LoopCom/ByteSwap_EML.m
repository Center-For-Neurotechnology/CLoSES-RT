function outBytes = ByteSwap_EML(inBytes,typeIn,swapStr)
%#codegen
if nargin<3
    swapStr = 'swap';
end
switch swapStr
    case 'swap'
outBytes = rot90(typecast(rot90(inBytes,2),typeIn),2);
    otherwise
        outBytes = typecast(inBytes,typeIn);
end