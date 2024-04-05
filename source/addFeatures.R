#
# addNormalizedFeatures.R
#
# MIT License
#
# Copyright (c) 2024 Magnus Palmblad
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

#   The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

print("The output in this window is for debugging and troubleshooting only.")

# Ensure the tcltk package is loaded:
packageName <- "SCiLSLabClient"
if (!requireNamespace(packageName, quietly = TRUE)) {
  # The package is not installed; run the external script to install it
  message(sprintf(
    "Package '%s' is not installed. Attempting to install...",
    packageName
  ))
  
  # Specify the path to your external R script that installs the package:
  pathToScript <-
    "C:/Program Files/SCiLS/SCiLS Lab/APIClients/R/install_SCiLSLab_API_client.R"
  # Run the external script:
  source(pathToScript)
  
  # Optionally, you can check again if the package was successfully installed:
  if (!requireNamespace(packageName, quietly = TRUE)) {
    stop(
      sprintf(
        "Failed to install the package '%s'. Please check for errors and try again.",
        packageName
      )
    )
  } else {
    message(sprintf("Package '%s' has been successfully installed.", packageName))
  }
} else {
  message(sprintf("Package '%s' is already installed.", packageName))
}

# Ensure the tcltk package is loaded:
if (!requireNamespace("tcltk"))
  install.packages("tcltk")
library(tcltk)

# Initialize file path variables:
file1 <- ""
file2 <- ""

# Create the main window:
win <- tktoplevel()
tkwm.title(win, "addFeatures")

# Set the window size:
tkwm.geometry(win, "730x235")


# Initialize text entries for displaying file names:
entryFile1 <- tkentry(win, width = 80)
entryFile2 <- tkentry(win, width = 80)

# Define function to update file path variables and display file names:
updateFilePath <- function(id, path) {
  path <- as.character(path)
  if (id == 1 && length(path) > 0) {
    file1 <<- path
    tkdelete(entryFile1, 0, "end")
    tkinsert(entryFile1, 0, basename(path))
  } else if (id == 2 && length(path) > 0) {
    file2 <<- path
    tkdelete(entryFile2, 0, "end")
    tkinsert(entryFile2, 0, basename(path))
  }
}

# Define function to be executed when the button is pressed:
runScriptOnFiles <- function() {
  if (file1 != "" & file2 != "") {
    library(SCiLSLabClient)
    
    # select image file:
    temporary_directory <- tempfile(pattern = "slxdir")
    datafile <- file.path(file2)
    
    # start the local server session:
    data <- SCiLSLabOpenLocalSession(datafile, port = 8082)
    
    # import the feature list from a CSV file (saved from SCiLS Lab):
    features_file <- file.path(file1)
    features <- read.csv(features_file, skip = 8, sep = ";")
    
    # get regions and coordinates from data:
    regTree <- getRegionTree(data)
    allRegions <- flattenRegionTree(regTree)
    do.call("rbind.data.frame", lapply(allRegions, "[", c(1:2)))
    coords <- getRegionSpots(data, regionId = "Regions")
    
    # get normalizations from data:
    getNormalizations(data)
    normalizations <- getNormalizations(data)
    ticNorm <-
      normalizations$uniqueId[normalizations$description == "Total Ion Count"]
    
    
    # define peaks by their min and max m/z (to be read from data):
    peaks <- data.frame(
      min = features[, 1] - features[, 2],
      max = features[, 1] + features[, 2],
      name = features$Name
    )
    
    # create a dataframe to store the ion intensities:
    ionIntensities <-
      setNames(data.frame(matrix(
        ncol = length(peaks$min),
        nrow = length(coords$spotId)
      )), peaks$name)
    
    # extract specified ion intensities from data:
    for (i in 1:length(peaks$min)) {
      ionIntensities[i] <- getIonIntensities(
        data,
        peaks$min[i],
        peaks$max[i],
        regionId = 'Regions',
        mode = 'sum',
        normId = ticNorm
      )$intensity
    }
    
    # write a spot image for each defined m/z region (peak):
    for (i in 1:length(peaks$min)) {
      if (tclvalue(renameState) == "1")
        peaks$name[i] <-
          as.character((peaks$min[i] + peaks$max[i]) / 2)
      if (tclvalue(normalizeState) == "1")
        writeScoreSpotImage(
          data,
          name = as.character(peaks$name[i]),
          groupname = "Peaks (normalized to 1)",
          userinfo = c("m/z " = as.character(paste(
            peaks$min[i], "-", peaks$max[i]
          ))),
          values = data.frame(
            spotId = coords$spotId,
            value = ionIntensities[[i]] / rowSums(ionIntensities)
          )
        )
      if (tclvalue(normalizeState) == "0")
        writeScoreSpotImage(
          data,
          name = as.character(peaks$name[i]),
          groupname = "Peaks (normalized to 1)",
          userinfo = c("m/z " = as.character(paste(
            peaks$min[i], "-", peaks$max[i]
          ))),
          values = data.frame(spotId = coords$spotId,
                              value = ionIntensities[[i]])
        )
    }
    
    if (tclvalue(addSumState) == "1")
      writeScoreSpotImage(
        data,
        name = "sum of all peaks",
        groupname = "Peaks (normalized to 1)",
        userinfo = c("m/z " = as.character(paste("all peaks"))),
        values = data.frame(
          spotId = coords$spotId,
          value = rowSums(ionIntensities)
        )
      )
    
    # cleanup (run these before switching to SCiLS Lab - R session can be kept open):
    close(data)
    Sys.sleep(1)
    unlink(temporary_directory, recursive = TRUE)
    
    if (tclvalue(normalizeState) == "0") endMessage <- "Features have been added as spot images."
    if (tclvalue(normalizeState) == "1") endMessage <- "Normalized features have been added as spot images."
    
    # Display a confirmation message when done:
    tkmessageBox(
      message = endMessage,
      title = "Confirmation",
      icon = "info",
      type = "ok"
    )
    
    # Then close the GUI window:
    tkdestroy(win)
    
  } else {
    tkmessageBox(message = "Please select both files before running the script.")
  }
}

# Create tooltip:
# Function to create a tooltip
createTooltip <- function(x, y, text) {
  tooltip <- tktoplevel(win, takefocus = NA)
  tkwm.overrideredirect(tooltip, TRUE) # Make it a borderless window
  tkwm.geometry(tooltip, paste("+", x, "+", y, sep = "")) # Position near the cursor/button
  label <-
    tklabel(
      tooltip,
      text = text,
      justify = "left",
      background = "yellow",
      relief = "solid",
      borderwidth = 1
    )
  tkpack(label)
  return(tooltip)
}

btnFile1 <-
  tkbutton(
    win,
    text = "Select features (.csv) file",
    padx = 3,
    command = function() {
      filePath <-
        tkgetOpenFile(filetypes = "{{CSV files} {.csv}} {{All files} {*}}")
      if (!is.null(filePath) && length(filePath) > 0) {
        updateFilePath(1, filePath)
      }
    }
  )
tkgrid(
  btnFile1,
  row = 1,
  column = 1,
  padx = 10,
  pady = 20
)

# Bind mouse events to the button to show and hide the tooltip:
tooltip <- NULL
tkbind(btnFile1, "<Enter>", function(...) {
  info <- .Tcl("winfo pointerxy .")
  coords <- strsplit(as.character(info), " ")
  x <- as.numeric(coords[1]) + 10
  y <- as.numeric(coords[2]) + 10
  tooltip <<-
    createTooltip(x, y, "Select the file defining the features.")
})
tkbind(btnFile1, "<Leave>", function(...) {
  if (!is.null(tooltip)) {
    tkdestroy(tooltip)
    tooltip <<- NULL
  }
})

# Add the text entry for File 1 next to its button:
tkgrid(
  entryFile1,
  row = 1,
  column = 2,
  columnspan = 2,
  padx = 10,
  pady = 10
)

# Add file selection button for File 2 with padding and text entry:
btnFile2 <-
  tkbutton(
    win,
    text = "Select SCiLS Lab .slx file",
    padx = 5,
    command = function() {
      filePath <-
        tkgetOpenFile(filetypes = "{{SLX files} {.slx}} {{All files} {*}}")
      if (!is.null(filePath) && length(filePath) > 0) {
        updateFilePath(2, filePath)
      }
    }
  )
tkgrid(
  btnFile2,
  row = 2,
  column = 1,
  padx = 10,
  pady = 10
)

# Position the text entry for File 2 next to its button:
tkgrid(
  entryFile2,
  row = 2,
  column = 2,
  columnspan = 2,
  padx = 10,
  pady = 10
)

# Bind mouse events to the button to show and hide the tooltip:
tooltip <- NULL
tkbind(btnFile2, "<Enter>", function(...) {
  info <- .Tcl("winfo pointerxy .")
  coords <- strsplit(as.character(info), " ")
  x <- as.numeric(coords[1]) + 10
  y <- as.numeric(coords[2]) + 10
  tooltip <<- createTooltip(x, y, "Select the SCiLS Lab dataset")
})
tkbind(btnFile2, "<Leave>", function(...) {
  if (!is.null(tooltip)) {
    tkdestroy(tooltip)
    tooltip <<- NULL
  }
})

# Add button to run the script on the selected files with padding:
btnRunScript <-
  tkbutton(win, text = "Add features as spot images", command = runScriptOnFiles)
tkgrid(
  btnRunScript,
  row = 4,
  column = 1,
  columnspan = 3,
  padx = 10,
  pady = 5
)

# Bind mouse events to the button to show and hide the tooltip:
tooltip <- NULL
tkbind(btnRunScript, "<Enter>", function(...) {
  info <- .Tcl("winfo pointerxy .")
  coords <- strsplit(as.character(info), " ")
  x <- as.numeric(coords[1]) + 10
  y <- as.numeric(coords[2]) + 10
  tooltip <<-
    createTooltip(x, y, "Run addFeatures on selected features and SCiLS Lab file")
})
tkbind(btnRunScript, "<Leave>", function(...) {
  if (!is.null(tooltip)) {
    tkdestroy(tooltip)
    tooltip <<- NULL
  }
})


# Variable to hold the state of the checkbox (1 for checked, 0 for unchecked):
normalizeState <- tclVar(1)

# Create a checkbox
chkBox <-
  tkcheckbutton(win,
                padx = 15,
                text = "Normalize features to 1",
                variable = normalizeState)

tkgrid(
  chkBox,
  row = 3,
  column = 1,
  columnspan = 1,
  padx = 10,
  pady = 20
)

# Variable to hold the state of the checkbox (1 for checked, 0 for unchecked):
renameState <- tclVar(0)

# Create a checkbox
chkBox <-
  tkcheckbutton(win, text = "(Re)name features by m/z", variable = renameState)

tkgrid(
  chkBox,
  row = 3,
  column = 2,
  columnspan = 1,
  padx = 10,
  pady = 20
)

# Variable to hold the state of the checkbox (1 for checked, 0 for unchecked):
addSumState <- tclVar(1)

# Create a checkbox
chkBox <-
  tkcheckbutton(win, text = "Include total intensity", variable = addSumState)

tkgrid(
  chkBox,
  row = 3,
  column = 3,
  columnspan = 1,
  padx = 10,
  pady = 20
)


# Start the Tcl/Tk event loop:
tkwait.window(win)
