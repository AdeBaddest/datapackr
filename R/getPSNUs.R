#' @export
#' @title Pull list of PSNUs from DATIM based on provided country UIDs.
#' 
#' @description
#' Queries DATIM to extract list of PSNUs and adds additional PSNUs not
#' currently in DATIM as needed.
#' 
#' @param country_uids Character vector of DATIM country IDs. This can only
#' include countries. Regional Operating Unit UIDs will not be accepted
#' @param include_mil Logical. If \code{TRUE}, will also include _Military nodes
#' related to \code{country_uids}. Default is \code{TRUE}.
#' @param additional_fields Character string of any fields to return from DATIM
#' API other than those returned by default: \code{name}, \code{id}, \code{ancestors},
#' & \code{organisationUnitGroups}.
#' 
#' @return Data frame of PSNUs
#' 
getPSNUs <- function(country_uids = NULL,
                     include_mil = TRUE,
                     additional_fields = NULL) {
  
  # Pull PSNUs from DATIM ####
  PSNUs <- api_call("organisationUnits") %>%
    api_filter("organisationUnitGroups.id","in",
               paste0("AVy8gJXym2D",
                      dplyr::if_else(include_mil, ",nwQbMeALRjL", ""))) %>%
    {if (all(!is.null(country_uids)))
      api_filter(., "ancestors.id", "in", match = paste(country_uids, collapse = ","))
      else . } %>%
    datapackr::api_fields("id,name,ancestors[id,name,organisationUnitGroups[id,name]],organisationUnitGroups[id,name]") %>%
    {if (!is.null(additional_fields)) datapackr::api_fields(., additional_fields) else . } %>%
    datapackr::api_get()
  
  # Extract metadata ####
  PSNUs %<>%
    dplyr::mutate(
      psnu_type =
        dplyr::case_when(
          stringr::str_detect(as.character(organisationUnitGroups), "nwQbMeALRjL") ~ "Military",
          stringr::str_detect(as.character(organisationUnitGroups), "cNzfcPWEGSH") ~ "Country",
          stringr::str_detect(as.character(organisationUnitGroups), "AVy8gJXym2D") ~ "SNU"),
      level_4_type = purrr::map(ancestors, list("organisationUnitGroups",4), .default = NA),
      country_name = dplyr::case_when(
        psnu_type == "Country" ~ name,
        stringr::str_detect(as.character(level_4_type), "cNzfcPWEGSH") ~ 
          purrr::map_chr(ancestors, list("name", 4), .default = NA),
        TRUE ~ purrr::map_chr(ancestors, list("name", 3), .default = NA)
      ),
      country_uid = dplyr::case_when(
        psnu_type == "Country" ~ id,
        stringr::str_detect(as.character(level_4_type), "cNzfcPWEGSH") ~ 
          purrr::map_chr(ancestors, list("id", 4), .default = NA),
        TRUE ~ purrr::map_chr(ancestors, list("id", 3), .default = NA)
      )
    ) %>%
    dplyr::select(psnu = name, psnu_uid = id, psnu_type, country_name, country_uid,
                  tidyselect::everything(), -level_4_type)
  
  return(PSNUs)
}


#' @export
#' @title Modify PSNU list to add datapackr IDs.
#' 
#' @description
#' Adds PSNU label used in Data Packs.
#'
#' @param PSNUs Data frame of PSNUs produced by \code{\link{getPSNUs}}.
#' 
#' @return Data frame of PSNUs with added Data Pack label, \code{dp_psnu}.
#' 
add_dp_psnu <- function(PSNUs) {
  
  country_count <- unique(PSNUs$country_uid) %>% length()
  
  PSNUs %<>%
    dplyr::mutate(
      dp_psnu = paste0(
        dplyr::if_else(
          country_count > 1 & country_uid != psnu_uid,
          paste0(country_name, " > "),
          ""),
        psnu,
        " [#", psnu_type,"]",
        " [", psnu_uid,"]")
    )
  
  return(PSNUs)
}
