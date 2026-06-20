# Cairn

Cairn is a lightweight iOS and watchOS app for cultivating awareness by capturing meaningful moments in real time and reflecting on them later.

## The idea

Personal growth comes from noticing. Each captured moment is a stone placed along a path. Individually they may seem insignificant, but over time they form a cairn — a set of markers that helps you identify recurring sources of fulfillment, frustration, growth, and insight.

## How it works

**Capture is frictionless.** From a watch complication or app button, you record a moment as either *Contentment* or one of several predefined categories of hindrance or friction. The interaction takes only a few seconds and is usable in the middle of daily life — no typing required.

**Reflection is deferred.** Cairn doesn't ask you to journal in the moment. Later, the app prompts you to revisit recorded moments, add context, and reflect on what happened, why it mattered, and whether any patterns are emerging.

**Patterns surface over time.** A longitudinal record of moments lets you see your own recurring sources of fulfillment and friction without anyone telling you what they mean.

## Goals for v1

- Extremely fast capture flow optimized for the watch.
- Record timestamp, category, and optional later reflection.
- Scheduled or intelligently timed reflection prompts.
- A longitudinal record of meaningful moments.
- Surface patterns and trends across entries over time.
- Encourage awareness without the burden of a traditional journaling practice.

## Explicit non-goals for v1

- Social features.
- Productivity tracking.
- Clinical mental health interventions.
- AI-generated coaching or recommendations.

## Stack

- Native iOS + watchOS (Swift, SwiftUI, WatchKit).
- Local-first storage with iCloud (CloudKit) sync across the user's own Apple devices.
- Android support is deferred until the capture and reflection model is validated.
