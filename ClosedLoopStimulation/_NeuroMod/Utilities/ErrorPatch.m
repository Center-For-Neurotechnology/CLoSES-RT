function h = ErrorPatch(xdata,ydata,ciRange,patchCol,varargin)

plot(xdata,ydata,varargin{:},'Color',patchCol);

h = patch([xdata fliplr(xdata)],[ydata-ciRange fliplr(ydata+ciRange+1e-6*ydata)],patchCol,'FaceAlpha',0.2,'Linestyle','none');

HideFromLegend(h);
end