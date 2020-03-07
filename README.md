# CLoSES-RT
# Closed-Loop system for Electrical Stimulation in humans in Real Time
This project implements a real time closed-loop stimulation platform and GUI
It is based on Simulink Real Time

# Step by Step to RUN and Compile CLoSES-RT 

************ To RUN using GUI ************ 

1. Start MATLAB2016b 
    Make sure to have all required toolboxes (e.g.: Simulink real-Time)

2. To RUN GUI: GUIClosedLoopConsole('PatientName','patientTEST')


Step by Step to RUN and Compile Decider Models

************ To RUN using GUI ************ 

1. Start MATLAB (tested version is MATLAB2016b)
    Make sure to have all required toolboxes (Simulink real-Time, optimization toolbox)

2. Edit patient name and run script: runClosedLoopPhysiology.m

or 2. add ClosedLoopStimulation to path and To RUN GUI: GUIClosedLoopConsole('PatientName','patientTEST')


************ To COMPILE ( Simulink Real-Time Compiler ) ************ 
1. Run initializationScript
Example to Compile:
       initializationScript('SIMULATION', [], 'THETA','SMOOTHBANDPOWER','REALTIME','CONTINUOUS','REFERENTIAL')

2. Open Simulink Model

3. Press BUILD button

NOTE: if building ClosedLoopStimXpcTarget on your computer you would get an error of "could not find target" - that is the expected behavior

************ Models ************ 
Important Models: 

    For simulation: ClosedLoopStim_SimulatedInput.slx
    For BlackRock NSPs: ClosedLoopStimXpcTarget.slx

    Main block for computation: Simulink/ClosedLoopControl.slx

****** Additional important Functions ******

1. Functions to create simulated data from your own EEG:
     script_createSimDataFromNEVfile.m from NS3 data
    script_createSimDataFromRealData.m from .mat MATLAB data


2. Look at: initializationScript.m to see the structure of sInputData

******* Configuration Files ********
Default Configuration files are located on folder: 
Configuration/Physiology

******* Test Data ********
Testing Data to play with the Simulink model located on folder:
ExampleData


Have fun! 
    Rina Zelmann
