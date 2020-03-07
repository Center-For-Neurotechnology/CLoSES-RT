function  plexonID =initializePlexon()
    plexonID = coder.extrinsic(PL_InitClient(0)); % initilize and save in persistent variable - add: %persistent plexonID;
    
    
