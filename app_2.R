# Load libraries
library(tidyverse)
library(shiny)
library(plotly)
library(DT)
library(GGally)

# Read all_sweeps file (shared with the main app; lives one level up)
all_sweeps <- read_tsv("all_sweeps.tsv")
glimpse(all_sweeps)

# ---- Data for "Raw recordings" tab -----------------------------------------

window_df <- all_sweeps |> filter(between(time_s, 0.3, 0.35))

# ---- Data for "Passive parameters" tab -------------------------------------
# (ported from Import_2025_05_02.qmd, "Calculate passive parameters" section)

voltage_step_data <- all_sweeps |>
    filter(between(time_s, 0.12, 0.22))

# time windows used to compute baseline / peak / plateau / decay
baseline_tw <- c(0.14, 0.16)
peak_tw <- c(0.159, 0.165)
plateau_tw <- c(0.180, 0.198)
decay_tw <- c(0.1605, 0.175)

# calculating resistances
passive_parameters <- voltage_step_data |>
    group_by(file, sweep) |>
    summarise(
        baseline_pA = mean(
            current_pA[between(time_s, baseline_tw[1], baseline_tw[2])]
        ),
        peak_pA = min(
            current_pA[between(time_s, peak_tw[1], peak_tw[2])]
        ) - baseline_pA,
        plateau_pA = mean(
            current_pA[between(time_s, plateau_tw[1], plateau_tw[2])]
        ) - baseline_pA,
        Rs_MOhm = -10000 / peak_pA,
        Rtotal_MOhm = -10000 / plateau_pA,
        Rmemb_MOhm = Rtotal_MOhm - Rs_MOhm,
        .groups = "drop"
    )

#### This part will be VERY hard to explain ####
# so it is kept close to a straight port (must stay robust to fit errors):
# for each file/sweep we fit an exponential decay (SSasymp) to get the
# membrane time constant (tau), then use it to derive the membrane
# capacitance from the two resistances calculated above.
decay_fits <- voltage_step_data |>
    filter(time_s >= decay_tw[1], time_s <= decay_tw[2]) |>
    nest(.by = c(file, sweep)) |>
    mutate(
        models = map(
            data,
            possibly(\(x) nls(current_pA ~ SSasymp(time_s, Asym, R0, lrc), data = x))
        ),
        # using SSasymp() as in this tutorial:
        # https://douglas-watson.github.io/post/2018-09_exponential_curve_fitting/
        # wrapped in possibly() so a sweep that fails to fit doesn't crash the app
        coefs = map(models, coef),
        lrc = map_dbl(coefs, \(x) pluck(x, "lrc", .default = NA)),
        # SSasymp gives the natural log of the rate constant (lrc);
        # tau is 1 / rate constant
        tau = 1 / exp(lrc)
    ) |>
    select(file, sweep, tau)
#### END OF HARD PART ####

# bring cond/stim back in (dropped by group_by/summarise above)
sweep_meta <- all_sweeps |> distinct(file, sweep, cond, stim)

passive_parameters <- passive_parameters |>
    left_join(decay_fits, by = c("file", "sweep")) |>
    mutate(
        Cmemb_pF = tau / (1 / (1 / Rs_MOhm + 1 / Rmemb_MOhm)) * 10^6
        # tau depends on Rseries and Rmemb together; from the capacitor's
        # point of view they act in parallel, hence the combined resistance
    ) |>
    left_join(sweep_meta, by = c("file", "sweep")) |>
    select(file, sweep, cond, stim, baseline_pA, Rs_MOhm, Rmemb_MOhm, Cmemb_pF)

# ---- Data for shiny selectors ----------------------------------------------

file_choices <- levels(factor(all_sweeps$file))
cond_choices <- levels(factor(all_sweeps$cond))
sweep_max <- max(all_sweeps$sweep)

# Define user interface
ui <- fluidPage(
    titlePanel("Lamina X"),
    img(src = "cat.webp", height = "100px", width = "auto"),
    tabsetPanel(
        tabPanel(
            "Raw recordings",
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
                    plotlyOutput("raw_recordings", height = "500px")
                )
            )
        ),
        tabPanel(
            "Passive parameters",
            sidebarLayout(
                sidebarPanel(
                    checkboxGroupInput("pp_files", "Recordings",
                                        choices = file_choices,
                                        selected = file_choices),
                    sliderInput("pp_sweep_range", "Sweeps",
                                min = 1, max = sweep_max,
                                value = c(1, sweep_max),
                                step = 1),
                    checkboxGroupInput("pp_cond", "Condition",
                                       choices = cond_choices,
                                       selected = cond_choices)
                ),
                mainPanel(
                    h4("Voltage step & time windows used for calculation"),
                    plotlyOutput("voltage_step_plot", height = "350px"),
                    h4("Calculated passive parameters"),
                    DTOutput("passive_table"),
                    h4("Overview across parameters"),
                    plotOutput("passive_boxplot", height = "450px"),
                    h4("Pairwise relationships"),
                    plotOutput("passive_ggpairs", height = "600px")
                )
            )
        )
    )
)

# Server function
server <- function(input, output, session) {

    # ---- Raw recordings tab -------------------------------------------------

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
            labs(x = "Time (s)", y = "Current (pA)", color = "File")
    })

    # ---- Passive parameters tab --------------------------------------------

    pp_filtered <- reactive({
        req(input$pp_files, input$pp_sweep_range, input$pp_cond)
        passive_parameters |>
            filter(
                file %in% input$pp_files,
                between(sweep, input$pp_sweep_range[1], input$pp_sweep_range[2]),
                cond %in% input$pp_cond)
    })

    output$voltage_step_plot <- renderPlotly({
        req(input$pp_files, input$pp_sweep_range, input$pp_cond)
        p <- voltage_step_data |>
            filter(
                file %in% input$pp_files,
                between(sweep, input$pp_sweep_range[1], input$pp_sweep_range[2]),
                cond %in% input$pp_cond) |>
            ggplot(aes(x = time_s, y = current_pA,
                       group = interaction(file, sweep),
                       color = file)) +
            geom_line(alpha = 0.6) +
            geom_vline(xintercept = baseline_tw, color = "lightblue") +
            geom_vline(xintercept = peak_tw, color = "pink") +
            geom_vline(xintercept = plateau_tw, color = "lightgreen") +
            geom_vline(xintercept = decay_tw, color = "gold") +
            labs(x = "Time (s)", y = "Current (pA)", color = "File")
        ggplotly(p)
    })

    output$passive_table <- renderDT({
        df <- pp_filtered()
        validate(need(nrow(df) > 0, "No sweeps match the current filters."))
        df |>
            mutate(across(where(is.numeric), \(x) round(x, 2))) |>
            datatable(rownames = FALSE)
    })

    output$passive_boxplot <- renderPlot({
        df <- pp_filtered()
        validate(need(nrow(df) > 0, "No sweeps match the current filters."))
        df |>
            pivot_longer(
                cols = c(baseline_pA, Rs_MOhm, Rmemb_MOhm, Cmemb_pF),
                names_to = "parameter",
                values_to = "value"
            ) |>
            ggplot(aes(x = file, y = value)) +
            geom_boxplot(outlier.shape = NA) +
            geom_jitter(aes(color = file), width = 0.15, size = 2.2) +
            facet_wrap(~parameter, scales = "free_y") +
            labs(x = NULL, y = NULL, color = "File")
    })

    output$passive_ggpairs <- renderPlot({
        df <- pp_filtered() |>
            select(file, sweep, baseline_pA, Rs_MOhm, Rmemb_MOhm, Cmemb_pF) |>
            na.omit()
        validate(need(nrow(df) > 1, "Not enough data for a pairwise plot."))
        ggpairs(df, aes(color = file), columns = 3:6)
    })

}

shinyApp(ui, server)
