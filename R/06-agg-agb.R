

##
## PLOT LEVEL ######
##

tmp_plot <- tree_agb |>
  group_by(plot_id_new) |>
  summarise(
    plot_ntree = n(),
    plot_ntree_ha = sum(tree_count_ha),
    plot_ba_ha = sum(tree_ba_ha),
    plot_agb_ha = sum(tree_agb_ha)
  )

plot_agb <- plot |>
  left_join(plot_E, by = "plot_id_new") |>
  left_join(tmp_plot, by = "plot_id_new") |>
  mutate(
    cluster_nplot_target = if_else(plot_physio == "Terai", 4, 6) 
  )

## Check
ggplot(plot_agb) +
  geom_point(aes(x = plot_ba_ha, y = plot_agb_ha))

ggplot(plot_agb) +
  geom_boxplot(aes(x = plot_physio, y = plot_agb_ha)) +
  guides(x = guide_axis(n.dodge = 2))



##
## CLUSTER ######
##

## Missing info on inaccessible plot. 
## Assuming that all missing plots are due to non-forest 
## with no tree (cstock = 0)

tmp_cluster <- plot_agb |>
  group_by(cluster_id_new) |>
  summarise(
    plot_count = n(),
    cluster_ntree_ha = sum(plot_ntree_ha / cluster_nplot_target),
    cluster_ba_ha    = sum(plot_ba_ha / cluster_nplot_target),
    cluster_agb_ha   = sum(plot_agb_ha / cluster_nplot_target)
  )

cluster_agb <- cluster |>
  left_join(tmp_cluster, by = "cluster_id_new") |>
  mutate(
    cluster_physio2 = case_when(
      cluster_physio == "HHMH_add" ~ "HMHH",
      cluster_physio == "High Mountain" ~ "HMHH",
      cluster_physio == "High Himal_re" ~ "HMHH",
      TRUE ~ cluster_physio
    ),
    leaf_region3 = if_else(
      cluster_physio2 == "HMHH", "region 2 high", "region 1 low"
      )
    ) 

sf_cluster_agb <- sf_cluster |>
  left_join(tmp_cluster, by = "cluster_id_new")

## Checks
ggplot(cluster_agb) +
  geom_point(aes(x = cluster_ba_ha, cluster_agb_ha)) +
  facet_wrap(~cluster_physio)
 
ggplot(cluster_agb) +
  geom_boxplot(aes(x = cluster_physio2, cluster_agb_ha))

gg <- ggplot() +
  geom_sf(data = sf_nepal, color = "darkred", linewidth = 0.6) +
  geom_sf(data = sf_cluster_agb, aes(color = cluster_agb_ha)) +
  scale_color_viridis_c() +
  theme(legend.position = "bottom") +
  labs(
    color = "AGB (t/ha)"
  )
print(gg)


##
## Forest type / Physiographic region
## 
table(cluster_agb$cluster_physio, useNA = "ifany")

physio_agb <- cluster_agb |>
  group_by(cluster_physio2) |>
  summarise(
    cluster_count = n(),
    physio_agb_mean = mean(cluster_agb_ha),
    physio_agb_sd = sd(cluster_agb_ha)
  ) |>
  mutate(
    physio_agb_se = physio_agb_sd / sqrt(cluster_count),
    physio_agb_me = physio_agb_se * qt(0.95, cluster_count-1),
    physio_agb_ciperc = round(physio_agb_me / physio_agb_mean * 100, 0)
  )


gg <- ggplot(physio_agb, aes(x = cluster_physio2)) +
  geom_col(aes(y = physio_agb_mean, fill = cluster_physio2)) +
  geom_errorbar(aes(
    ymin = physio_agb_mean - physio_agb_me,
    ymax = physio_agb_mean + physio_agb_me, 
    ), width = 0.6) +
  geom_label(aes(y = 5, label = cluster_count)) +
  theme(legend.position = "none") +
  labs(
    x = "",
    y = "AGB (t/ha)",
    caption = "Number of clusters in label."
    
  )
print(gg)


