#!/usr/bin/env python3
"""
board.py — The Long Walk project dashboard

Usage:
    python3 scripts/board.py              # full board
    python3 scripts/board.py --milestone  # milestone progress only
    python3 scripts/board.py --ticket TASK-209  # single ticket detail
"""

import argparse
import glob
import os
import re
import sys

import yaml
from rich import box
from rich.columns import Columns
from rich.console import Console
from rich.panel import Panel
from rich.progress import BarColumn, Progress, TextColumn
from rich.table import Table
from rich.text import Text

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OPEN_DIR = os.path.join(REPO_ROOT, ".tickets", "open")
CLOSED_DIR = os.path.join(REPO_ROOT, ".tickets", "closed")
MILESTONES_DIR = os.path.join(REPO_ROOT, "tasks", "milestones")

console = Console()

STATUS_STYLE = {
    "ready":       ("bold white",   "⬜"),
    "in_progress": ("bold yellow",  "🔄"),
    "verifying":   ("bold cyan",    "🔍"),
    "blocked":     ("bold red",     "🚫"),
    "done":        ("bold green",   "✅"),
}

PRIORITY_STYLE = {
    "p0": "bold red",
    "p1": "yellow",
    "p2": "dim",
}

AREA_COLORS = {
    "infra":       "blue",
    "ui":          "magenta",
    "combat":      "red",
    "progression": "green",
    "data":        "cyan",
    "test":        "yellow",
}


def load_tickets(directory):
    tickets = []
    if not os.path.isdir(directory):
        return tickets
    for path in sorted(glob.glob(os.path.join(directory, "*.yaml"))):
        with open(path) as f:
            try:
                data = yaml.safe_load(f)
                if data:
                    tickets.append(data)
            except yaml.YAMLError:
                pass
    return tickets


def load_milestones():
    milestones = []
    if not os.path.isdir(MILESTONES_DIR):
        return milestones
    for path in sorted(glob.glob(os.path.join(MILESTONES_DIR, "*.md"))):
        with open(path) as f:
            content = f.read()
        m = {}
        # parse frontmatter
        fm = re.search(r"^---\n(.*?)\n---", content, re.DOTALL)
        if fm:
            try:
                m = yaml.safe_load(fm.group(1))
            except yaml.YAMLError:
                pass
        # count tasks — support both "- [x] TASK-" and bare "- TASK-" formats
        checkbox_tasks = re.findall(r"^- \[(.)\] TASK-", content, re.MULTILINE)
        bare_tasks = re.findall(r"^- TASK-\d+", content, re.MULTILINE)
        if checkbox_tasks:
            m["total_tasks"] = len(checkbox_tasks)
            m["done_tasks"] = sum(1 for t in checkbox_tasks if t == "x")
        else:
            # bare format — treat all as done if milestone status is done
            m["total_tasks"] = len(bare_tasks)
            m["done_tasks"] = len(bare_tasks) if m.get("status") == "done" else 0
        milestones.append(m)
    return milestones


def render_header():
    title = Text("The Long Walk", style="bold white", justify="center")
    subtitle = Text("Project Dashboard", style="dim", justify="center")
    header = Text.assemble(title, "\n", subtitle)
    console.print(Panel(header, style="bold blue", padding=(0, 4)))


def render_milestones(milestones, open_tickets, closed_tickets):
    table = Table(
        box=box.SIMPLE_HEAD,
        show_header=True,
        header_style="bold",
        pad_edge=False,
        expand=True,
    )
    table.add_column("Milestone", style="bold white", min_width=20)
    table.add_column("Progress", min_width=24)
    table.add_column("Tasks", justify="right", min_width=8)
    table.add_column("Status", justify="center", min_width=10)

    for m in milestones:
        mid = m.get("id", "?")
        title = m.get("title", "Unknown")
        status = m.get("status", "unknown")
        done = m.get("done_tasks", 0)
        total = m.get("total_tasks", 0)

        # progress bar
        pct = done / total if total else 0
        filled = int(pct * 20)
        bar = f"[green]{'█' * filled}[/][dim]{'░' * (20 - filled)}[/]"

        # status badge
        if status == "done":
            badge = "[bold green]  DONE  [/]"
        elif status == "in-progress":
            badge = "[bold yellow]IN PROGRESS[/]"
        else:
            badge = f"[dim]{status}[/]"

        table.add_row(
            f"{mid}: {title}",
            bar,
            f"{done}/{total}",
            badge,
        )

    total_closed = len(closed_tickets)
    total_open = len(open_tickets)
    console.print(
        Panel(
            table,
            title="[bold]Milestone Progress[/]",
            border_style="blue",
            padding=(0, 1),
        )
    )


def render_open_board(open_tickets):
    statuses = ["ready", "in_progress", "verifying", "blocked"]
    columns_data = {s: [] for s in statuses}

    for t in open_tickets:
        s = t.get("status", "ready")
        if s in columns_data:
            columns_data[s].append(t)

    any_open = any(columns_data[s] for s in statuses)

    if not any_open:
        console.print(
            Panel(
                "[dim]No open tickets — backlog is clear. Ready to plan next milestone.[/]",
                title="[bold]Active Work[/]",
                border_style="yellow",
                padding=(0, 1),
            )
        )
        return

    col_titles = {
        "ready":       "READY",
        "in_progress": "IN PROGRESS",
        "verifying":   "VERIFYING",
        "blocked":     "BLOCKED",
    }
    col_styles = {
        "ready":       "white",
        "in_progress": "yellow",
        "verifying":   "cyan",
        "blocked":     "red",
    }

    panels = []
    for status in statuses:
        tickets = columns_data[status]
        style, icon = STATUS_STYLE.get(status, ("white", "•"))
        col_style = col_styles[status]

        if not tickets:
            inner = Text("—", style="dim", justify="center")
        else:
            lines = []
            for t in tickets:
                tid = t.get("id", "?")
                title = t.get("title", "")
                priority = t.get("priority", "p2")
                area = t.get("area", "")
                p_style = PRIORITY_STYLE.get(priority, "")
                a_color = AREA_COLORS.get(area, "white")

                card = Text()
                card.append(f"{icon} {tid}\n", style=f"bold {col_style}")
                card.append(f"{title}\n", style="white")
                card.append(f"[{area}]", style=a_color)
                card.append("  ")
                card.append(priority, style=p_style)
                lines.append(card)
                lines.append(Text(""))

            inner = Text.assemble(*lines)

        panels.append(
            Panel(
                inner,
                title=f"[bold {col_style}]{col_titles[status]} ({len(tickets)})[/]",
                border_style=col_style,
                padding=(0, 1),
                width=30,
            )
        )

    console.print(Columns(panels, equal=True, expand=True))


def render_stats(open_tickets, closed_tickets):
    total = len(open_tickets) + len(closed_tickets)
    done = len(closed_tickets)
    pct = int((done / total) * 100) if total else 0

    in_prog = sum(1 for t in open_tickets if t.get("status") == "in_progress")
    blocked = sum(1 for t in open_tickets if t.get("status") == "blocked")

    stats = Table.grid(padding=(0, 4))
    stats.add_column(justify="center")
    stats.add_column(justify="center")
    stats.add_column(justify="center")
    stats.add_column(justify="center")
    stats.add_column(justify="center")

    def stat(value, label, color):
        t = Text(justify="center")
        t.append(str(value), style=f"bold {color}")
        t.append(f"\n{label}", style="dim")
        return t

    stats.add_row(
        stat(total,   "total tickets", "white"),
        stat(done,    "done",          "green"),
        stat(in_prog, "in progress",   "yellow"),
        stat(blocked, "blocked",       "red"),
        stat(f"{pct}%", "complete",    "cyan"),
    )

    console.print(Panel(stats, border_style="dim", padding=(0, 1)))


def render_ticket_detail(ticket_id):
    all_tickets = load_tickets(OPEN_DIR) + load_tickets(CLOSED_DIR)
    match = next((t for t in all_tickets if t.get("id") == ticket_id), None)
    if not match:
        console.print(f"[red]Ticket {ticket_id} not found.[/]")
        sys.exit(1)

    t = match
    status = t.get("status", "unknown")
    style, icon = STATUS_STYLE.get(status, ("white", "•"))

    # Header
    console.print(
        Panel(
            Text.assemble(
                (f"{icon} {t.get('id', '')}  ", f"bold {style}"),
                (t.get("title", ""), "bold white"),
                "\n",
                (f"  {t.get('milestone', '')}  ", "dim"),
                (f"  {t.get('area', '')}  ", AREA_COLORS.get(t.get("area", ""), "white")),
                (f"  {t.get('priority', '')}  ", PRIORITY_STYLE.get(t.get("priority", ""), "")),
                (f"  {status}  ", style),
            ),
            border_style=style,
        )
    )

    # Problem / outcome
    if t.get("problem"):
        console.print(Panel(
            Text(str(t["problem"]).strip(), style="white"),
            title="[bold]Problem[/]",
            border_style="dim",
            padding=(0, 1),
        ))
    if t.get("desired_outcome"):
        console.print(Panel(
            Text(str(t["desired_outcome"]).strip(), style="white"),
            title="[bold]Desired Outcome[/]",
            border_style="dim",
            padding=(0, 1),
        ))

    # Acceptance criteria
    ac = t.get("acceptance_criteria", [])
    if ac:
        table = Table(box=box.SIMPLE, show_header=True, header_style="bold", pad_edge=False)
        table.add_column("ID", style="dim", width=5)
        table.add_column("Description")
        table.add_column("Verify", style="dim")
        for item in ac:
            table.add_row(
                item.get("id", ""),
                item.get("description", ""),
                item.get("verify", ""),
            )
        console.print(Panel(table, title="[bold]Acceptance Criteria[/]", border_style="dim", padding=(0, 1)))

    # Verification
    verification = t.get("delivery", {}).get("verification", {})
    passed = verification.get("required_passed", False)
    commands = t.get("verification_required", [])
    if commands:
        cmds = "\n".join(f"  $ {c}" for c in commands)
        gate_text = Text()
        gate_text.append(cmds, style="dim")
        gate_text.append("\n\nGate: ")
        gate_text.append("PASSED", style="bold green") if passed else gate_text.append("NOT RUN", style="bold red")
        console.print(Panel(
            gate_text,
            title="[bold]Verification[/]",
            border_style="green" if passed else "red",
            padding=(0, 1),
        ))


def main():
    parser = argparse.ArgumentParser(description="The Long Walk project dashboard")
    parser.add_argument("--milestone", action="store_true", help="Show milestone progress only")
    parser.add_argument("--ticket", metavar="ID", help="Show detail for a specific ticket")
    args = parser.parse_args()

    open_tickets = load_tickets(OPEN_DIR)
    closed_tickets = load_tickets(CLOSED_DIR)
    milestones = load_milestones()

    console.print()

    if args.ticket:
        render_ticket_detail(args.ticket)
        return

    render_header()
    console.print()
    render_milestones(milestones, open_tickets, closed_tickets)
    console.print()

    if not args.milestone:
        render_open_board(open_tickets)
        console.print()

    render_stats(open_tickets, closed_tickets)
    console.print()


if __name__ == "__main__":
    main()
