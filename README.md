# addFeatures
addFeatures adds spot images to a SCiLS Lab dataset from a list of defined mass spectral features

[1. Introduction](#1-Introduction)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[1.1 What is addFeatures?](#11-What-is-addFeatures)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[1.2 What can addFeatures be used for?](#11-What-can-addFeatures-be-used-for)  
[2. Installing addFeatures](#2-Installing-addFeatures)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[2.1 Running addFeatures](#21-Running-addFeatures)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[2.2 Running addFeatures from within RStudio](#22-Running_addFeatures_from_within_RStudio)  
[3. Using addFeatures](#3-Using-addFeatures)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[3.1 Selecting the SCiLS Lab dataset](#31-Selecting_the_SCiLS_Lab_dataset)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[3.2 Selecting the feature file](#32-Selecting_the_feature_file)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[3.3 Normalization](#33-Normalization)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[3.4 Renaming features](#34-Renaming_features)  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[3.5 Adding total intensity](#35-Adding_total_intensity)  
[4. Acknowledgements ](#4-Acknowledgements)  
[5. Further reading](#5-Further-reading)  

## 1. Introduction

### 1.1 What is addFeatures?

addFeatures adds spot images to a SCiLS Lab dataset from a list of defined mass spectral features, also generated in SCiLS Lab and saved to a .csv file.

### 1.2 What can addFeatures be used for?

addFeatures automates the otherwise tedious process of creating and naming spot images from defined regions in mass spectra, typically corresponding to one or more peaks. The spot images are written to the SCiLS Lab dataset, and are immediately available from withing SCiLS Lab. addFeatures can also normalize the intensities across the spot images to the total of all features, and create an additional image for this total intensity.

## 2. Installing addFeatures

To install addFeatures, simply download the R script and place it in an arbitrary folder, e.g. C:\Program Files\SCiLS Lab tools\addFeatures on a Windows system. Create a batch (.bat) file calling the R program with Rscript.exe for a version of R currently installed on your system that is compatible with the SCiLS Lab R API, e.g. R-4.1.2:

```
@echo off
"C:\Program Files\R\R-4.1.2\bin\Rscript.exe" "C:\Program Files\SCiLS Lab tools\addFeatures\addFeatures.R"
pause
```

If making a shortcut to this batch file, you can change its properties to run in "minimized" mode. This will automatically hide the command line interface, which is only used for debugging and troubleshooting by addFeatures.

### 2.1 Running addFeatures

To run addFeatures, simply launch the software by running the batch file or double-clicking on the shortcut. The first time addFeatures is run, any necessary R libraries will be installed. This may require manual removal of some lock files from previous R package installations.


### 2.2 Running addFeatures from within RStudio

It is also possible to run addFeatures from within RStudio. Simply launch RStudio and open the R script. Remember to use the same version of R compatible with the SCiLS Lab API


## 3. Using addFeatures

addFeatures has a clean graphical user interface (GUI):

![screenshot](./pictures/addFeatures.png)

Tooltips provide additional cues on the different elements of the GUI.

### 3.1 Selecting the SCiLS Lab dataset

Click on the 



### 3.2 Calculating distance matrices

Distance matrices are calculated using a separate executable, compareMS2_to_distance_matrices. This can also average the distances for multiple replicates per species for more accurate molecular phylogenetic analysis. For this, a tab-delimited file with filenames and species names are required. If no such file is provided, one is created automatically, using the filenames as sample "species". The distance matrix can currently be saved in the MEGA or Nexus formats. [MEGA](https://www.megasoftware.net/) is recommended for creating trees from compareMS2 results.

### 3.3 Running compareMS2

After specifying the parameters, click on the "Start" button to run compareMS2 on all files in the specified directory. Alternatively, compareMS2 can be run on two specific files using the CLI version.

### 3.4 Molecular phylogenetics

We recommend [MEGA](https://www.megasoftware.net/) creating phylogenetic trees from compareMS2 results. However, most phylogenetic software can take distance matrices as input for UPGMA analysis. This was the original use for which compareMS2 was developed, see the [2012 paper](https://doi.org/10.1002/rcm.6162).

### 3.5 Data quality control

compareMS2 provides a very quick overview of large number of datasets to see if they cluster as expected or if there are outliers. Data of lower quality can thus be detected *before* running them through a data analysis pipeline and statistical analysis. It is not absolutely necessary to include all spectra in the analysis - major discrepancies should be detectable with ~1,000 spectra, if selected systematically. Similarly, compareMS2 can be used to determine the relative importance of factors in sample preparation and analysis, as shown in a [2016 paper](https://doi.org/10.1002/rcm.7494).

In addition, compareMS2 collects metadata on each dataset (by default the number of tandem mass spectra) and visualizes this on top of the hierarcical clustering or phylogenetic tree.

### 3.6 Experimental features

Starting in version 2.0, we have begun to include experimental features in compareMS2. These are only available on the command line, but allow extraction of additional information from the comparisons, such as the distribution of similarity between tandem mass spectra as function of precursor mass measurement error, allowing identification of isotope errors and charge state distributions *before* any database search:

![screenshot](./pictures/addFeatures.png)  
Figure 2. Similarity (spectral angle from 0 to 1) of tandem mass spectra plotted against precursor *m*/*z* difference, revealing isotope errors up to at least 2 (corresponding to bands at *m*/*z* difference 2/3 and 2/5) and charge states up to 6 (corresponding to the band at *m*/*z* difference 1/6).

## 4. Acknowledgements

The developer wish to thank Rob Marissen for help and support during the development of addFeatures.

## 5. Further reading

addFeatures has not been described or used in any publications as yet.
