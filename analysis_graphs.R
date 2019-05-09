
library(dplyr)  #for data management
library(tidyr)  #for data management

headlines = read.csv("labeled_dataset.csv", row.names=NULL)
samples = nrow(headlines)

labels0 <- within(headlines, headlines[, rm("term1", "term2", "term3", "term4", "term5")])
names(labels0)[names(labels0) == "term0"] <- "term"
labels1 <- within(headlines, headlines[, rm("term0", "term2", "term3", "term4", "term5")])
names(labels1)[names(labels1) == "term1"] <- "term"
labels2 <- within(headlines, headlines[, rm("term0", "term1", "term3", "term4", "term5")])
names(labels2)[names(labels2) == "term2"] <- "term"
labels3 <- within(headlines, headlines[, rm("term0", "term1", "term2", "term4", "term5")])
names(labels3)[names(labels3) == "term3"] <- "term"
labels4 <- within(headlines, headlines[, rm("term0", "term1", "term2", "term3", "term5")])
names(labels4)[names(labels4) == "term4"] <- "term"
labels5 <- within(headlines, headlines[, rm("term0", "term1", "term2", "term3", "term4")])
names(labels5)[names(labels5) == "term5"] <- "term"

deceas_labels <- bind_rows(list(labels0, labels1, labels2))
police_labels <- bind_rows(list(labels3, labels4, labels5))
# I don't understand exactly what the coercion problem is here about making the blank cells into characters
# but the bind_rows function accidentally does it for me so ¯\_(ツ)_/¯
deceas_labels <- deceas_labels[!(is.na(deceas_labels$term) | deceas_labels$term=="" | is.null(deceas_labels$term)), ]
police_labels <- police_labels[!(is.na(police_labels$term) | police_labels$term=="" | is.null(police_labels$term)), ]

deceas_labels$race = ifelse(is.na(deceas_labels$race) | deceas_labels$race=="" | is.null(deceas_labels$race), "Unknown race", deceas_labels$race)
police_labels$race = ifelse(is.na(police_labels$race) | police_labels$race=="" | is.null(police_labels$race), "Unknown race", police_labels$race)

unique(deceas_labels$term)
unique(police_labels$term)

# this one mistake was almost definitely an offset error from a comma in the CSV that should have been inside of a quoted string
# TOFIX
deceas_labels[deceas_labels$term=="Ohio",]
deceas_labels <- deceas_labels[deceas_labels$term != "Ohio",]

# lookup table transformation to clean the term labels
regex_labels = c("suspect(?:|s)(?:\\W|$)", "(?:^|\\W)(?:man|woman)(?:$|\\W)", "person", "father", "driver", "(?:^|\\W)(?:men|women)(?:$|\\W)", "mother", "victim", "family(?:-| )member", "[0-9]{1,2}(?:-| )year(?:-| )old", "(?:^|\\W)girl(?:$|\\W)", "teen", "patient", "kidnapper", "inmate", "guard", "fugitive", "veteran", "killer", "hostage(?:-| )taker", "rapper", "dealer", "passenger", "(?:^|\\W)guy(?:$|\\W)", "(?:^|\\W)boy(?:$|\\W)", "(?:[a-z]\\.?)*p\\.?d\\.?(?:$|\\W)", "(?<!police )officer", "police(?! officer)", "deput(?:y|ies)", "police officer", "\\Ws\\.?w\\.?a\\.?t\\W", "marshal", "trooper", "(?:^|\\W)cop(?:$|\\W)", "(?:^|\\W)d\\.?e\\.?a\\.?(?:$|\\W)", "border patrol", "captain")
clean_labels = c("suspect(s)", "man/woman", "person", "father", "driver", "men/women", "mother", "victim", "family member", "N year old", "girl", "teen", "patient", "kidnapper", "inmate", "guard", "fugitive", "veteran", "killer", "hostage taker", "rapper", "dealer", "passenger", "guy", "boy", "some PD", "officer", "police", "Deputy", "police officer", "SWAT", "Marshal", "Trooper", "cops", "DEA", "Border Patrol", "Captain")
lookup = setNames(clean_labels, regex_labels)
deceas_labels <- transform(deceas_labels, term=lookup[term], stringsAsFactors=FALSE)
police_labels <- transform(police_labels, term=lookup[term], stringsAsFactors=FALSE)

# confirm no labels were missed in the mapping
deceas_labels[is.na(deceas_labels$term) | deceas_labels$term=="" | is.null(deceas_labels$term), ] # <0 rows>
police_labels[is.na(police_labels$term) | police_labels$term=="" | is.null(police_labels$term), ] # <0 rows>

# Overview of deceased terminology
deceas_term_freqs <- data.frame(sort(table(deceas_labels$term), decreasing = TRUE))
deceas_term_freqs$Freq <- deceas_term_freqs$Freq / samples
ggplot(deceas_term_freqs, aes(x=Var1, y=Freq)) +
  geom_point(size=3) +
  geom_segment(aes(x=Var1,
                   xend=Var1,
                   y=0,
                   yend=Freq)) +
  labs(title="Deceased Terminology",
       subtitle="Frequency of Occurence",
       caption="Figure 1") +
  theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
  xlab("Term") +
  ylab("Probability")

# Overview of police terminology
police_term_freqs <- data.frame(sort(table(police_labels$term), decreasing = TRUE))
police_term_freqs$Freq <- police_term_freqs$Freq / samples
ggplot(police_term_freqs, aes(x=Var1, y=Freq)) +
  geom_point(size=3) +
  geom_segment(aes(x=Var1,
                   xend=Var1,
                   y=0,
                   yend=Freq)) +
  labs(title="Police Terminology",
       subtitle="Frequency of Occurence",
       caption="Figure 2") +
  theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
  xlab("Term") +
  ylab("Probability")

# deceas terms
#0  label:  197
#1+ label:  710 + 48
#2+ labels: 48

# police terms
#0  label:  44
#1  label:  736 + 175
#2+ labels: 175

omission_freq = data.frame("Category" = c("Deceased", "Police"), "OmissionRate" = c(197/samples, 44/samples))
ggplot(omission_freq, aes(x=omission_freq$Category, y=omission_freq$OmissionRate)) +
  geom_bar(stat="identity", width=0.5) + 
  labs(title="Frequency of Omission of Reference",
       caption="Figure 3") +
  xlab("Reference") +
  ylab("Omission Rate") +
  theme(axis.text.x = element_text(angle=65, vjust=0.6))

deceas_labels_man <- subset(deceas_labels, deceas_labels$term  == "man/woman")
man_count <- nrow(deceas_labels_man)
deceas_labels_sus <- subset(deceas_labels, deceas_labels$term  == "suspect(s)")
sus_count <- nrow(deceas_labels_sus)

man_freqs = data.frame("Race" = c("White", "Unknown race", "Black", "Hispanic", "Other race"), "Count" = c(191, 116, 73, 58, 16) / man_count)
ggplot(man_freqs, aes(x=Race, y=Count)) +
  geom_point(size=3) +
  geom_segment(aes(x=Race,
                   xend=Race,
                   y=0,
                   yend=Count)) +
  labs(title="Race of Victims Referred to as Man/Woman",
       caption="Figure 4") +
  theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
  xlab("Race") +
  ylab("Percentage of References") +
  ylim(0, 0.6)

sus_freqs = data.frame("Race" = c("White", "Unknown race", "Black", "Hispanic", "Other race"), "Count" = c(61, 61, 48, 35, 5) / sus_count)
ggplot(sus_freqs, aes(x=Race, y=Count)) +
  geom_point(size=3) +
  geom_segment(aes(x=Race,
                   xend=Race,
                   y=0,
                   yend=Count)) +
  labs(title="Race of Victims Referred to as Suspect",
       caption="Figure 5") +
  theme(axis.text.x = element_text(angle=65, vjust=0.6)) +
  xlab("Race") +
  ylab("Percentage of References") +
  ylim(0, 0.6)
