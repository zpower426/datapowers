---
name: executing-plans
description: "Use when executing an analysis plan. Dispatches tasks with two-stage review: Statistical first, then Code Quality."
---

# Executing Analysis Plans

## Overview

Standard execution loop for data analysis tasks. Prioritizes the **Statistical Review** to ensure the core logic is correct before worrying about code style.

## Process Flow

1. **Pick Task**: From the TodoWrite list.
2. **Execute**: Write code, run tests, save artifacts.
3. **Statistical Review**: Trigger `requesting-statistical-review`. **STOP** if issues found.
4. **Code Review**: Check for vectorization (no loops), memory efficiency, and comments.
5. **Mark Done**: Update TodoWrite.

## The Two-Stage Review

**Stage 1: Statistical Correctness**
Focus on leakage, metric choice, and split integrity. If the statistics are wrong, the code is useless.

**Stage 2: Code Quality**
Focus on `pandas` best practices (vectorization), docstrings, and clean artifact saving.

## Red Flags

- Skipping statistical review because "it's just a simple task".
- Merging code into the main branch with "PENDING" review status.

## The Iron Law

**STATISTICAL AUDIT ALWAYS PRECEDES CODE QUALITY REVIEW.**
