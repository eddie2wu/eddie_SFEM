
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv")
df <- subset(data, stage == 1)
df <- df[, c("round", "treatment", "coop", "id", "ocoop")]

df <- df %>%
  arrange(id, round, treatment)

# convert the chr person variable to a factor variable
df$id <- as.numeric(df$id)
df$round <- as.numeric(df$round)

library(dplyr)

# delete the id with the same coop value (no variantion)
df <- df %>%
  group_by(id) %>%
  filter(max(coop) != min(coop)) %>%
  ungroup()

# generate id2 variable as indicator for id within each treatment group
df <- df %>%
  group_by(treatment) %>%
  mutate(id2 = as.numeric(factor(id))) %>%
  ungroup()

df <- df %>%
  arrange(treatment, id2, round)

write.table(df, "scripts/dfformatlab.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")






