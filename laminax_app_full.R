library(shiny)
library(bslib)
library(tidyverse)
library(plotly)
library(DT)

# ============================================================
# DATA
# Expects the following files (all produced by import_data.qmd)
# in the same folder as this app:
#   all_sweeps.tsv
#   passive_parameters.tsv
#   AC_all_params.tsv
#   C_all_params.tsv
# ============================================================

all_sweeps <- read_tsv("all_sweeps.tsv", show_col_types = FALSE) |>
    mutate(file = factor(file), cond = factor(cond), stim = factor(stim))

passive_parameters <- read_tsv("passive_parameters.tsv", show_col_types = FALSE) |>
    mutate(file = factor(file))

# each sweep's condition/stim only needs to be looked up once
sweep_meta <- all_sweeps |> distinct(file, sweep, cond, stim)

AC_all_params <- read_tsv("AC_all_params.tsv", show_col_types = FALSE) |>
    mutate(file = factor(file)) |>
    left_join(sweep_meta, by = c("file", "sweep"))

C_all_params <- read_tsv("C_all_params.tsv", show_col_types = FALSE) |>
    mutate(file = factor(file)) |>
    left_join(sweep_meta, by = c("file", "sweep"))

# choices for selectors
file_choices <- levels(all_sweeps$file)
cond_choices <- levels(all_sweeps$cond)
sweep_max    <- max(all_sweeps$sweep)
pp_vars      <- c("baseline", "Rs_MOhm", "Rmemb_MOhm", "Cmemb_pF")

# response time windows, just for drawing guide lines on the trace plots
resp_windows <- list(
    AC = c(0.28, 0.40),
    C  = c(0.28, 0.40)
)

# ============================================================
# UI
# ============================================================

ui <- page_navbar(
    title = "Lamina X — Cell 2023-03-07",
    theme = bs_theme(bootswatch = "cosmo"),
    fillable = FALSE,
    
    nav_panel(
        "Overview",
        layout_columns(
            col_widths = c(8, 4),
            card(
                card_header("About this dataset"),
                markdown(
                    "This app explores whole-cell patch-clamp recordings from a single
                    dorsal horn neuron (cell **2023_03_07**), stimulated with dorsal
                    root afferent input under three conditions: **control**,
                    **noradrenaline**, and **washout**.

                    Each recording contains repeated sweeps combining a brief voltage
                    step (used to estimate passive membrane properties) followed by
                    afferent stimulation restricted to either **C-fibers** alone, or
                    **A- and C-fibers together (AC)**.

                    Use the tabs above to:

                    - **Raw Recordings** — browse individual sweeps of raw current traces
                    - **Passive Parameters** — inspect series/membrane resistance and
                      capacitance, and which sweeps pass quality control
                    - **Postsynaptic Responses** — compare evoked response size
                      (charge transfer and amplitude) across conditions, for AC or C
                      stimulation"
                )
            ),
            card(
                card_header("Passive parameters (QC summary)"),
                tableOutput("qc_summary")
            )
        )
    ),
    
    nav_panel(
        "Raw Recordings",
        layout_sidebar(
            sidebar = sidebar(
                width = 260,
                checkboxGroupInput("raw_files", "Recordings",
                                   choices = file_choices, selected = file_choices),
                sliderInput("raw_sweep_range", "Sweeps",
                            min = 1, max = sweep_max, value = c(1, sweep_max), step = 1),
                checkboxGroupInput("raw_cond", "Condition",
                                   choices = cond_choices, selected = cond_choices),
                sliderInput("raw_time_range", "Time window (s)",
                            min = 0, max = round(max(all_sweeps$time_s), 2),
                            value = c(0.1, 0.45), step = 0.01)
            ),
            card(
                card_header("Raw current traces"),
                plotlyOutput("raw_plot", height = "450px")
            ),
            card(
                card_header("Sweep data"),
                DTOutput("raw_table")
            )
        )
    ),
    
    nav_panel(
        "Passive Parameters",
        layout_sidebar(
            sidebar = sidebar(
                width = 260,
                selectInput("pp_x", "X axis", choices = pp_vars, selected = "Rs_MOhm"),
                selectInput("pp_y", "Y axis", choices = pp_vars, selected = "Cmemb_pF"),
                checkboxInput("pp_qc_only", "Show only sweeps passing QC", value = FALSE)
            ),
            card(
                card_header("Passive parameters (colored by QC pass/fail)"),
                plotlyOutput("pp_plot", height = "450px")
            ),
            card(
                card_header("Passive parameters table"),
                DTOutput("pp_table")
            )
        )
    ),
    
    nav_panel(
        "Postsynaptic Responses",
        layout_sidebar(
            sidebar = sidebar(
                width = 260,
                radioButtons("post_stim", "Fiber stimulation",
                             choices = c("AC" = "AC", "C" = "C"), selected = "AC"),
                checkboxGroupInput("post_cond", "Condition",
                                   choices = cond_choices, selected = cond_choices)
            ),
            card(
                card_header("Raw traces, response window"),
                plotlyOutput("post_traces", height = "400px")
            ),
            layout_columns(
                card(
                    card_header("Total charge transfer by condition"),
                    plotlyOutput("post_area_box", height = "350px")
                ),
                card(
                    card_header("Monosynaptic amplitude by condition"),
                    plotlyOutput("post_amp_box", height = "350px")
                )
            ),
            card(
                card_header("Response summary table"),
                DTOutput("post_table")
            )
        )
    )
)

# ============================================================
# SERVER
# ============================================================

server <- function(input, output, session) {
    
    # ---------- Overview ----------
    output$qc_summary <- renderTable({
        passive_parameters |>
            count(QC) |>
            mutate(QC = if_else(QC, "Pass", "Fail")) |>
            rename(`QC result` = QC, `# sweeps` = n)
    })
    
    # ---------- Raw Recordings ----------
    raw_filtered <- reactive({
        req(input$raw_files, input$raw_sweep_range, input$raw_cond)
        all_sweeps |>
            filter(
                file %in% input$raw_files,
                between(sweep, input$raw_sweep_range[1], input$raw_sweep_range[2]),
                cond %in% input$raw_cond,
                between(time_s, input$raw_time_range[1], input$raw_time_range[2])
            )
    })
    
    output$raw_plot <- renderPlotly({
        p <- ggplot(raw_filtered(),
                    aes(x = time_s, y = current_pA,
                        group = interaction(file, sweep), color = file)) +
            geom_line(alpha = 0.6) +
            labs(x = "Time (s)", y = "Current (pA)", color = "File") +
            theme_minimal()
        ggplotly(p)
    })
    
    output$raw_table <- renderDT({
        datatable(raw_filtered(), options = list(pageLength = 10), rownames = FALSE)
    })
    
    # ---------- Passive Parameters ----------
    pp_filtered <- reactive({
        df <- passive_parameters
        if (input$pp_qc_only) df <- df |> filter(QC)
        df
    })
    
    output$pp_plot <- renderPlotly({
        df <- pp_filtered()
        p <- ggplot(df, aes(x = .data[[input$pp_x]], y = .data[[input$pp_y]],
                            color = QC, text = paste("file:", file, "| sweep:", sweep))) +
            geom_point(size = 2, alpha = 0.8) +
            labs(x = input$pp_x, y = input$pp_y, color = "QC pass") +
            theme_minimal()
        ggplotly(p, tooltip = "text")
    })
    
    output$pp_table <- renderDT({
        datatable(
            pp_filtered() |>
                mutate(across(where(is.numeric), \(x) round(x, 2))),
            options = list(pageLength = 10), rownames = FALSE
        )
    })
    
    # ---------- Postsynaptic Responses ----------
    post_params <- reactive({
        if (input$post_stim == "AC") AC_all_params else C_all_params
    })
    
    post_traces_data <- reactive({
        req(input$post_cond)
        win <- resp_windows[[input$post_stim]]
        all_sweeps |>
            filter(
                stim == input$post_stim,
                cond %in% input$post_cond,
                between(time_s, win[1], win[2])
            )
    })
    
    output$post_traces <- renderPlotly({
        p <- ggplot(post_traces_data(),
                    aes(x = time_s, y = current_pA,
                        group = interaction(file, sweep), color = cond)) +
            geom_line(alpha = 0.4) +
            labs(x = "Time (s)", y = "Current (pA)", color = "Condition") +
            theme_minimal()
        ggplotly(p)
    })
    
    post_filtered <- reactive({
        req(input$post_cond)
        post_params() |> filter(cond %in% input$post_cond)
    })
    
    output$post_area_box <- renderPlotly({
        p <- ggplot(post_filtered(), aes(x = cond, y = total_area_pAs, color = cond)) +
            geom_boxplot(outliers = FALSE) +
            geom_jitter(width = 0.15, alpha = 0.7) +
            labs(x = "Condition", y = "Total charge transfer (pA·s)") +
            theme_minimal() +
            theme(legend.position = "none")
        ggplotly(p)
    })
    
    output$post_amp_box <- renderPlotly({
        p <- ggplot(post_filtered(), aes(x = cond, y = mono1_amplitude_pA, color = cond)) +
            geom_boxplot(outliers = FALSE) +
            geom_jitter(width = 0.15, alpha = 0.7) +
            labs(x = "Condition", y = "Monosynaptic amplitude (pA)") +
            theme_minimal() +
            theme(legend.position = "none")
        ggplotly(p)
    })
    
    output$post_table <- renderDT({
        datatable(
            post_filtered() |>
                select(file, sweep, cond, total_area_pAs, mono1_amplitude_pA,
                       baseline, Rs_MOhm, Rmemb_MOhm, Cmemb_pF) |>
                mutate(across(where(is.numeric), \(x) round(x, 2))),
            options = list(pageLength = 10), rownames = FALSE
        )
    })
}

shinyApp(ui, server)