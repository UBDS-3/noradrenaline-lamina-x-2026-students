library(tidyverse)
library(bslib)
library(shiny)
library(plotly)

all_sweep<-read_tsv("all_sweeps.tsv")


# Subset of all sweeps
window_df <- all_sweep |> filter(between(time_s, 0.3, 0.5))

# Data for shiny selectors
file_choices <- levels(factor(window_df$file))
cond_choices <- levels(factor(window_df$cond))
sweep_max <- max(window_df$sweep)

ui<- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background-color: #4B0082 !important; 
        color: #FFFFFF;                       
      }
      .well {
        background-color: #310054 !important; 
        border: none !important;
      }
    "))
  ),
  titlePanel("Lamina X. explloring cell 2025-03-25"),
  img (src= "dog.jpg", height="200px", width="auto"),
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput("files","Recordings",
                         choices= file_choices, 
                          selected= file_choices
                         ),
      sliderInput("sweep_range", "Sweeps",
      min=1, max= sweep_max,
      value = c(1, sweep_max), 
      step= 1
      ),
      checkboxGroupInput("cond", "condition",
                         choices=cond_choices,
                         selected= cond_choices)
      ),
      mainPanel(
        
        navset_tab(
          nav_panel(
            title = "data overview",
            plotlyOutput("raw_drawings", height = "500px")
          ),
          nav_panel(
            title = "passive paramaters"
            ),
          nav_panel(
            title = "info",
            "This is interactive app"
          )
        )
      )
    )
  )
  
  
#Server function 

server<-function(input,output, session){
  output$raw_recordings <- renderPlotly({
    req(input$files, input$sweep_range, input$cond)
    window_df  |>
      filter(
        file %in% input$files,
        between(sweep, input$sweep_range[1], input$sweep_range[2]),
        cond %in% input$cond) |>
      ggplot(aes(x= time_s, y= current_pA, 
                 group= interaction(file, sweep),
                 color= file))+
      #check what is alpha
      geom_line(alpha=0.6)+
      labs(x = "time (s)", y="Current (pA)", color= "file")
  
  }) 
  
}

shinyApp(ui,server)


