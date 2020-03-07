function HideFromLegend(plotHandle)
% hide a plot element from the matlab legend. AAS 2015.04.

            hAnnotation = get(plotHandle,'Annotation');
            hLegendEntry = get(hAnnotation','LegendInformation');
            set(hLegendEntry,'IconDisplayStyle','off')
            