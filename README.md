MITT
====

Multi-Instrument Turbulence Toolbox (Matlab)

For full description of toolbox, please "MacVicar, B.J., S. Dilling, and R.W.J. Lacey, (accepted) Multi-Instrument Turbulence Toolbox (MITT): Open-source MATLAB algorithms for the analysis of high-frequency flow velocity time series datasets Computers and Geosciences.

<h2>Description<h2>

MITT is designed to: i) organize the data output from multiple instruments into a common format; ii) present the data in a variety of interactive figures for visualization; iii) clean the data by removing data spikes and noise; and iv) classify data quality. The scope of the toolbox is currently limited to high frequency (≥ 20 Hz) instruments that are commonly used in field and lab experiments of open-channel flow. 

A common data format, modeled after the output format of the Nortek Vectrino II (VII)™ velocity profiling instrument, is used to save the output from MITT. Two structure arrays called Data and Config store the recorded data and configuration parameters, respectively. 

MITT is capable of handling instruments that sample either a single volume (called a ‘cell’) or multiple cells in parallel (i.e. simultaneously or quasi-simultaneously) or in series (i.e. one after another). Single cell instruments for which Organize algorithms have been created include the Sontek Acoustic Doppler Velocimeter ™ (ADV), the Nortek Vectrino™, and the Marsh-McBirney Electomagnetic Current Meter (ECM). These instruments can be linked to record multiple cells in parallel. Multiple cell instruments for which Organize algorithms have been created include the VII and the Metflow Ultrasonic Doppler Velocity Profiler (UDVP). Multiple UDVP probes can be multiplexed but the software records data from different probes in series. Within the appropriate subfields, single cell time series are stored in single columns while multiple cells in parallel are stored in a matrix with the rows and columns representing the time interval and the cell number, respectively. Multiple cells recorded in series are stored in separate files with their own Data and Config structure arrays. 

Four figures have been designed to visualize recorded data and aid in the assessment of data quality. The available figures are:  
<ol>
<li>The interactive quality control window - profile statistics can be displayed and the effect of different quality control classifications can be visualized, </li>
<li>The time series plot - full recorded velocity time series along with signal correlation data, box plots, and frequency spectra</li>
<li>The time-space velocity matrix plot; and</li>
<li>The sampling cell locations plot.</li>
</ol>

<h2>Getting Started<h2>

Before the master program (MITT) is started, the user must create a CSVcontrol file using the format specified in Table 1 and containing, at a minimum, the parameters specified in Table 2. Care should be taken to ensure that the file names included in the CSVcontrol file match the instrument output file names. The CSVcontrol file and instrument output files must be located in the same directory/folder. 

To begin using MITT:
<ol>
<li>Open MATLAB and open the directory where the MITT programs are located.</li>
<li>From the command line run MITT. The MITT launch window opens (Figure 1).</li>
<li>Click the ‘Select File’ box. This opens a browser window to search for the CSVcontrol file.</li>
</ol>

To upload and organize the raw data into MATLAB format:
<ol>
<li>Click the ‘Organize raw Data and Config array’ tick box. A set of tick boxes appears allowing the user define the channel geometry and custom sampling locations if desired.</li>
<li>Click the ‘Run Analysis’ button. The structured arrays Data and Config are created in a *.MAT file named after each raw data time series.</li>
</ol>

To clean the time series:
<ol>
<li>Click the ‘Clean raw time series’ tick box. The ‘Clean block options’ tick boxes are displayed. The ‘reset despiked and/or filtered time series’ should be ticked if the cleaning algorithms are being rerun.  </li>
<li>Clicking ‘Plot all time series’ will generate a time series plot for each series (e.g., Figure 4). This is recommended as a first quality control measure.  Alternatively, the time series plots can be created from the Interactive Quality Control window (Figure 2).</li>
<li>Click the ‘Despike’ tick box to clean the data. Four de-spiking methods appear and the user has the option to tick one or more to clean the data. </li>
<li>Click the ‘Frequency filter’ tick box to filter the data series. The only filter option is a low pass 3rd order Butterworth filter. </li>
<li>Click the ‘Run Analysis’ button. The cleaned and filtered data series are stored in the Data array.</li>
</ol>

To classify the quality of the time series
<ol>
<li>Click the ‘Classify quality of time series’ tick box. The ‘Classify block options’ tick boxes are displayed along with the classification parameters. The ‘reset classifications with listed parameters’ should be ticked if the classification is being rerun. </li>
<li>Click the ‘Interactive quality control GUI’ tick box to obtain the interactive plotting figure (Figure 2).  Otherwise the classification is done automatically for all files listed in CSVcontrol.</li>
<li>Click the ‘Plot classification results in tables’ tick box to obtain a popup window output of classification results for each time series. </li>
<li>Click the ‘Run Analysis’ button. The classification parameter results are stored in Config.Qdat and the results of the analysis (1 = good data, 0 = poor data) are stored in Config.goodCells.</li>
</ol>

Table 1 - csvcontrol file format example.  Probe elevations should be entered as true elevations (i.e. not relative to the bed). Columns may be in any order and additional columns may be used to save additional parameters as subfields in Config.  For example, the discharge ‘Q’ would be saved as Config.Q.

instrument	filename	zpos	xpos	ypos	waterDepth	bedElevation	Q   
%s	%s	%f	%f	%f	%f	%f	%f  
Vectrino	Example1	0.2	0.5	0.4	1	0	.054  
Vectrino	Example2	0.4	0.5	0.4	1	0	.054  

Table 2 - Variables required for analysis and visualization algorithms.  These variables can be input directly using the CSVcontrol file (Table 1) or can be calculated using custom subprograms  

Parameter  Description  
instrument	Instrument type. Current options are ‘ECM’, ’ADV’, ’Vectrino’, ’VectrinoII’, or ’UDVP’  
filename	File where raw data is stored. File should be located in same directory as the control file.  
waterDepth	Depth of water at measurement location (m)  
bedElevation	Bed elevation at measurement location (m)  
xpos	Streamwise position of sampling volume (m)  
ypos	Lateral position of sampling volume (m)  
zpos	Vertical position of sampling volume (m)  

