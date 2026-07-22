library(tidyverse)
library(shiny)
library(plotly)
library(DT)
library(bslib)

all_sweeps <- read_tsv("Notebooks/all_sweeps.tsv")
glimpse(all_sweeps)
window_df <- all_sweeps |> filter(between(time_s, 0.3, 0.5))

file_choices <-levels(factor(window_df$file))
cond_choices <- levels(factor(window_df$cond))
sweep_max <- max(window_df$sweep)
ui <- fluidPage(
  titlePanel("Lamina X"),
  titlePanel("Exploring cell: 2025_03_12"),
  img(src = "kaktus.png", height = "100px", width = "auto"),
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput("files", "Recordings", choices = file_choices),
      checkboxGroupInput("cond", "Condition", choices = cond_choices),
      sliderInput("sweep_range", "Sweep range",
                  min = 1, max = sweep_max, value = c(1, sweep_max))
    ),
    mainPanel(
      navset_tab(
        nav_panel(
          title = "data overview",
          plotlyOutput("raw_recordings", height = "500px")
        ),
        nav_panel(
          title = "passive parameters"
        )
      )
    )
  )
)

server <- function(input, output, session) {
  output$raw_recordings <- renderPlotly({
    req(input$sweep_range, input$cond)
    window_df |>
      filter(
        file %in% input$files,
        between(sweep, input$sweep_range[1], input$sweep_range[2]),
        cond %in% input$cond
      ) |>
      ggplot(aes(x = time_s, y = current_pA,
                 group = interaction(file, sweep),
                 color = file)) +
      geom_line(alpha = 0.6) +
      labs(x = "Time (s)", y = "Current (pA)", color = "File")
  })
}

shinyApp(ui, server)




