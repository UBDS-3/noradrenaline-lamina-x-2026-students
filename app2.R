library(tidyverse)
library(shiny)
library(plotly)

#write_tsv(all_sweeps, file = "all_sweeps.tsv")
all_sweeps <- read_tsv("all_sweeps.tsv")
glimpse(all_sweeps$cond)

#subset
window_df <- all_sweeps |> filter(between(time_s, 0.3, 0.5))
levels(factor(all_sweeps$cond))

#Data for shiny selectors
file_choices <- levels(factor(window_df$file))
cond_choices <- levels(factor(window_df$cond))
sweep_max <- max(window_df$sweep)

#Defining user interface
ui <- fluidPage(
  titlePanel("Title!"),
  img(src = "image.png", height = "200px", width = "auto"),
  sidebarLayout(
    position = "left",
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
                         selected = cond_choices
                         )
      ),
    mainPanel(
      plotlyOutput("raw_recordings", height = "500px"),
      hr(),
      DTOutput("raw_recordings_table")
    )
    )
    
  )

server <- function(input, output, session){
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
      geom_line(alpha = 0.6) +
      labs( x = "Time (s)", y = "Current (pA)", color = "file")
  })
  
  output$raw_recordings_table <- renderDT({filtered_data() |>
      group_by(file, sweep, cond) |>           # summarise to one row per sweep
      summarise(
        mean_current = round(mean(current_pA), 3),
        min_current  = round(min(current_pA),  3),
        max_current  = round(max(current_pA),  3),
        .groups = "drop"
      ) |>
      datatable(
        filter   = "top",        # per-column search boxes
        rownames = FALSE,
        options  = list(pageLength = 10, scrollX = TRUE)
      )
    
  })
  
}

shinyApp(ui, server)
