import pandas as pd

map_cols = {
    "superlearner": "Super Learner",
    "discrete_learner": "Discrete SL",
    "SL.glm_All": "SL.glm",
    "SL.randomForest_All": "SL.randomForest",
    "SL.xgboost_All": "SL.xgboost",
    "SL.ipredbagg_1_All": "SL.ipredbagg(0.00)",
    "SL.ipredbagg_2_All": "SL.ipredbagg(0.1)",
    "SL.ipredbagg_3_All": "SL.ipredbagg(0.01)",
    "SL.gam_1_All": "SL.gam(2)",
    "SL.gam_2_All": "SL.gam(3)",
    "SL.gam_3_All": "SL.gam(4)",
    "SL.nnet_1_All": "SL.nnet(2)",
    "SL.nnet_2_All": "SL.nnet(3)",
    "SL.nnet_3_All": "SL.nnet(4)",
    "SL.nnet_4_All": "SL.nnet(5)",
    "SL.polymars_All": "SL.polymars",
    "SL.loess_1_All": "SL.loess(0.75)",
    "SL.loess_2_All": "SL.loess(0.5)",
    "SL.loess_3_All": "SL.loess(0.25)",
    "SL.loess_4_All": "SL.loess(0.1)",
}
df = pd.read_csv("output/slearn_results.csv").rename(columns=map_cols)
res = (
    df.melt(id_vars="outcome", var_name="model", value_name="score")
    .groupby(["outcome", "model"])
    .aggregate(("mean", "sem"))
    .unstack(0)
    .swaplevel(axis=1)
    .sort_index(axis=1, level=0)
    .round(3)
    .rename(columns={"Y1": "Sim 1", "Y2": "Sim 2", "Y3": "Sim 3", "Y4": "Sim 4"})
    .rename(columns={"mean": "R²", "sem": "SE(R²)"})
)
res.columns = res.columns.droplevel(0)
res.index.name = None
res = res.loc[map_cols.values()]
res.columns.names = [None, None]
# Proc with gt
res.reset_index().to_csv("output/table.csv", index=False)

df = (
    pd.read_csv("output/vdlsim_coefs.csv", index_col=0)
    .reset_index(names="Algorithm")
    .assign(Algorithm=lambda df: df.Algorithm.map(map_cols))
    .set_index("Algorithm")
    .loc[(c for c in map_cols.values() if c not in ("Super Learner", "Discrete SL"))]
    .rename(columns={"Y1": "Sim 1", "Y2": "Sim 2", "Y3": "Sim 3", "Y4": "Sim 4"})
)
df.reset_index().to_csv("output/table_weights.csv", index=False)
