preprocess_data <- function(file_path = "Data/cleaned_data.csv") {

  # Read the Excel file
  data <- read.csv(file_path)
  
  data <- data %>%
    filter(
      perfect_quiz == 1
    ) %>%
    rename(
      round = match,
      stage = round
    ) %>%
    mutate(
      id = as.numeric( as.factor(id)),
      treatment = case_when(
        treatment == 7 ~ 1,
        treatment == 19 ~ 2,
        treatment == 9 ~ 3,
        treatment == 21 ~ 4,
        treatment == 15 ~ 5,
        treatment == 20 ~ 6,
        treatment == 23 ~ 7,
        treatment == 24 ~ 8,
        TRUE ~ treatment
      ),
      you = case_when(
        player_choice == "A" ~ 1,
        player_choice == "B" ~ 2
      ),
      other = case_when(
        computer_choice == "A" ~ 1,
        computer_choice == "B" ~ 2
      )
    ) %>%
    arrange(id)
  
  # # Convert the 'person'-'source' variable to a factor
  # data <- data %>%
  #   mutate(id = paste(source, person, sep = "_")) %>%
  #   mutate(id = as.numeric(as.factor(id))) %>%
  #   arrange(id)
  
  
  # Generate coop variable based on conditions
  data <- data %>%
    mutate(
      coop = ifelse(you == 1, 1, 0),
      ocoop = ifelse(other == 1, 1, 0),
      pay = case_when(
        treatment %in% c("8", "9") ~ "high",
        TRUE ~ "normal"
      ),
      delta = case_when(
        treatment %in% c("1", "3", "8", "9") ~ "high",
        TRUE ~ "low"
      ),
      suggestion = case_when(
        treatment %in% c("3", "4", "9") ~ "GT suggestion",
        TRUE ~ "no suggestion"
      ),
      treatment = as.factor(treatment),
      first_stage = ifelse(stage == 1, 1, 0),
      first_round = ifelse(round == 1, 1, 0)
    )
  
  # generate the rd variable to 0 if pay normal and delta is low otherwise 1
  data$rd <- ifelse(data$pay == "high" & data$delta == "high", 1, 0)
  data$sgpe <- ifelse(data$delta == "high", 1, 0)
  data$game_type <- ifelse(data$sgpe == 0, 0, ifelse(data$rd == 0, 1, 2))
  
  # generate the dec_round variable by every 5 rounds
  data$dec_round <- (as.numeric(data$round) - 1) %/% 5 + 1
  
  
  # replace "no suggestion" with "no" and "GT suggestion" with "GT" in suggestion
  data$suggestion <- gsub("no suggestion", "no", data$suggestion)
  data$suggestion <- gsub("GT suggestion", "GT", data$suggestion)
  
  # Save the modified data to a new CSV file
  write.csv(data, "data/modified_data.csv", row.names = FALSE)
  
  # save stata format with rename treatment to treatment
  data$treatment <- data$treatment %>% as.numeric()
  # change round stage to numeric
  data$round <- data$round %>% as.numeric()
  data$stage <- data$stage %>% as.numeric()
  # # rename round as match and delete round
  # data$match <- data$round
  # # rename stage as round
  # data$round <- data$stage
  
  # create maxround variable by id
  data <- data %>%
    group_by(id) %>%
    mutate(maxround = max(round)) %>%
    ungroup()
  
  # create an id-round variable
  data <- data %>%
    mutate(id_round = paste(id, round, sep = "_"))
  
  # generate the maxstage variable by id_round
  data <- data %>%
    group_by(id_round) %>%
    mutate(maxstage = max(stage)) %>%
    ungroup()
  
  # # generate session variable as indicator for source within each treatment group
  # data <- data %>%
  #   group_by(treatment) %>%
  #   mutate(session = as.numeric(factor(source))) %>%
  #   ungroup()
  data <- data %>%
    mutate(session = 1)
  
  # generate id2 variable as indicator for id within each treatment group
  data <- data %>%
    group_by(treatment) %>%
    mutate(id2 = as.numeric(factor(id))) %>%
    ungroup()
  
  haven::write_dta(data, "scripts/modified_data.dta")
  
  return(data)
}





dfformatlab_special <- function(data = preprocess_data(), output_dir = "scripts/", strategies_selected = c("ad", "ac", "g", "tft", "wsls", "t2")){
  
  # Create output directory if it doesn't exist
  if(!dir.exists(output_dir)){
    dir.create(output_dir)
  }
  
  # Only keep the variables: round, stage, coop, id, ocoop, session, id2, and treatment
  data <- dplyr::select(data, round, stage, treatment, coop, id, ocoop, session, id2)
  
  # Create 6 new strategy variables: ad, ac, g, tft, wsls, t2
  data <- data %>%
    group_by(id, round) %>%
    mutate(ad = 0,  # Always defect (fixed value as per provided data)
           ac = 1,  # Always cooperate (fixed value as per provided data)
           g = 1,   # Initialize grim trigger strategy to 1
           tft = 1, # Initialize tit-for-tat strategy to 1
           wsls = 0, # Initialize win-stay-lose-switch strategy to 0
           t2 = 0) %>%    # Initialize 2-periods punishment trigger strategy to 0
    mutate(
      g = ifelse(cumsum(dplyr::lag(ocoop, default = 1) == 0) > 0, 0, g),  # Update grim trigger strategy
      tft = ifelse(row_number() > 1, dplyr::lag(ocoop, default = 1), tft),  # Update tit-for-tat strategy
      wsls = ifelse(dplyr::lag(coop, default = 1) == 1 & dplyr::lag(ocoop, default = 1) == 1, dplyr::lag(coop, default = 1),
                    ifelse(dplyr::lag(coop, default = 1) == 0 & dplyr::lag(ocoop, default = 1) == 1, dplyr::lag(coop, default = 1), 1 - dplyr::lag(coop, default = 1))),  # Update win-stay-lose-switch strategy
      t2 = ifelse(dplyr::lag(ocoop, default = 1) == 0 | dplyr::lag(ocoop, n = 2, default = 1) == 0, 0, 1)  # Update 2-periods punishment trigger strategy
    ) %>%
    ungroup()
  
  # Only keep the specified strategies
  strategies_to_keep <- intersect(strategies_selected, c("ad", "ac", "g", "tft", "wsls", "t2"))
  data <- dplyr::select(data, all_of(c("round", "stage", "treatment", "coop", "id", "ocoop", "session", "id2", strategies_to_keep)))
  
  # Split the data by the treatment variable and write to different files
  treatment_levels <- unique(data$treatment)
  
  for(treatment_level in treatment_levels){
    subset_data <- dplyr::filter(data, treatment == treatment_level)
    file_name <- paste0(output_dir, "dfformatlab_strg_", treatment_level, "_special.txt")
    write.table(subset_data, file = file_name, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
    
    # Create subsets for first 5 rounds and last 5 rounds
    first_5_rounds <- subset_data %>% dplyr::filter(round <= 5)
    last_5_rounds <- subset_data %>% dplyr::filter(round > max(round) - 5)
    
    # Save first 5 rounds data
    first_5_filename <- paste0(output_dir, "dfformatlab_strg_", treatment_level, "_first5_special.txt")
    write.table(first_5_rounds, file = first_5_filename, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
    
    # Save last 5 rounds data
    last_5_filename <- paste0(output_dir, "dfformatlab_strg_", treatment_level, "_last5_special.txt")
    write.table(last_5_rounds, file = last_5_filename, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
  }
  
  return(data)
}
