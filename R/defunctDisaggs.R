#' @export
#' @importFrom magrittr %>% %<>%
#' @importFrom utils capture.output
#' @title defunctDisaggs(d)
#'
#' @description Checks data extracted from a sheet in a submitted Data Pack or
#'    Site Tool to identify cases where invalid Disaggregate combinations have
#'    been used.
#'
#' @param d Datapackr object.
#' @param sheet Sheet name.
#'     
#' @return d
#' 
defunctDisaggs <- function(d, sheet) {
  
  if (sheet %in% c("SNU x IM","PSNUxIM")) {
    stop("Sorry! Can't check the SNU x IM tab with this function.")
  } else {
    data = d$data$extract
  }
  
  valid_disaggs <- d$info$schema %>%
    dplyr::filter(sheet_name == sheet,
                  col_type == "target") %>%
    dplyr::select(indicator_code, valid_ages, valid_sexes, valid_kps)
  
  defunct_disaggs <- data %>%
    dplyr::left_join(valid_disaggs, by = c("indicator_code" = "indicator_code")) %>%
    dplyr::filter(!purrr::map2_lgl(Age, valid_ages, ~.x %in% .y[["name"]])
                  | !purrr::map2_lgl(Sex, valid_sexes, ~.x %in% .y[["name"]])
                  | !purrr::map2_lgl(KeyPop, valid_kps, ~.x %in% .y[["name"]])) %>%
    dplyr::select(indicator_code, Age, Sex, KeyPop) %>%
    dplyr::distinct()

  d$tests$defunct_disaggs<-dplyr::bind_rows(d$tests$defunct_disaggs,defunct_disaggs)
  attr(d$tests$defunct_disaggs,"test_name")<-"Defunct disaggs"
  
  if (NROW(defunct_disaggs) > 0) {

    defunct_msg <- 
      capture.output(
        print(as.data.frame(defunct_disaggs), row.names = FALSE)
      )
    
    warning_msg <-
      paste0(
        "ERROR! In tab ",
        sheet,
        ": INVALID DISAGGS ",
        "(Check MER Guidance for correct alternatives) -> \n\t",
        paste(defunct_msg, collapse = "\n\t"),
        "\n")
    
    d$info$warning_msg <- append(d$info$warning_msg, warning_msg)
    d$info$has_error <- TRUE
  }
  
  return(d)
  
}
