#' @export
#' @title Extract COP indicators list from DATIM
#' 
#' @description
#' Queries DATIM to return list of COP indicators for given COP year.
#' 
#' @param cop_year Year of COP for which to return indicator list. (e.g., for 
#' COP19 enter 19.) If left blank, will use COP Year as stored in datapackr.
#' 
#' @return Dataframe of COP indicators retrieved from DATIM
#'
pull_COPindicators <- function(cop_year = datapackr::getCurrentCOPYear()) {
  indicators <- datapackr::api_call("indicators") %>%
    datapackr::api_filter(field = "indicatorGroups.name",
                          operation = "eq",
                          match = paste("COP",stringr::str_sub(cop_year,start = -2),"indicators")) %>%
    datapackr::api_fields("code,id,name,numeratorDescription,numerator,denominatorDescription,denominator,indicatorType[id,name]") %>%
    datapackr::api_get()
  
  row.names(indicators) <- NULL
  
  return(indicators)
  
}