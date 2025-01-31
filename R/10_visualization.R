#------------------------------------------------------------------------------
#
# This script produces visualizations of the effect size distributions across
# different groupings.
#
#------------------------------------------------------------------------------
library(tidyverse)

general_data_path <- file.path("..", "Data")
todo_manual_path <- file.path(general_data_path, "R_todo_manual_check")
done_manual_check_path <- file.path(general_data_path, "R_done_manual_check")
side_output_path <- file.path(general_data_path, "R_side_output_data")
clean_data_path <- file.path(general_data_path, "R_clean_data")
img_path <- "img"

df <- read.csv(file.path(clean_data_path, "per_paper_summarized_for_visualizations.csv")) #%>%
  mutate(across(c(experiment_design, topic_for_analysis), ~as.factor(.x)))
  
summary_stats2 <- read.csv(file.path(clean_data_path, "per_topic_experiment_design_summarized_for_vis.csv"))  # old version with quantiles
summary_stats <- read.csv(file.path(clean_data_path, "guidelines.csv")) %>%
  filter(experiment_design != "all")  %>%
  select(experiment_design, topic_for_analysis, guided_size, guideline_r, n_values) %>%
  group_by(experiment_design, topic_for_analysis) %>%
  mutate(num_es = sum(n_values)) %>%
  ungroup() %>% 
  select(-n_values) %>%
  pivot_wider(names_from=guided_size, values_from=guideline_r)
    
colnames(summary_stats2)
colnames(summary_stats)
summary(df)

ggplot(df, aes(y=topic_for_analysis, x=median_es_per_paper)) +
  facet_wrap(~experiment_design)+
  geom_violin()+
  geom_point(data=summary_stats, aes(y=topic_for_analysis, x=medium), color="red", alpha=0.7, shape=18, size=4 ) +
  geom_point(data=summary_stats, aes(y=topic_for_analysis, x=small)) +
  geom_point(data=summary_stats, aes(y=topic_for_analysis, x=large)) + 
  scale_x_continuous(name="median r effect size per paper", )+
  scale_y_discrete(name="CCS category of paper", 
                   limits=rev) +
  theme_bw()

df_vis <- df %>% 
  mutate(topic_for_analysis = case_when(experiment_design == "within" ~  NA_character_, 
                                        TRUE ~ topic_for_analysis)) %>%
  filter(!is.na(topic_for_analysis))
  
topic_palette <- c("#ffffff", "#cce6ff", "#b3d9ff", "#99ccff", "#66b3ff", 
                     "#3399ff", "#1a8cff", "#0073ff", "#0066cc",
                     "#0059b3", "#004d99", "#004080", "#003366")

size_palette <- c("#99ccff", "#1a8cff", "#003366")
design_palette <- c("#E69F00", "#009E73")

  

ggplot(df) + 
  facet_grid(topic_for_analysis~experiment_design) +
  geom_histogram(data=df, aes(x=median_es_per_paper), binwidth=0.05) +
  geom_text(data=df_vis, aes(label=topic_for_analysis), x=-0.1, y=20, hjust=1) +
  geom_vline(data = summary_stats, aes(xintercept=medium, color="medium"), size=1) +
  geom_vline(data = summary_stats, aes(xintercept=small, color="small"), size=1) +
  geom_vline(data = summary_stats, aes(xintercept=large, color="large"), size=1) +
  scale_x_continuous(name="median r effect size per paper", 
                     breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2))+
  scale_y_discrete(name="CCS categories") +
    coord_cartesian(xlim = c(0, 1.3), # This focuses the x-axis on the range of interest
                    clip = 'off') +
  scale_color_manual(name="Research area specific guideline",
                     breaks=c("small","medium", "large"),
                     values=size_palette) +
  theme_bw()+
  theme(strip.text.y = element_blank(),
        plot.margin = unit(c(1, 1, 1, 5, "points"), units="points"),
        axis.title.y = element_text(margin=margin(r=170, "points")),
        legend.position="bottom")

ggsave(file.path(img_path, "es_per_topic_and_design_v1.png"), unit="cm", width=20, height=25)



ggplot(df) + 
  facet_grid(topic_for_analysis~experiment_design) +
  geom_histogram(data=df, aes(x=median_es_per_paper), binwidth=0.05) +
  geom_text(data=df_vis, aes(label=topic_for_analysis), x=-1.75, y=20, hjust=0) +
  geom_vline(data = summary_stats, aes(xintercept=medium, color="medium"), size=1) +
  geom_vline(data = summary_stats, aes(xintercept=small, color="small"), size=1) +
  geom_vline(data = summary_stats, aes(xintercept=large, color="large"), size=1) +
  scale_x_continuous(name="median r effect size per paper", 
                     breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2)) +
  scale_y_continuous(name = "CCS categories",
                     breaks = c(0, 20, 40),
                     sec.axis = sec_axis(~., 
                                         breaks = c(0, 20, 40),
                                         name="number of papers")) +
  coord_cartesian(xlim = c(0, 1.3), # This focuses the x-axis on the range of interest
                  clip = 'off') +
  scale_color_manual(name="research area specific guideline",
                     breaks=c("small","medium", "large"),
                     values=size_palette) +
  theme_bw()+
  theme(strip.text.y = element_blank(),
    plot.margin = unit(c(1, 5, 1, 1, "points"), units="points"),
    axis.title.y = element_text(margin=margin(r=185, "points")),
    legend.position="bottom")

ggsave(file.path(img_path, "es_per_topic_and_design.png"), unit="cm", 
       width=20, height=25
       )

ggplot(df) + 
  facet_grid(topic_for_analysis~experiment_design, scale="free_y") +
  geom_histogram(data=df, aes(x=median_es_per_paper), binwidth=0.05) +
  geom_violin(data=df_vis, aes(x=median_N_num_per_paper, y=topic_for_analysis))+
  geom_point(data = summary_stats, aes(y=15, x=medium), color="red", shape=18, size=4 ) +
  geom_point(data = summary_stats, aes(y=15, x=small)) +
  geom_point(data = summary_stats, aes(y=15, x=large)) +
  scale_x_continuous(name="Median r effect size per paper" )+
  scale_y_discrete(name="CCS categories")+
  theme_bw()


ggplot(df, aes(y=topic_for_analysis, x=median_N_num_per_paper, fill=topic_for_analysis)) +
  facet_wrap(~experiment_design)+
  geom_violin(position=position_nudge(y=-0.2))+
  geom_boxplot(aes(y = topic_for_analysis), position=position_nudge(y=0.2), width=0.1, outliers=TRUE) +
  scale_x_continuous(name="median sample size per paper" )+
  scale_y_discrete(name="CCS categories", 
                   limits=rev)+
  scale_fill_manual(values=topic_palette)+
  theme_bw() +
  theme(legend.position = "none",
        axis.text.y = element_text(face="bold", color="black"))

ggsave(file.path(img_path, "sample_size_per_topic_and_design.png"), unit="cm", height= 25, width=20)


# This excludes 4 r > 1 where conversion introduces invalid values through limits
# N > 352,5 is plotted as that value (value which is used in weighting in the meta-analysis)
samplesize_es_vis <- df %>% 
  filter(topic != "all") %>%
  select(-num_topic:-topic_for_analysis) %>%
  unique()
ggplot(samplesize_es_vis, aes(x=median_es_per_paper, y=median_N_num_per_paper, color=experiment_design)) + 
  geom_point() +
  scale_y_continuous(name="Median N per Paper")+
  scale_x_continuous(name="Median Effect Size (r) per Paper", 
                     limits = c(0,1)) + 
  scale_color_manual(name="Experiment Design", 
                     values=design_palette,
                     breaks=c("between", "within"),
                     labels=c("between-groups", "within-groups")) +
  theme_bw()


cor.test(samplesize_es_vis %>% filter(experiment_design=="between") %>% pull(median_es_per_paper), 
         samplesize_es_vis %>% filter(experiment_design=="between") %>% pull(median_N_num_per_paper), method="pearson")

cor.test(samplesize_es_vis %>% filter(experiment_design=="within") %>% pull(median_es_per_paper), 
         samplesize_es_vis %>% filter(experiment_design=="within") %>% pull(median_N_num_per_paper), method="pearson")

cor.test(samplesize_es_vis$median_es_per_paper, 
         samplesize_es_vis$median_N_num_per_paper, method="pearson")


ggsave(file.path(img_path, "sample_size_vs_effect_size.png"), unit="cm", width=20, height=10)
