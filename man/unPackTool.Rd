% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/unPackTool.R
\name{unPackTool}
\alias{unPackTool}
\title{Unpack a submitted tool}
\usage{
unPackTool(
  submission_path = NULL,
  tool = "Data Pack",
  country_uids = NULL,
  cop_year = getCurrentCOPYear()
)
}
\arguments{
\item{submission_path}{Local path to the file to import.}

\item{tool}{What type of tool is the submission file? Default is "Data Pack".
Other options include "Site Tool", "Mechanism Map", and "Site Filter".}

\item{country_uids}{List of 11 digit alphanumeric DATIM codes representing
countries. If not provided, will check file for these codes. If not in file,
will flag error.}

\item{cop_year}{Specifies COP year for dating as well as selection of
templates.}
}
\description{
Processes a submitted Data Pack, Site Tool, Mechanism Map, or Site Filter by
identifying integrity issues, checking data against DATIM validations, and
extracting data.
}
\details{
Executes the following operations in relation to a submitted Site Tool
\enumerate{
    \item Performs integrity checks on file structure;
}
}
