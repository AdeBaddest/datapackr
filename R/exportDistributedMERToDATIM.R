#' @export
#' @importFrom magrittr %>% %<>%
#' @importFrom stats complete.cases
#' @title exportDistributedDataToDATIM(data)
#'
#' @description Packs distributed MER data prepared from unPackSNUxIM for import to DATIM.
#'
#' @param d
#' 
#' @return Modified d object with  a DATIM compatible data frame for import id d$datim$MER
#' 
exportDistributedDataToDATIM <- function(d, keep_dedup = FALSE) {
  
  
  #We need to now indentify any cases where there was exactly 100% distribution, but there was a dedupe. 
  over_allocated<-d$data$SNUxIM %>% 
    dplyr::filter(mechanism_code != '99999') %>% 
    dplyr::filter(distribution != 0) %>% 
    dplyr::group_by(PSNU,psnuid,indicator_code,Age,Sex,KeyPop,support_type) %>% 
    dplyr::summarize(distribution = sum(distribution)) %>% 
    dplyr::mutate(distribution_diff = abs(distribution - 1.0)) %>% 
    dplyr::filter(distribution_diff >= 1e-3 & distribution > 1.0) %>% 
    dplyr::select(PSNU,psnuid,indicator_code,Age,Sex,KeyPop,support_type)
  
  potential_dupes<-d$data$distributedMER %>% 
    dplyr::group_by(PSNU,psnuid,indicator_code,Age,Sex,KeyPop,support_type) %>% 
    dplyr::filter(mechanism_code != '99999') %>% 
    dplyr::tally() %>% 
    dplyr::filter(n > 1) %>% 
    dplyr::select(PSNU,psnuid,indicator_code,Age,Sex,KeyPop,support_type)
  
  sum_dupes<-dplyr::anti_join(potential_dupes,over_allocated) %>% 
    dplyr::mutate(mechanism_code ='00000',
                  value = 0)
  
  #DSD_TA Crosswalk dupes which should be autoresolved
  
  crosswalk_dupes<-d$data$SNUxIM %>% 
    dplyr::filter(mechanism_code != '99999') %>% 
    dplyr::filter(distribution != 0) %>% 
    dplyr::group_by(PSNU,psnuid,indicator_code,Age,Sex,KeyPop,support_type) %>% 
    dplyr::summarize(distribution = sum(distribution)) %>% 
    dplyr::mutate(distribution_diff = abs(distribution - 1.0)) %>% 
    dplyr::filter(distribution_diff >= 1e-3 & distribution != 1.0) %>% 
    dplyr::select(-distribution_diff) 
  
  if (setequal(unique(crosswalk_dupes$support_type),c("DSD","TA"))) {
    crosswalk_dupes %<>% 
      tidyr::pivot_wider(names_from = support_type,values_from = distribution) %>% 
      dplyr::mutate(total_distribution = DSD + TA,
                    is_crosswalk = !is.na(DSD) & !is.na(TA)) %>% 
      dplyr::filter(is_crosswalk) %>% 
      dplyr::mutate(distribution_diff = abs(total_distribution - 1.0)) %>% 
      dplyr::filter(distribution_diff <= 1e-3 ) %>% 
      dplyr::select(PSNU,psnuid,indicator_code,Age,Sex,KeyPop) %>% 
      dplyr::mutate(support_type = 'TA',
                    sheet_name = NA,
                    mechanism_code = '00001',
                    value = 0) %>% 
      dplyr::select(names(d$data$distributedMER))
  } else {
    crosswalk_dupes<-data.frame(foo=character())
  }
  

  
  if(keep_dedup == TRUE){
    d$datim$MER <- d$data$distributedMER  
  } else {
    #Filter the pseudo-dedupe mechanism data out
    d$datim$MER <- d$data$distributedMER %>%
      dplyr::filter(mechanism_code != '99999')
  }
  
  #Bind pure dupes
 
  if (NROW(sum_dupes) > 0) {
    d$datim$MER<-dplyr::bind_rows(d$datim$MER,sum_dupes)
    msg<-paste0("INFO! ", NROW(sum_dupes), " zero-valued pure deduplication adjustments will be added to your DATIM import.
                Please consult the DataPack wiki section on deduplication for more information. ")
    
    d$info$warning_msg<-append(d$info$warning_msg,msg)
  }
  
  #Bind crosswalk dupes
  if (NROW(crosswalk_dupes) > 0) {
    d$datim$MER<-dplyr::bind_rows(d$datim$MER,crosswalk_dupes)
    msg<-paste0("INFO! ", NROW(crosswalk_dupes), " zero-valued crosswalk deduplication adjustments will be added to your DATIM import.
                Please consult the DataPack wiki section on deduplication for more information. ")
    
    d$info$warning_msg<-append(d$info$warning_msg,msg)
  }
  
  
  # align   map_DataPack_DATIM_DEs_COCs with  d$datim$MER/d$data$distributedMER for KP_MAT 
  map_DataPack_DATIM_DEs_COCs_local <- datapackr::map_DataPack_DATIM_DEs_COCs
  map_DataPack_DATIM_DEs_COCs_local$valid_sexes.name[map_DataPack_DATIM_DEs_COCs_local$indicator_code == "KP_MAT.N.Sex.T" &
                                                       map_DataPack_DATIM_DEs_COCs_local$valid_kps.name == "Male PWID"] <- "Male"
  map_DataPack_DATIM_DEs_COCs_local$valid_sexes.name[map_DataPack_DATIM_DEs_COCs_local$indicator_code == "KP_MAT.N.Sex.T" &
                                                       map_DataPack_DATIM_DEs_COCs_local$valid_kps.name == "Female PWID"] <- "Female"
  map_DataPack_DATIM_DEs_COCs_local$valid_kps.name[map_DataPack_DATIM_DEs_COCs_local$indicator_code == "KP_MAT.N.Sex.T" &
                                                     map_DataPack_DATIM_DEs_COCs_local$valid_kps.name == "Male PWID"] <- NA_character_
  map_DataPack_DATIM_DEs_COCs_local$valid_kps.name[map_DataPack_DATIM_DEs_COCs_local$indicator_code == "KP_MAT.N.Sex.T" &
                                                     map_DataPack_DATIM_DEs_COCs_local$valid_kps.name == "Female PWID"] <- NA_character_
  
  # Readjust for PMTCT_EID
  d$datim$MER %<>% dplyr::mutate(
    Age =
      dplyr::case_when(
        indicator_code %in% c("PMTCT_EID.N.Age.T.2mo","PMTCT_EID.N.Age.T.2to12mo")
        ~ NA_character_,
        TRUE ~ Age)
  ) %>%
    
    # Pull in all dataElements and categoryOptionCombos
    dplyr::left_join(., ( map_DataPack_DATIM_DEs_COCs_local %>% 
                            dplyr::rename(Age = valid_ages.name,
                                          Sex = valid_sexes.name,
                                          KeyPop = valid_kps.name) )) %>% 
    
    # Add period
    dplyr::mutate(
      period = paste0(d$info$cop_year,"Oct") ) %>% 
    # Under COP19 requirements, after this join, TX_PVLS N will remain NA for dataelementuid and categoryoptioncombouid
    # Select and rename based on DATIM protocol
    dplyr::select(
      dataElement = dataelement,
      period,
      orgUnit = psnuid,
      categoryOptionCombo = categoryoptioncombouid,
      attributeOptionCombo = mechanism_code,
      value) %>%
    
    # Make sure no duplicates
    dplyr::group_by(dataElement, period, orgUnit,categoryOptionCombo,
                    attributeOptionCombo) %>% #TODO: Coordinate with self-service on this name change
    dplyr::summarise(value = sum(value)) %>%
    dplyr::ungroup() %>%
    
    # Remove anything which is NA here. Under COP19 guidance, this will include only TX_PVLS.N.Age/Sex/Indication/HIVStatus.20T.Routine
    dplyr::filter(complete.cases(.))
  
  
  return(d)
  
}