"""
Figure 2B - proportion of synchronized voxels per brain network (mirror plot)
=============================================================================

Input   results/networks/networks_division_and_wholeBrain.csv  (written by
        code/step03_network_proportions.m): for each video, the proportion of
        each Yeo-17 network's voxels that are unique to Religious / Secular
        ISC ("Total") and significant after the t-test + FDR ("Sig"), plus the
        whole-brain voxel counts.
Output  results/figures/mirror_plot_<Video>.png  (one panel per video)

Run     python code/figures/fig2B_network_mirror_plot.py

Networks are drawn in NETWORK_ORDER, the order of the published figure.
(It came from an alphabetical sort of the original column names, which is
why SMN-B precedes SMN-A.)

Yohay Zvi, Feb 2026. Paths and fixed network order added Oct 2026.
"""
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import matplotlib.patches as mpatches
import math

# ==============================================================================
#                           USER CONFIGURATION SECTION
# ==============================================================================

# --- Plot Toggles ---
INCLUDE_WHOLE_BRAIN_BAR = True  # Set to True to add "Whole Brain" as the 1st bar
USE_ABBREVIATIONS = True  # Set to True to use short nets names (e.g., "Vis Cent")

GENERATE_HORIZONTAL_PLOT = False  # Side-by-side (Horizontal bars)
GENERATE_VERTICAL_PLOT = False  # Stacked (Vertical bars)
GENERATE_INDIVIDUAL_PLOTS = True  # Separate files (Horizontal bars)
GENERATE_INDIVIDUAL_VERTICAL_PLOTS = False  # Separate files (Vertical bars)

# --- File & Data Settings ---
ROOT = Path(__file__).resolve().parents[2]  # repository root
FILE_NAME = ROOT / 'results' / 'networks' / 'networks_division_and_wholeBrain.csv'
OUT_DIR = ROOT / 'results' / 'figures'
SHOW_PLOTS = False  # True: also open the figures in a window

# Column names
COL_COMPARISON = 'Comparison'
COL_VIDEO = 'Video'
COL_DATA_SCALAR = 'Control A'

# --- PROPORTION DATA NAMES ---
VAL_RELIGIOUS_TOTAL_PROP = 'Unique Religious'
VAL_RELIGIOUS_SIG_PROP = 'Sig. voxels after t-test and FDR in Religious'
VAL_SECULAR_TOTAL_PROP = 'Unique Secular'
VAL_SECULAR_SIG_PROP = 'Sig. voxels after t-test and FDR in Secular'

# --- WHOLE BRAIN COUNT DATA NAMES ---
VAL_RELIGIOUS_TOTAL_WB = 'number of unique religious'
VAL_RELIGIOUS_SIG_WB = 'number of sig. religious'
VAL_SECULAR_TOTAL_WB = 'number of unique secular'
VAL_SECULAR_SIG_WB = 'number of sig. secular'

# Order of videos
VIDEO_ORDER = ['Neutral', 'Kosher', 'Chametz']

# --- Visualization Text ---
PLOT_TITLE = 'Brain Network Synchrony'
AXIS_LABEL_PROP = 'Prop. of Synced Voxels'
AXIS_LABEL_NET = 'Brain Network'
LABEL_COUNT = 'Total Voxel Count (Whole Brain)'

# --- Colors ---
COLOR_REL_TOTAL = '#FFB6C1'
COLOR_REL_SIG = '#F54927'
COLOR_SEC_TOTAL = '#ADD8E6'
COLOR_SEC_SIG = '#104E8B'

# --- Appearance ---
# 11 cm = 4.33 inches width (journal-ready)
FIG_WIDTH_CM = 12
FIG_WIDTH_IN = FIG_WIDTH_CM / 2.54  # ~4.33 inches

FIG_SIZE_HORIZONTAL = (FIG_WIDTH_IN, FIG_WIDTH_IN * 1.8)   # landscape
FIG_SIZE_VERTICAL = (FIG_WIDTH_IN, FIG_WIDTH_IN * 4.0)     # tall stacked
FIG_SIZE_INDIVIDUAL = (FIG_WIDTH_IN, FIG_WIDTH_IN * 1.8)   # single horizontal
FIG_SIZE_INDIVIDUAL_VERT = (FIG_WIDTH_IN, FIG_WIDTH_IN * 2.0)  # single vertical

BAR_WIDTH_TOTAL = 0.8
BAR_WIDTH_SIG = 0.6

# Limits (Primary Axis - Proportion)
LIMIT_REL_PROP = 0.6
LIMIT_SEC_PROP = 0.2

# Limits (Secondary Axis - Voxel Count)
LIMIT_COUNT_MANUAL = None

FONT_SIZE_TITLE = 14
FONT_SIZE_SUBTITLE = 14
FONT_SIZE_LABELS = 16
FONT_SIZE_TICKS = 12
FONT_SIZE_LEGEND = 12

OUT_PREFIX_H = str(OUT_DIR / 'mirror_plot_horizontal')
OUT_PREFIX_V = str(OUT_DIR / 'mirror_plot_vertical')
OUT_PREFIX_IND = str(OUT_DIR / 'mirror_plot_')
OUT_PREFIX_IND_V = str(OUT_DIR / 'mirror_plot_vertical_')

# Order of the networks in the published figure (abbreviated names)
NETWORK_ORDER = ['Con-A', 'Con-B', 'Con-C', 'DMN-A', 'DMN-B', 'DMN-C', 'DMN-D', 'DAN-A', 'DAN-B',
                 'Limbic-A', 'Limbic-B', 'Salience', 'SMN-B', 'SMN-A', 'VentAttn', 'VisCent', 'VisPeri']

# --- Abbreviations Dictionary ---
ABBREVIATIONS_MAP = {
    # Visual
    'Visual Central': 'VisCent',
    'visual Central': 'VisCent',
    'Visual Peripheral': 'VisPeri',
    'visual Peripheral': 'VisPeri',

    # Somatomotor
    'Somatomotor A': 'SMN-A',
    'Somatomotor B': 'SMN-B',
    'Somato motor B': 'SMN-B',

    # Dorsal Attention
    'Dorsal Attention A': 'DAN-A',
    'Dorsal Attention B': 'DAN-B',

    # Ventral Attention
    'Ventral Attention': 'VentAttn',
    'ventral Attention': 'VentAttn',

    # Salience
    'Salience': 'Salience',

    # Limbic
    'Limbic Visual Central': 'Limbic-A',
    'Limbic Visual Peripheral': 'Limbic-B',
    'Limbic': 'Limbic',

    # Control
    'Control A': 'Con-A',
    'Control B': 'Con-B',
    'Control C': 'Con-C',

    # Default Mode
    'Default A': 'DMN-A',
    'Default B': 'DMN-B',
    'Default C': 'DMN-C',
    'Default D': 'DMN-D',
    'Default D ': 'DMN-D',  # trailing space in CSV

    # Other
    'TempPar': 'TempPar'
}

# ==============================================================================

def load_and_prep_data():
    print(f"Loading data from {FILE_NAME}...")
    try:
        df = pd.read_csv(FILE_NAME)
    except FileNotFoundError:
        print(f"Error: {FILE_NAME} not found. Run code/step03_network_proportions.m first.")
        return None, None, None, None

    # Clean
    df[COL_COMPARISON] = df[COL_COMPARISON].astype(str).str.strip()
    df[COL_VIDEO] = df[COL_VIDEO].astype(str).str.strip()

    # 1. Process Networks
    prop_rows = [VAL_RELIGIOUS_TOTAL_PROP, VAL_RELIGIOUS_SIG_PROP, VAL_SECULAR_TOTAL_PROP, VAL_SECULAR_SIG_PROP]
    df_prop = df[df[COL_COMPARISON].isin(prop_rows)].copy()
    network_cols = [c for c in df.columns if c not in [COL_COMPARISON, COL_VIDEO]]
    melted = df_prop.melt(id_vars=[COL_COMPARISON, COL_VIDEO], value_vars=network_cols, var_name='Network',
                          value_name='Score')
    pivoted = melted.pivot_table(index=[COL_VIDEO, 'Network'], columns=COL_COMPARISON, values='Score').reset_index()

    rename_map = {
        VAL_RELIGIOUS_TOTAL_PROP: 'Rel_Tot',
        VAL_RELIGIOUS_SIG_PROP: 'Rel_Sig',
        VAL_SECULAR_TOTAL_PROP: 'Sec_Tot',
        VAL_SECULAR_SIG_PROP: 'Sec_Sig',
    }
    pivoted.rename(columns=rename_map, inplace=True)

    # 2. Process Whole Brain & Calculate Global Max
    global_max_wb = 0

    if INCLUDE_WHOLE_BRAIN_BAR:
        wb_rows_map = {
            VAL_RELIGIOUS_TOTAL_WB: 'Rel_Tot',
            VAL_RELIGIOUS_SIG_WB: 'Rel_Sig',
            VAL_SECULAR_TOTAL_WB: 'Sec_Tot',
            VAL_SECULAR_SIG_WB: 'Sec_Sig'
        }
        wb_data_rows = []

        # Scan all videos to find the true global max
        all_videos = df[COL_VIDEO].unique()

        for vid in all_videos:
            vid_subset = df[df[COL_VIDEO] == vid]
            row_dict = {COL_VIDEO: vid, 'Network': 'Whole Brain'}

            for csv_name, internal_name in wb_rows_map.items():
                val_row = vid_subset[vid_subset[COL_COMPARISON].str.contains(csv_name, case=False, regex=False)]
                if not val_row.empty:
                    val = val_row[COL_DATA_SCALAR].values[0]
                else:
                    val = 0
                row_dict[internal_name] = val

                # Update global max tracker
                if val > global_max_wb:
                    global_max_wb = val

            wb_data_rows.append(row_dict)

        df_wb = pd.DataFrame(wb_data_rows)
        pivoted = pd.concat([pivoted, df_wb], ignore_index=True)

    # Round up global max to a nice number
    if global_max_wb > 0:
        magnitude = 10 ** (len(str(int(global_max_wb))) - 1)
        if magnitude < 10: magnitude = 10
        global_limit_wb = math.ceil(global_max_wb / (magnitude / 2)) * (magnitude / 2)
    else:
        global_limit_wb = 100  # Default fallback

    # Apply Manual Override if set
    if LIMIT_COUNT_MANUAL is not None:
        global_limit_wb = LIMIT_COUNT_MANUAL

    print(f"Global Whole Brain Limit set to: {global_limit_wb}")

    if VIDEO_ORDER:
        tasks = [t for t in VIDEO_ORDER if t in pivoted[COL_VIDEO].unique()]
        if not tasks: tasks = sorted(pivoted[COL_VIDEO].unique())
    else:
        tasks = sorted(pivoted[COL_VIDEO].unique())

    # Handle Networks & Abbreviations
    raw_networks = [n for n in pivoted['Network'].unique() if n != 'Whole Brain']

    if USE_ABBREVIATIONS:
        current_map = {}
        for net in raw_networks:
            clean_net = net.strip()
            if clean_net in ABBREVIATIONS_MAP:
                current_map[net] = ABBREVIATIONS_MAP[clean_net]
            else:
                current_map[net] = ABBREVIATIONS_MAP.get(net, net)

        pivoted['Network'] = pivoted['Network'].replace(current_map)
        networks = [n for n in pivoted['Network'].unique() if n != 'Whole Brain']
        missing = set(networks) ^ set(NETWORK_ORDER)
        if missing:
            raise ValueError(f"Network names do not match NETWORK_ORDER: {sorted(missing)}")
        networks = list(NETWORK_ORDER)
    else:
        networks = raw_networks

    # Add Whole Brain to the START (Index 0)
    if INCLUDE_WHOLE_BRAIN_BAR:
        networks = ['Whole Brain'] + list(networks)

    return pivoted, tasks, networks, global_limit_wb


def _set_title(fig, title):
    if fig.canvas.manager is not None:
        fig.canvas.manager.set_window_title(title)


def get_smart_ticks(neg_limit, pos_limit, step):
    if step <= 0: step = 1
    neg_ticks = np.arange(0, neg_limit + (step / 1000), step) * -1
    pos_ticks = np.arange(step, pos_limit + (step / 1000), step)
    return np.concatenate([np.sort(neg_ticks), pos_ticks])


def scale_whole_brain_data(rel_tot, rel_sig, sec_tot, sec_sig, networks, global_limit):
    """
    Scales the 'Whole Brain' bar using the GLOBAL LIMIT.
    This ensures consistent scaling across all plots/videos.
    """
    rel_tot = rel_tot.copy()
    rel_sig = rel_sig.copy()
    sec_tot = sec_tot.copy()
    sec_sig = sec_sig.copy()

    # Calculate limits based on the fixed GLOBAL LIMIT
    # Target height on plot is 90% of the prop limit
    target_height = LIMIT_REL_PROP * 0.9
    scale_factor = target_height / global_limit

    limit_count_rel = LIMIT_REL_PROP / scale_factor
    limit_count_sec = LIMIT_SEC_PROP / scale_factor

    if INCLUDE_WHOLE_BRAIN_BAR and 'Whole Brain' in networks:
        wb_idx = networks.index('Whole Brain')

        rel_tot[wb_idx] *= scale_factor
        rel_sig[wb_idx] *= scale_factor
        sec_tot[wb_idx] *= scale_factor
        sec_sig[wb_idx] *= scale_factor

    return rel_tot, rel_sig, sec_tot, sec_sig, limit_count_rel, limit_count_sec


def setup_secondary_axis(ax_primary, limit_rel, limit_sec, orientation='vertical'):
    max_c = max(limit_rel, limit_sec)
    step_c = max_c / 4
    if step_c == 0: step_c = 1
    mag = 10 ** (len(str(int(step_c))) - 1)
    if mag == 0: mag = 1
    step_c = np.ceil(step_c / mag) * mag

    labels_c = []

    if orientation == 'vertical':
        # Vertical Bar Plot: Whole Brain is LEFT (Index 0).
        # We put the axis on the LEFT, but offset it OUTWARD to avoid collision.
        ticks_c = get_smart_ticks(limit_sec, limit_rel, step_c)
        for t in ticks_c:
            val = abs(t)
            if val >= 1000:
                labels_c.append(f'{int(val / 1000)}k')
            else:
                labels_c.append(f'{int(val)}')

        ax2 = ax_primary.twinx()
        ax2.yaxis.set_label_position("left")
        ax2.yaxis.tick_left()

        # KEY FIX: Offset the left spine outward
        ax2.spines['left'].set_position(('outward', 30))

        ax2.set_ylabel(LABEL_COUNT, fontsize=FONT_SIZE_LABELS, color='black', labelpad=3)
        ax2.set_ylim(-limit_sec, limit_rel)
        ax2.set_yticks(ticks_c)
        ax2.set_yticklabels(labels_c, fontsize=FONT_SIZE_TICKS)

        ax2.spines['top'].set_visible(False)
        ax2.spines['bottom'].set_visible(False)
        ax2.spines['right'].set_visible(False)
        ax2.spines['left'].set_visible(True)
        return ax2

    elif orientation == 'horizontal':
        # Horizontal Bar Plot: Whole Brain is TOP (Index 0).
        # Axis on TOP.
        ticks_c = get_smart_ticks(limit_rel, limit_sec, step_c)
        for t in ticks_c:
            val = abs(t)
            if val >= 1000:
                labels_c.append(f'{int(val / 1000)}k')
            else:
                labels_c.append(f'{int(val)}')

        ax2 = ax_primary.twiny()
        ax2.set_xlabel(LABEL_COUNT, fontsize=FONT_SIZE_LABELS, color='black', labelpad=15)
        ax2.set_xlim(-limit_rel, limit_sec)

        ax2.set_xticks(ticks_c)
        ax2.set_xticklabels(labels_c, fontsize=FONT_SIZE_TICKS)

        ax2.spines['bottom'].set_visible(False)
        ax2.spines['left'].set_visible(False)
        ax2.spines['right'].set_visible(False)
        ax2.spines['top'].set_visible(True)
        return ax2


# ---------------------------------------------------------
# 1. HORIZONTAL MIRROR PLOT
# ---------------------------------------------------------
def create_horizontal_mirror_plot(pivoted, tasks, networks, global_limit):
    if not GENERATE_HORIZONTAL_PLOT: return
    print("Generating Horizontal Plot...")

    y_pos = np.arange(len(networks))
    fig, axes = plt.subplots(1, len(tasks), figsize=FIG_SIZE_HORIZONTAL, sharey=True)
    _set_title(fig, 'Horizontal – ' + ', '.join(tasks))
    if len(tasks) == 1: axes = [axes]

    plt.subplots_adjust(wspace=0.3, bottom=0.22, top=0.85)
    fig.suptitle(f"{PLOT_TITLE} (Side-by-Side)", fontsize=FONT_SIZE_TITLE, y=0.97)

    for i, task in enumerate(tasks):
        ax = axes[i]
        task_data = pivoted[pivoted[COL_VIDEO] == task].set_index('Network').reindex(networks)

        rel_tot = task_data['Rel_Tot'].fillna(0).values
        rel_sig = task_data['Rel_Sig'].fillna(0).values
        sec_tot = task_data['Sec_Tot'].fillna(0).values
        sec_sig = task_data['Sec_Sig'].fillna(0).values

        rel_tot, rel_sig, sec_tot, sec_sig, lim_rel, lim_sec = scale_whole_brain_data(rel_tot, rel_sig, sec_tot,
                                                                                      sec_sig, networks, global_limit)

        ax.barh(y_pos, -rel_tot, color=COLOR_REL_TOTAL, height=BAR_WIDTH_TOTAL)
        ax.barh(y_pos, -rel_sig, color=COLOR_REL_SIG, height=BAR_WIDTH_SIG)
        ax.barh(y_pos, sec_tot, color=COLOR_SEC_TOTAL, height=BAR_WIDTH_TOTAL)
        ax.barh(y_pos, sec_sig, color=COLOR_SEC_SIG, height=BAR_WIDTH_SIG)

        ax.set_title(task, fontsize=FONT_SIZE_SUBTITLE, fontweight='bold', pad=25)
        ax.axvline(0, color='black', linewidth=0.8)
        ax.set_xlim(-LIMIT_REL_PROP, LIMIT_SEC_PROP)

        ticks = get_smart_ticks(LIMIT_REL_PROP, LIMIT_SEC_PROP, 0.1)
        ax.set_xticks(ticks)
        ax.set_xticklabels([f'{abs(t):.1f}' for t in ticks], fontsize=FONT_SIZE_TICKS)

        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['left'].set_visible(False)
        ax.tick_params(axis='y', length=0)

        if INCLUDE_WHOLE_BRAIN_BAR:
            ax.axhline(0.5, color='gray', linestyle='--', linewidth=1.8, alpha=0.8)
            setup_secondary_axis(ax, lim_rel, lim_sec, 'horizontal')

    axes[0].set_yticks(y_pos)
    clean_labels = [str(n).replace('_', ' ') for n in networks]
    # Special casing abbreviation style if needed
    axes[0].set_yticklabels(clean_labels, fontsize=FONT_SIZE_TICKS, rotation=0)
    axes[0].invert_yaxis()
    axes[0].set_ylabel(AXIS_LABEL_NET, fontsize=FONT_SIZE_LABELS)

    fig.text(0.5, 0.05, AXIS_LABEL_PROP, ha='center', fontsize=FONT_SIZE_LABELS)

    handles = [
        mpatches.Patch(color=COLOR_REL_TOTAL, label='Religious (Total)'),
        mpatches.Patch(color=COLOR_REL_SIG, label='Religious (Sig)'),
        mpatches.Patch(color=COLOR_SEC_TOTAL, label='Secular (Total)'),
        mpatches.Patch(color=COLOR_SEC_SIG, label='Secular (Sig)'),
    ]
    fig.legend(handles=handles, loc='lower center', ncol=2, bbox_to_anchor=(0.5, 0.01),
               fontsize=FONT_SIZE_LEGEND, frameon=False, handlelength=1.0, handletextpad=0.4,
               columnspacing=1.0)

    plt.savefig(f"{OUT_PREFIX_H}.png", dpi=300, bbox_inches='tight')
    print(f"Saved {OUT_PREFIX_H}.png")


# ---------------------------------------------------------
# 2. VERTICAL MIRROR PLOT
# ---------------------------------------------------------
def create_vertical_mirror_plot(pivoted, tasks, networks, global_limit):
    if not GENERATE_VERTICAL_PLOT: return
    print("Generating Vertical Plot...")

    x_pos = np.arange(len(networks))
    fig, axes = plt.subplots(len(tasks), 1, figsize=FIG_SIZE_VERTICAL, sharex=True)
    _set_title(fig, 'Vertical – ' + ', '.join(tasks))
    if len(tasks) == 1: axes = [axes]

    # Increase Left margin to fit the double axis
    plt.subplots_adjust(hspace=0.45, left=0.22, bottom=0.12)
    fig.suptitle(f"{PLOT_TITLE} (Stacked)", fontsize=FONT_SIZE_TITLE, y=0.97)

    for i, task in enumerate(tasks):
        ax = axes[i]
        task_data = pivoted[pivoted[COL_VIDEO] == task].set_index('Network').reindex(networks)

        rel_tot = task_data['Rel_Tot'].fillna(0).values
        rel_sig = task_data['Rel_Sig'].fillna(0).values
        sec_tot = task_data['Sec_Tot'].fillna(0).values
        sec_sig = task_data['Sec_Sig'].fillna(0).values

        rel_tot, rel_sig, sec_tot, sec_sig, lim_rel, lim_sec = scale_whole_brain_data(rel_tot, rel_sig, sec_tot,
                                                                                      sec_sig, networks, global_limit)

        ax.bar(x_pos, rel_tot, color=COLOR_REL_TOTAL, width=BAR_WIDTH_TOTAL)
        ax.bar(x_pos, rel_sig, color=COLOR_REL_SIG, width=BAR_WIDTH_SIG)
        ax.bar(x_pos, -sec_tot, color=COLOR_SEC_TOTAL, width=BAR_WIDTH_TOTAL)
        ax.bar(x_pos, -sec_sig, color=COLOR_SEC_SIG, width=BAR_WIDTH_SIG)

        ax.set_title(task, loc='left', fontsize=FONT_SIZE_SUBTITLE, fontweight='bold', pad=10)
        ax.axhline(0, color='black', linewidth=0.8)
        ax.set_ylim(-LIMIT_SEC_PROP, LIMIT_REL_PROP)

        ticks = get_smart_ticks(LIMIT_SEC_PROP, LIMIT_REL_PROP, 0.1)
        ax.set_yticks(ticks)
        ax.set_yticklabels([f'{abs(t):.1f}' for t in ticks], fontsize=FONT_SIZE_TICKS)

        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['bottom'].set_visible(False)
        ax.spines['left'].set_visible(False)
        ax.tick_params(axis='x', length=0)

        if INCLUDE_WHOLE_BRAIN_BAR:
            ax.axvline(0.5, color='gray', linestyle='--', linewidth=1.8, alpha=0.8)
            setup_secondary_axis(ax, lim_rel, lim_sec, 'vertical')

    clean_labels = [str(n).replace('_', ' ') for n in networks]
    axes[-1].set_xticks(x_pos)
    axes[-1].set_xticklabels(clean_labels, fontsize=FONT_SIZE_TICKS, rotation=60, ha='right')
    axes[-1].set_xlabel(AXIS_LABEL_NET, fontsize=FONT_SIZE_LABELS)

    fig.text(0.02, 0.5, AXIS_LABEL_PROP, va='center', rotation='vertical', fontsize=FONT_SIZE_LABELS)

    handles = [
        mpatches.Patch(color=COLOR_REL_TOTAL, label='Religious (Total)'),
        mpatches.Patch(color=COLOR_REL_SIG, label='Religious (Sig)'),
        mpatches.Patch(color=COLOR_SEC_TOTAL, label='Secular (Total)'),
        mpatches.Patch(color=COLOR_SEC_SIG, label='Secular (Sig)'),
    ]
    fig.legend(handles=handles, loc='lower center', ncol=2, bbox_to_anchor=(0.5, 0.0),
               fontsize=FONT_SIZE_LEGEND, frameon=False, handlelength=1.0, handletextpad=0.4,
               columnspacing=1.0)

    plt.savefig(f"{OUT_PREFIX_V}.png", dpi=300, bbox_inches='tight')
    print(f"Saved {OUT_PREFIX_V}.png")


# ---------------------------------------------------------
# 3. INDIVIDUAL HORIZONTAL
# ---------------------------------------------------------
def create_individual_video_plots(pivoted, tasks, networks, global_limit):
    if not GENERATE_INDIVIDUAL_PLOTS: return
    print("Generating Individual Plots (Horizontal)...")

    y_pos = np.arange(len(networks))

    for task in tasks:
        fig, ax = plt.subplots(figsize=FIG_SIZE_INDIVIDUAL)
        _set_title(fig, task)

        task_data = pivoted[pivoted[COL_VIDEO] == task].set_index('Network').reindex(networks)
        rel_tot = task_data['Rel_Tot'].fillna(0).values
        rel_sig = task_data['Rel_Sig'].fillna(0).values
        sec_tot = task_data['Sec_Tot'].fillna(0).values
        sec_sig = task_data['Sec_Sig'].fillna(0).values

        rel_tot, rel_sig, sec_tot, sec_sig, lim_rel, lim_sec = scale_whole_brain_data(rel_tot, rel_sig, sec_tot,
                                                                                      sec_sig, networks, global_limit)

        ax.barh(y_pos, -rel_tot, color=COLOR_REL_TOTAL, height=BAR_WIDTH_TOTAL)
        ax.barh(y_pos, -rel_sig, color=COLOR_REL_SIG, height=BAR_WIDTH_SIG)
        ax.barh(y_pos, sec_tot, color=COLOR_SEC_TOTAL, height=BAR_WIDTH_TOTAL)
        ax.barh(y_pos, sec_sig, color=COLOR_SEC_SIG, height=BAR_WIDTH_SIG)

        ax.set_title(f"{PLOT_TITLE}: {task}", fontsize=FONT_SIZE_TITLE, fontweight='bold', pad=25)
        ax.set_xlabel(AXIS_LABEL_PROP, fontsize=FONT_SIZE_LABELS)
        ax.set_ylabel(AXIS_LABEL_NET, fontsize=FONT_SIZE_LABELS)
        ax.axvline(0, color='black', linewidth=0.8)
        ax.set_xlim(-LIMIT_REL_PROP, LIMIT_SEC_PROP)

        ticks = get_smart_ticks(LIMIT_REL_PROP, LIMIT_SEC_PROP, 0.1)
        ax.set_xticks(ticks)
        ax.set_xticklabels([f'{abs(t):.1f}' for t in ticks], fontsize=FONT_SIZE_TICKS)

        ax.set_yticks(y_pos)
        clean_labels = [str(n).replace('_', ' ') for n in networks]
        ax.set_yticklabels(clean_labels, fontsize=FONT_SIZE_TICKS, rotation=0)
        ax.invert_yaxis()

        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['left'].set_visible(False)
        ax.tick_params(axis='y', length=0)

        if INCLUDE_WHOLE_BRAIN_BAR:
            ax.axhline(0.5, color='gray', linestyle='--', linewidth=1.8, alpha=0.8)
            setup_secondary_axis(ax, lim_rel, lim_sec, 'horizontal')

        handles = [
            mpatches.Patch(color=COLOR_REL_TOTAL, label='Religious (Total)'),
            mpatches.Patch(color=COLOR_REL_SIG, label='Religious (Sig)'),
            mpatches.Patch(color=COLOR_SEC_TOTAL, label='Secular (Total)'),
            mpatches.Patch(color=COLOR_SEC_SIG, label='Secular (Sig)'),
        ]

        ax.legend(handles=handles, loc='upper center', bbox_to_anchor=(0.5, -0.18),
                  ncol=2, fontsize=FONT_SIZE_LEGEND, frameon=False,
                  handlelength=1.0, handletextpad=0.4, columnspacing=1.0)
        plt.subplots_adjust(bottom=0.32, left=0.22, right=0.95, top=0.88)
        plt.savefig(f"{OUT_PREFIX_IND}{task}.png", dpi=300)
        print(f"Saved {OUT_PREFIX_IND}{task}.png")


# ---------------------------------------------------------
# 4. INDIVIDUAL VERTICAL
# ---------------------------------------------------------
def create_individual_vertical_video_plots(pivoted, tasks, networks, global_limit):
    if not GENERATE_INDIVIDUAL_VERTICAL_PLOTS: return
    print("Generating Individual Plots (Vertical)...")

    x_pos = np.arange(len(networks))

    for task in tasks:
        fig, ax1 = plt.subplots(figsize=FIG_SIZE_INDIVIDUAL_VERT)
        _set_title(fig, task + ' (vertical)')

        task_data = pivoted[pivoted[COL_VIDEO] == task].set_index('Network').reindex(networks)
        rel_tot = task_data['Rel_Tot'].fillna(0).values
        rel_sig = task_data['Rel_Sig'].fillna(0).values
        sec_tot = task_data['Sec_Tot'].fillna(0).values
        sec_sig = task_data['Sec_Sig'].fillna(0).values

        rel_tot, rel_sig, sec_tot, sec_sig, lim_rel, lim_sec = scale_whole_brain_data(rel_tot, rel_sig, sec_tot,
                                                                                      sec_sig, networks, global_limit)

        ax1.bar(x_pos, rel_tot, color=COLOR_REL_TOTAL, width=BAR_WIDTH_TOTAL)
        ax1.bar(x_pos, rel_sig, color=COLOR_REL_SIG, width=BAR_WIDTH_SIG)
        ax1.bar(x_pos, -sec_tot, color=COLOR_SEC_TOTAL, width=BAR_WIDTH_TOTAL)
        ax1.bar(x_pos, -sec_sig, color=COLOR_SEC_SIG, width=BAR_WIDTH_SIG)

        ax1.set_title(f"{PLOT_TITLE}: {task}", fontsize=FONT_SIZE_TITLE, fontweight='bold', pad=10)
        ax1.set_ylabel(AXIS_LABEL_PROP, fontsize=FONT_SIZE_LABELS, color='black')
        ax1.axhline(0, color='black', linewidth=0.8)
        ax1.set_ylim(-LIMIT_SEC_PROP, LIMIT_REL_PROP)

        ticks_p = get_smart_ticks(LIMIT_SEC_PROP, LIMIT_REL_PROP, 0.1)
        ax1.set_yticks(ticks_p)
        ax1.set_yticklabels([f'{abs(t):.1f}' for t in ticks_p], fontsize=FONT_SIZE_TICKS)

        clean_labels = [str(n).replace('_', ' ') for n in networks]
        ax1.set_xticks(x_pos)
        ax1.set_xticklabels(clean_labels, fontsize=FONT_SIZE_TICKS, rotation=60, ha='right')
        ax1.set_xlabel(AXIS_LABEL_NET, fontsize=FONT_SIZE_LABELS)

        ax1.spines['top'].set_visible(False)
        ax1.spines['bottom'].set_visible(False)
        ax1.spines['left'].set_visible(False)
        ax1.tick_params(axis='x', length=0)

        if INCLUDE_WHOLE_BRAIN_BAR:
            ax1.axvline(0.5, color='gray', linestyle='--', linewidth=1.8, alpha=0.8)
            setup_secondary_axis(ax1, lim_rel, lim_sec, 'vertical')

        handles = [
            mpatches.Patch(color=COLOR_REL_TOTAL, label='Religious (Total)'),
            mpatches.Patch(color=COLOR_REL_SIG, label='Religious (Sig)'),
            mpatches.Patch(color=COLOR_SEC_TOTAL, label='Secular (Total)'),
            mpatches.Patch(color=COLOR_SEC_SIG, label='Secular (Sig)'),
        ]

        ax1.legend(handles=handles, loc='upper center', bbox_to_anchor=(0.5, -0.35),
                   ncol=2, fontsize=FONT_SIZE_LEGEND, frameon=False,
                   handlelength=1.0, handletextpad=0.4, columnspacing=1.0)

        plt.subplots_adjust(bottom=0.38, left=0.22, right=0.92, top=0.93)
        plt.savefig(f"{OUT_PREFIX_IND_V}{task}.png", dpi=300)
        print(f"Saved {OUT_PREFIX_IND_V}{task}.png")


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    pivoted, tasks, nets, global_wb_lim = load_and_prep_data()
    if pivoted is not None:
        create_horizontal_mirror_plot(pivoted, tasks, nets, global_wb_lim)
        create_vertical_mirror_plot(pivoted, tasks, nets, global_wb_lim)
        create_individual_video_plots(pivoted, tasks, nets, global_wb_lim)
        create_individual_vertical_video_plots(pivoted, tasks, nets, global_wb_lim)
        if SHOW_PLOTS:
            plt.show()
        print("Done!")