import pandas as pd
from great_tables import GT, loc, style

table = pd.read_csv("output/table.csv")
tab_gt = table.iloc[1:,]

tab_gt.columns = [
    "Algorithm",
    "Sim 1",
    "Sim 1.1",
    "Sim 2",
    "Sim 2.1",
    "Sim 3",
    "Sim 3.1",
    "Sim 4",
    "Sim 4.1",
]
tab = (
    GT(tab_gt, rowname_col="Algorithm")
    .tab_stubhead("Algorithm")
    .tab_header(title="Simulation results for N = 100 simulations")
    .tab_spanner(label="Sim 1", columns=["Sim 1", "Sim 1.1"])
    .tab_spanner(label="Sim 2", columns=["Sim 2", "Sim 2.1"])
    .tab_spanner(label="Sim 3", columns=["Sim 3", "Sim 3.1"])
    .tab_spanner(label="Sim 4", columns=["Sim 4", "Sim 4.1"])
    .cols_label(
        {
            "Sim 1": "R²",
            "Sim 1.1": "SE(R²)",
            "Sim 2": "R²",
            "Sim 2.1": "SE(R²)",
            "Sim 3": "R²",
            "Sim 3.1": "SE(R²)",
            "Sim 4": "R²",
            "Sim 4.1": "SE(R²)",
        }
    )
    .cols_align("center")
    .tab_style(
        style=style.borders(sides=["top"], weight="2px", color="black"),
        locations=loc.body(rows=[0]),
    )
    .tab_style(
        style=style.borders(sides=["bottom"], weight="2px", color="black"),
        locations=loc.body(rows=[1]),
    )
    .tab_style(
        style=style.borders(sides=["top"], weight="2px", color="black"),
        locations=loc.stub(rows=[0]),
    )
    .tab_style(
        style=style.borders(sides=["bottom"], weight="2px", color="black"),
        locations=loc.stub(rows=[1]),
    )
    .tab_options(
        table_font_size="20px",  # Adjust table font size
        heading_title_font_size="22px",  # Larger title
        heading_subtitle_font_size="20px",  # Slightly smaller subtitle
        column_labels_font_size="20px",  # Column label size
        row_group_font_size="20px",  # Row group size
        stub_font_size="20px",  # Stub font size (if applicable)
        source_notes_font_size="20px",  # Font size for notes (if applicable)
    )
)
tab.write_raw_html("output/table_gt.html")


tablew = pd.read_csv("output/table_weights.csv")
tab_w = (
    GT(tablew.round(3), rowname_col="Algorithm")
    .tab_header(title="Super Learner weights from plot")
    .tab_stubhead("Algorithm")
    .tab_options(
        table_font_size="20px",  # Adjust table font size
        heading_title_font_size="22px",  # Larger title
        heading_subtitle_font_size="20px",  # Slightly smaller subtitle
        column_labels_font_size="20px",  # Column label size
        row_group_font_size="20px",  # Row group size
        stub_font_size="20px",  # Stub font size (if applicable)
        source_notes_font_size="20px",  # Font size for notes (if applicable)
    )
)
tab_w.write_raw_html("output/table_gt_w.html")


tmlew = (
    pd.read_csv("output/tmle_weights.csv", index_col=0)
    .reset_index(names=["Algorithm"])
    .rename(columns={"bin": "Binary", "cont": "Continuous"})
    .assign(
        Algorithm=lambda df: df.Algorithm.map(
            {
                "SL.glm_All": "SL.glm",
                "SL.randomForest_All": "SL.randomForest",
                "SL.xgboost_All": "SL.xgboost",
                "SL.gam_1_All": "SL.gam(2)",
                "SL.gam_2_All": "SL.gam(3)",
                "SL.gam_3_All": "SL.gam(4)",
            }
        )
    )
    .round(3)
)
(
    GT(tmlew.round(3), rowname_col="Algorithm")
    .tab_header(title="Super Learner weights")
    .tab_options(
        table_font_size="20px",  # Adjust table font size
        heading_title_font_size="22px",  # Larger title
        heading_subtitle_font_size="20px",  # Slightly smaller subtitle
        column_labels_font_size="20px",  # Column label size
        row_group_font_size="20px",  # Row group size
        stub_font_size="20px",  # Stub font size (if applicable)
        source_notes_font_size="20px",  # Font size for notes (if applicable)
    )
    .write_raw_html("output/gt_lalonde_w.html")
)


tmle = pd.read_csv("output/tmle_results.csv")
tmle = (
    tmle.pivot(index="Type", columns="type", values="Estimate")
    .reset_index()
    .rename(columns={"binary": "Binary", "cont": "Continuous", "Type": "Estimate"})
)
tmle = tmle.assign(
    Estimate=lambda df: df.Estimate.replace(
        {
            "ATE": "Ψ(Q₀)",
            "CI_Lower": "CI lower",
            "CI_Upper": "CI upper",
        }
    )
)
(
    GT(tmle.round(3), rowname_col="Estimate")
    .tab_header(title="TMLE results")
    .tab_options(
        table_font_size="20px",  # Adjust table font size
        heading_title_font_size="22px",  # Larger title
        heading_subtitle_font_size="20px",  # Slightly smaller subtitle
        column_labels_font_size="20px",  # Column label size
        row_group_font_size="20px",  # Row group size
        stub_font_size="20px",  # Stub font size (if applicable)
        source_notes_font_size="20px",  # Font size for notes (if applicable)
    )
    .write_raw_html("output/gt_lalonde_tmle.html")
)
