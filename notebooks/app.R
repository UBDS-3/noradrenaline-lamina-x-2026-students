library(readABF)
library(tidyverse)
library(shiny)
library(plotly)
library(bslib)

# Import preprocessed patch-clamp sweep dataset
all_sweeps <- read_tsv('all_sweeps.tsv')
glimpse(all_sweeps)

# Filter baseline analysis window (0.3s to 0.5s)
window_df <- all_sweeps |> 
  filter(between(time_s, 0.3, 0.5))

# Extract unique factor levels and dynamic control ranges for UI input selectors
file_choices <- levels(factor(window_df$file))
cond_choices <- levels(factor(window_df$cond))
sweep_max <- max(window_df$sweep)

ui <- fluidPage(
  theme = bs_theme(preset = "minty"),
  titlePanel('Patch Clamp Data Explorer'),
  # Header banner image (was used as example from folder www)
  # img(src = "board.jpg", height = "100px", width = "auto"),
  
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput(
        inputId = "files", 
        label = "Recordings", 
        choices = file_choices, 
        selected = file_choices
      ),
      sliderInput(
        inputId = "sweep_range", 
        label = "Sweeps", 
        min = 1, 
        max = sweep_max, 
        value = c(1, sweep_max), 
        step = 1
      ),
      checkboxGroupInput(
        inputId = "cond", 
        label = "Condition", 
        choices = cond_choices, 
        selected = cond_choices
      )
    ),
    mainPanel(
      navset_tab(
        nav_panel(
          title = "Data overview",
          plotlyOutput("raw_recordings", height = "500px")
        ),
        nav_panel(
          title = "Passive parameters",
          tableOutput("table")
        ),
        nav_panel(
          title = "Info",
          p("Interactive visualization app created for electrophysiological data analysis during UBDS, hehe")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive expression to dynamically filter sweeps based on user inputs
  filtered_data <- reactive({
    req(input$files, input$sweep_range, input$cond)
    window_df |> 
      filter(
        file %in% input$files,
        between(sweep, input$sweep_range[1], input$sweep_range[2]),
        cond %in% input$cond
      )
  })
  # Render interactive plotly recording trace plot
  output$raw_recordings <- renderPlotly({
    p <- filtered_data() |> 
      ggplot(aes(
        x = time_s, 
        y = current_pA,
        group = interaction(file, sweep),
        color = file
      )) +
      geom_line(alpha = 0.6) + 
      # Focus view on response window
      coord_cartesian(xlim = c(0.3, 0.33), ylim = c(-200, 0)) +
      labs(
        x = "Time (s)", 
        y = "Current (pA)", 
        color = "File"
      ) +
      theme_minimal()
    ggplotly(p)
  })
  
  # Render preview table of filtered trace data
  output$table <- renderTable({
    head(filtered_data(), n = 15)
  })
}

shinyApp(ui, server)