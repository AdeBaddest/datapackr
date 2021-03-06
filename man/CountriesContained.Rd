% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getSiteList.R
\name{CountriesContained}
\alias{CountriesContained}
\title{CountriesContained}
\usage{
CountriesContained(org_unit_uid, base_url = getOption("baseurl"))
}
\arguments{
\item{org_unit_uid}{single org unit uid as a character string}

\item{base_url}{DHIS2 URL to use as base query.}
}
\value{
character vector of country uids, length of 0 if no countries at or below
the org unit
}
\description{
Given an org unit uid, returns uids for all countries at or below the UID in the hierarchy. E.g. global
would return all countries' uids, but the main use case is getting a list of
countries in a region
}
