# ALZA ORG Training Tracker

A separate GitHub Pages application for associate and admin dashboards.

## Current scope
- Sign in with existing ALZA TMC associate credentials.
- Associate dashboard displays name, position, crew and client only.
- Admin dashboard displays the associate directory, including mobile number and trainer.
- Training Tracker uses its own short-lived session table and Edge Function. TMC entries and TMC session records are not modified.

## Backend
Supabase project: ALZA TMC Manager
Edge Function: `training-api`
Session table: `public.training_sessions`

## Deployment
This app is published from `/training-tracker/` in the GitHub Pages repository.
