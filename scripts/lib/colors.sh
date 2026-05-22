#!/usr/bin/env bash
# Shared ANSI color printers. Sourced by every script that needs colored output.
# Single source of truth — do not re-declare red/green/yellow/cyan elsewhere.

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
cyan()   { printf '\033[36m%s\033[0m\n' "$*"; }
