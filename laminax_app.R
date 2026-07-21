library(shiny)
library(bslib)
library(tidyverse)
library(plotly)
library(DT)

# Read all_sweeps file

# all_sweeps <- read_tsv("all_sweeps.tsv")

# Subset of all sweeps
window_df <- all_sweeps |> filter(between(time_s, 0.3, 0.5))

# Data for shiny selectors
file_choices <- levels(factor(window_df$file))
cond_choices <- levels(factor(window_df$cond))
sweep_max <- max(window_df$sweep)

# Define user interface

ui <- fluidPage(
    titlePanel("Lamina X. Exploring cell 2023-03-07"),
    img(src = "dog.png", height = "100px", width = "auto"),
    sidebarLayout(
      sidebarPanel(
        checkboxGroupInput("files", "Recordings",
                           choices = file_choices,
                           selected = file_choices),
        sliderInput("sweep_range", "Sweeps",
                    min = 1, max = sweep_max,
                    value = c(1, sweep_max),
                    step = 1),
        checkboxGroupInput("cond", "Condition",
                           choices = cond_choices,
                           selected = cond_choices)
      ),
      mainPanel(
        # plotlyOutput("raw_recordings", height = "500px"),
        navset_tab(
            nav_panel(
                title = "info",
                "This is an interactive app to explore and process recordings files."
            ),
            nav_panel(
                title = "data_overview",
                plotlyOutput("raw_recordings", height = "500px")
            ),
            nav_panel(
                title = "passive_parameters"
            )
        )
      )
      
    ),
    card(
        dataTableOutput("summarytable")
    )
)
  
# Server function
server <- function(input, output, session) {
    output$raw_recordings <- renderPlotly({
        req(input$files, input$sweep_range, input$cond)
        window_df |> 
            filter(
                file %in% input$files,
                between(sweep, input$sweep_range[1], input$sweep_range[2]),
                cond %in% input$cond) |>
            ggplot(aes(x = time_s, y = current_pA,
                       group = interaction(file, sweep),
                       color = file)) +

            geom_line(alpha=0.6) +
            labs(x = "Time (s)", y = "Current (pA)", color = "file")
            # theme(panel.grid = element_line(color = "pink"))
    })
    output$summarytable <- renderDataTable({
        window_df |> 
            filter(
                file %in% input$files,
                between(sweep, input$sweep_range[1], input$sweep_range[2]),
                cond %in% input$cond)
    }, options = list(pageLength = 10))
    
}

shinyApp(ui, server)
