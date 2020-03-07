function paletteOut = ColorPalette(numColors)

paletteMaster = [.9353 .3848 .0922;
    .0862 .7388 .2347;
    .3048 .9133 .8387;
    .2680 .6807 .9493;
    .8930 .2361 .2818;
    .9046 .5209 .0074;
    .7743 .0015 .6560;
    .0709 .2510 .8534;
    .2304 .9294 .1287;
    .4636 .7801 .9509;
    .9606 .6179 .8579;
    .7974 .3064 .7738;
    .1732 .3961 .8670;
    .8871 .0337 .2375;
    .0067 .9584 .8039;    
    .8859 .1818 .8135;
    .6442 .2193 .9491;
];

paletteOut = paletteMaster(1:numColors,:)';

end