library(shiny)
library(readABF)
library(tidyverse)
library(plotly)
library(bslib)

all_sweeps <- read_tsv("all_sweeps.tsv")

window_df <- all_sweeps |> filter(between(time_s, 0.3, 0.5))

file_choices <- levels(factor(window_df$file))
cond_choices <- levels(factor(window_df$cond))
sweep_max <- max(window_df$sweep)

ui <- fluidPage(
  titlePanel("Exploring ..."), 
  img(src = "imeg1.png", height = "100px", width = "auto"),
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
      navset_tab(
        nav_panel(
          title = "data overview",
          # МІНІМАЛЬНА ЗМІНА: додано літеру "s" у слові raw_recordings
          plotlyOutput("raw_recordings", height = "500px")
        ),
        nav_panel(
          title = "info",
          "This is intetaction"
        )
      )
    )
  )
)

server <- function(input, output, session){
  
  filtered_data <- reactive({
    req(input$files, input$sweep_range, input$cond)
    
    window_df |>
      filter(
        file %in% input$files,
        between(sweep, input$sweep_range[1], input$sweep_range[2]),
        cond %in% input$cond
      )
  })
  
  output$raw_recordings <- renderPlotly({
    filtered_data() |>
      ggplot(aes(x = time_s, y = current_pA,
                 group = interaction(file, sweep),
                 color = file)) +
      geom_line(alpha = 0.6) +
      labs(x = "Time(s)", y = "Current (pA)", color = "Files")
  })
  
  output$cell_table <- renderTable({
    filtered_data() |>
      group_by(file, cond) |>
      summarise(
        sweeps_count = n_distinct(sweep),         
        mean_current_pA = mean(current_pA),       
        min_current_pA = min(current_pA),         
        .groups = "drop"
      )
  })
}

shinyApp(ui, server)