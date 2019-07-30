#' @export
#' @title Returns current COP Year
#'
#' @return Current COP Year. (e.g., for COP19, returns 2019)
#' 
cop_year <- function() { 2019 }


#' @export
#' @title Location of Country UIDs on Home tab.
#' 
#' @return Cell reference where Country UIDs should be on Home tab.
#' 
countryUIDs_homeCell <- function() { "B25" }


#' @export
#' @title List of tabs to skip for given tool.
#' 
#' @param tool "Data Pack", "Data Pack Template", "Site Tool", "Site Tool Template",
#' "Mechanism Map", or "Site Filter".
#' 
#' @return Character vector of tab names to skip.
#' 
skip_tabs <- function(tool = "Data Pack") {
  if (tool %in% c("Data Pack", "Data Pack Template")) {
    skip = c("Home", "Quotes", "Summary", "Spectrum")
  } else {skip = c(NA_character_)}
  
  return(skip)
}

#' @export
#' @title Tool start rows
#' 
#' @param tool "Data Pack", "Data Pack Template", "Site Tool", "Site Tool Template",
#' "Mechanism Map", or "Site Filter".
#' 
#' @return Start row
#' 
startRow <- function(tool) {
  if (tool %in% c("Data Pack", "Site Tool")) {
    start_row <- 5
  } else if (tool %in% c("Data Pack Template", "Site Tool Template")) {
    start_row <- 11
  } else if (tool %in% c("Site Filter")) {
    start_row <- 1
  } else if (tool %in% c("Mechanism Map")) {
    start_row <- 3
  }
    
  return(start_row)
    
}