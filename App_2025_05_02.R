library(tidyverse)
library(shiny)
library(plotly)
library(bslib)

# save file (in qmd from yesterday)
# write_tsv(all_sweeps, file = "../all_sweeps.tsv")

# write_tsv(all_sweeps |> filter(between(time_s, 0.1, 0.7)), 
# file = "../all_sweeps_part.tsv")

# read all_sweeps file

all_sweeps <- read_tsv("all_sweeps_part.tsv")
window_df <- all_sweeps |> filter(between(time_s, 0.3, 0.4))

file_choices <- levels(factor(window_df$file))
cond_choices <- levels(factor(window_df$cond))
sweep_max <- max(window_df$sweep)
stim_choices <- levels(factor(window_df$stim))

# Define user interface

ui <- fluidPage(
    titlePanel("Lamina X cell 2025_05_02"),
    img(src = "cells_in_LaminaX.jpg", height = "100px", width = "auto"),
    sidebarLayout(
        sidebarPanel(
            checkboxGroupInput("files", "Recordings",
                               choices = file_choices,
                               selected = file_choices),
            sliderInput("sweep_range", "Sweeps",
                        min = 1, max = sweep_max,
                        value = c(1, sweep_max),
                        step = 1),
            checkboxGroupInput("stim", "Stimulation type",
                               choices = stim_choices,
                               selected = stim_choices),
            checkboxGroupInput("cond", "Condition",
                               choices = cond_choices,
                               selected = cond_choices)
        ),
        mainPanel(
            navset_tab(
                nav_panel(
                    title = "data overview",
                    plotlyOutput("raw_recordings", height = "500px")
                ),
                nav_panel(
                    title = "passive parameters"
                ),
                nav_panel(
                    title = "info",
                    "This is interactive app to explore and process recordings files from cell 2025_05_02 "
                )
            )
        )
    )
)

# server
server <- function(input, output, session){
    output$raw_recordings <- renderPlotly({
        req(input$files, input$sweep_range, input$stim, input$cond)
        window_df |>
            filter(
                file %in% input$files,
                between(sweep, input$sweep_range[1], input$sweep_range[2]),
                stim %in% input$stim,
                cond %in% input$cond
            ) |>
            ggplot(aes(x = time_s, y = current_pA,
                       group = interaction(file, sweep),
                       color = cond)) + 
            # check what is alpha
            geom_line(alpha = 0.6) +
            coord_cartesian(xlim = c(0.3, 0.33), ylim = c(-200, 0)) +
            labs(x = "Time (s)", y = "Current (pA)")
    })
    
}

shinyApp(ui, server)

